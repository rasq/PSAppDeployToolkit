<#
.SYNOPSIS
	This script performs the installation or uninstallation of an application(s).
	# LICENSE #
	PowerShell App Deployment Toolkit - Provides a set of functions to perform common application deployment tasks on Windows.
	Copyright (C) 2017 - Sean Lillis, Dan Cunningham, Muhammad Mashwani, Aman Motazedian.
	This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
	You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
.DESCRIPTION
	The script is provided as a template to perform an install or uninstall of an application(s).
	The script either performs an "Install" deployment type or an "Uninstall" deployment type.
	The install deployment type is broken down into 3 main sections/phases: Pre-Install, Install, and Post-Install.
	The script dot-sources the AppDeployToolkitMain.ps1 script which contains the logic and functions required to install or uninstall an application.
.PARAMETER DeploymentType
	The type of deployment to perform. Default is: Install.
.PARAMETER DeployMode
	Specifies whether the installation should be run in Interactive, Silent, or NonInteractive mode. Default is: Interactive. Options: Interactive = Shows dialogs, Silent = No dialogs, NonInteractive = Very silent, i.e. no blocking apps. NonInteractive mode is automatically set if it is detected that the process is not user interactive.
.PARAMETER AllowRebootPassThru
	Allows the 3010 return code (requires restart) to be passed back to the parent process (e.g. SCCM) if detected from an installation. If 3010 is passed back to SCCM, a reboot prompt will be triggered.
.PARAMETER TerminalServerMode
	Changes to "user install mode" and back to "user execute mode" for installing/uninstalling applications for Remote Destkop Session Hosts/Citrix servers.
.PARAMETER DisableLogging
	Disables logging to file for the script. Default is: $false.
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeployMode 'Silent'; Exit $LastExitCode }"
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -AllowRebootPassThru; Exit $LastExitCode }"
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeploymentType 'Uninstall'; Exit $LastExitCode }"
.EXAMPLE
    Deploy-Application.exe -DeploymentType "Install" -DeployMode "Silent"
.NOTES
	Toolkit Exit Code Ranges:
	60000 - 68999: Reserved for built-in exit codes in Deploy-Application.ps1, Deploy-Application.exe, and AppDeployToolkitMain.ps1
	69000 - 69999: Recommended for user customized exit codes in Deploy-Application.ps1
	70000 - 79999: Recommended for user customized exit codes in AppDeployToolkitExtensions.ps1
.LINK
	http://psappdeploytoolkit.com
#>
[CmdletBinding()]
Param (
	[Parameter(Mandatory=$false)]
	[ValidateSet('Install','Uninstall','Repair')]
	[string]$DeploymentType = 'Install',
	[Parameter(Mandatory=$false)]
	[ValidateSet('Interactive','Silent','NonInteractive')]
	[string]$DeployMode = 'Interactive',
	[Parameter(Mandatory=$false)]
	[switch]$AllowRebootPassThru = $false,
	[Parameter(Mandatory=$false)]
	[switch]$TerminalServerMode = $false,
	[Parameter(Mandatory=$false)]
	[switch]$DisableLogging = $false
)

#Try {  
  Function Set-ADTVariable {
    param(
        [Parameter(Mandatory = $True)]
        [AllowEmptyString()]
        [String]$YamlData,
        [Parameter(Mandatory = $True)]
        [AllowEmptyString()]
        [String]$DefaultValue
    )

    if (-not ([string]::IsNullOrEmpty($YamlData))) { $tmpValue = $YamlData } 
    else { $YamlData = $DefaultValue }

    Return $tmpValue
  } 

	## Set the script execution policy for this process
	Try { Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Scope 'Process' -Force -ErrorAction 'Stop' } Catch {}
	
	If (Test-Path -LiteralPath 'variable:HostInvocation') { $InvocationInfo = $HostInvocation } Else { $InvocationInfo = $MyInvocation }
	[string]$scriptDirectory = Split-Path -Path $InvocationInfo.MyCommand.Definition -Parent
  
  ## Import YAML modules
  #Get public and private function definition files.
  $Public  = @( Get-ChildItem -Path $PSScriptRoot\AppDeployToolkit\PSYaml\Public\*.ps1 -ErrorAction SilentlyContinue )
  $Private = @( Get-ChildItem -Path $PSScriptRoot\AppDeployToolkit\PSYaml\Private\*.ps1 -ErrorAction SilentlyContinue )

  Add-Type -Path "$PSScriptRoot\AppDeployToolkit\PSYaml\lib\YamlDotNet.dll"

  #Dot source the files
  . "$scriptDirectory\AppDeployToolkit\AppDeployToolkitExtended.ps1"
  
  Foreach ($import in @($Public + $Private)) {
      Try {
          . $import.fullname
      } Catch { Write-Error -Message "Failed to import function $($import.fullname): $_" }
  }

  $yamlFile = "$scriptDirectory\PKGDefinition.yaml"

  if (Test-Path -LiteralPath $yamlFile) {
    $yamlString = [System.IO.File]::ReadAllText($yamlFile)
    $stringReader = new-object System.IO.StringReader($yamlString)
    $yamlStream = New-Object YamlDotNet.RepresentationModel.YamlStream
    $yamlStream.Load([System.IO.TextReader]$stringReader)
    $YamlObject = ConvertFrom-YAMLDocument ($yamlStream.Documents[0])
    [bool]$isYaml = $True 
  } else { [bool]$isYaml = $False }


	##*===============================================
	##* VARIABLE DECLARATION
	##*===============================================
  ## Variables: Application
  [string]$Global:TmpDeployMode = 'null'
  [string]$ClientName = Set-ADTVariable -YamlData $YamlObject.properties.ClientName -DefaultValue ''
  [string]$PKGName = Set-ADTVariable -YamlData $YamlObject.properties.PKGName -DefaultValue ''
  
    if ([string]::IsNullOrWhitespace($ClientName) -or ($ClientName -eq "") -or ($null -eq $ClientName)) {
			$Global:clientBasedBP = $False	
			if ($DeployMode -eq 'null') { $DeployMode = 'Silent' }
		} else { 
			If ($DeployMode -eq 'null') { 
				$Global:TmpDeployMode = 'Interactive' 
				$DeployMode = 'Silent' 
			} else { $Global:TmpDeployMode = $DeployMode } 
			$Global:clientBasedBP = $True	
			Set-AccountBP -CN $ClientName
		}

  [string]$mainPKGGUID = Set-ADTVariable -YamlData $YamlObject.properties.mainPKGGUID -DefaultValue ''

  [string]$killProcessesInstall = Set-ADTVariable -YamlData $YamlObject.properties.killProcessesInstall -DefaultValue ''
  [string]$killProcessesUninstall = Set-ADTVariable -YamlData $YamlObject.properties.killProcessesUninstall -DefaultValue ''
  [string]$FriendlyProcessName = Set-ADTVariable -YamlData $YamlObject.properties.FriendlyProcessName -DefaultValue ''
  [string]$blnRebootNeeded = Set-ADTVariable -YamlData $YamlObject.properties.blnRebootNeeded -DefaultValue ''
  [string]$LanguagesToUse = Set-ADTVariable -YamlData $YamlObject.properties.LanguagesToUse -DefaultValue ''

  [string]$appVendor = Set-ADTVariable -YamlData $YamlObject.properties.appVendor -DefaultValue ''
  [string]$appName = Set-ADTVariable -YamlData $YamlObject.properties.appName -DefaultValue ''
  [string]$appVersion = Set-ADTVariable -YamlData $YamlObject.properties.appVersion -DefaultValue ''
  [string]$appArch = Set-ADTVariable -YamlData $YamlObject.properties.appArch -DefaultValue ''
  [string]$appLang = Set-ADTVariable -YamlData $YamlObject.properties.appLang -DefaultValue 'EN'
  [string]$appRevision = Set-ADTVariable -YamlData $YamlObject.properties.appRevision -DefaultValue '01'
  [string]$appScriptVersion = Set-ADTVariable -YamlData $YamlObject.properties.appScriptVersion -DefaultValue '1.0.0'
  [string]$appScriptDate = Set-ADTVariable -YamlData $YamlObject.properties.appScriptDate -DefaultValue 'XX/XX/20XX'
  [string]$appScriptAuthor = Set-ADTVariable -YamlData $YamlObject.properties.appScriptAuthor -DefaultValue '<author name>'
	##*===============================================
	## Variables: Install Titles (Only set here to override defaults set by the toolkit)
  [string]$installName = Set-ADTVariable -YamlData $YamlObject.properties.installName -DefaultValue ''
  [string]$installTitle = Set-ADTVariable -YamlData $YamlObject.properties.installTitle -DefaultValue ''

	##* Do not modify section below
	#region DoNotModify

	## Variables: Exit Code
	[int32]$mainExitCode = 0

	## Variables: Script
  [string]$deployAppScriptFriendlyName = Set-ADTVariable -YamlData $YamlObject.properties.deployAppScriptFriendlyName -DefaultValue 'Deploy Application'
  [string]$deployAppScriptVersion = Set-ADTVariable -YamlData $YamlObject.properties.deployAppScriptVersion -DefaultValue '3.8.3'
  [string]$deployAppScriptDate = Set-ADTVariable -YamlData $YamlObject.properties.deployAppScriptDate -DefaultValue '30/09/2020'
	[hashtable]$deployAppScriptParameters = $psBoundParameters

	## Variables: Environment
	If (Test-Path -LiteralPath 'variable:HostInvocation') { $InvocationInfo = $HostInvocation } Else { $InvocationInfo = $MyInvocation }
	[string]$scriptDirectory = Split-Path -Path $InvocationInfo.MyCommand.Definition -Parent

	## Dot source the required App Deploy Toolkit Functions
	Try {
		[string]$moduleAppDeployToolkitMain = "$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"
		If (-not (Test-Path -LiteralPath $moduleAppDeployToolkitMain -PathType 'Leaf')) { Throw "Module does not exist at the specified location [$moduleAppDeployToolkitMain]." }
		If ($DisableLogging) { . $moduleAppDeployToolkitMain -DisableLogging } Else { . $moduleAppDeployToolkitMain }
	}
	Catch {
		If ($mainExitCode -eq 0){ [int32]$mainExitCode = 60008 }
		Write-Error -Message "Module [$moduleAppDeployToolkitMain] failed to load: `n$($_.Exception.Message)`n `n$($_.InvocationInfo.PositionMessage)" -ErrorAction 'Continue'
		## Exit the script, returning the exit code to SCCM
		If (Test-Path -LiteralPath 'variable:HostInvocation') { $script:ExitCode = $mainExitCode; Exit } Else { Exit $mainExitCode }
	}

	#endregion
	##* Do not modify section above
	##*===============================================
	##* END VARIABLE DECLARATION
	##*===============================================

	If ($deploymentType -ine 'Uninstall' -and $deploymentType -ine 'Repair') {
		##*===============================================
		##* PRE-INSTALLATION
		##*===============================================
    [string]$installPhase = 'Pre-Installation'

		## Show Welcome Message, close Internet Explorer if required, allow up to 3 deferrals, verify there is enough disk space to complete the install, and persist the prompt
		Show-InstallationWelcome -CloseApps 'iexplore' -AllowDefer -DeferTimes 3 -CheckDiskSpace -PersistPrompt

		## Show Progress Message (with the default message)
		Show-InstallationProgress

    ## <Perform Pre-Installation tasks here>
    
    Set-YAMLActions -installPhase $installPhase -yamlData $YamlObject.preInstallation


		##*===============================================
		##* INSTALLATION
		##*===============================================
		[string]$installPhase = 'Installation'

		## Handle Zero-Config MSI Installations
		If ($useDefaultMsi) {
			[hashtable]$ExecuteDefaultMSISplat =  @{ Action = 'Install'; Path = $defaultMsiFile }; If ($defaultMstFile) { $ExecuteDefaultMSISplat.Add('Transform', $defaultMstFile) }
			Execute-MSI @ExecuteDefaultMSISplat; If ($defaultMspFiles) { $defaultMspFiles | ForEach-Object { Execute-MSI -Action 'Patch' -Path $_ } }
		}

		## <Perform Installation tasks here>
    
    Set-YAMLActions -installPhase $installPhase -yamlData $YamlObject.installation


		##*===============================================
		##* POST-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Installation'

		## <Perform Post-Installation tasks here>
    
    Set-YAMLActions -installPhase $installPhase -yamlData $YamlObject.postInstallation

		## Display a message at the end of the install
		If (-not $useDefaultMsi) { Show-InstallationPrompt -Message 'You can customize text to appear at the end of an install or remove it completely for unattended installations.' -ButtonRightText 'OK' -Icon Information -NoWait }
	} ElseIf ($deploymentType -ieq 'Uninstall') {
		##*===============================================
		##* PRE-UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Pre-Uninstallation'

		## Show Welcome Message, close Internet Explorer with a 60 second countdown before automatically closing
		Show-InstallationWelcome -CloseApps 'iexplore' -CloseAppsCountdown 60

		## Show Progress Message (with the default message)
		Show-InstallationProgress

		## <Perform Pre-Uninstallation tasks here>
    
    Set-YAMLActions -installPhase $installPhase -yamlData $YamlObject.preUninstallation


		##*===============================================
		##* UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Uninstallation'

		## Handle Zero-Config MSI Uninstallations
		If ($useDefaultMsi) {
			[hashtable]$ExecuteDefaultMSISplat =  @{ Action = 'Uninstall'; Path = $defaultMsiFile }; If ($defaultMstFile) { $ExecuteDefaultMSISplat.Add('Transform', $defaultMstFile) }
			Execute-MSI @ExecuteDefaultMSISplat
		}

		# <Perform Uninstallation tasks here>
    
    Set-YAMLActions -installPhase $installPhase -yamlData $YamlObject.uninstallation


		##*===============================================
		##* POST-UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Uninstallation'

		## <Perform Post-Uninstallation tasks here>
    
    Set-YAMLActions -installPhase $installPhase -yamlData $YamlObject.postUninstallation

	} ElseIf ($deploymentType -ieq 'Repair') {
		##*===============================================
		##* PRE-REPAIR
		##*===============================================
		[string]$installPhase = 'Pre-Repair'

		## Show Progress Message (with the default message)
		Show-InstallationProgress

		## <Perform Pre-Repair tasks here>
    
    Set-YAMLActions -installPhase $installPhase -yamlData $YamlObject.preRepair

		##*===============================================
		##* REPAIR
		##*===============================================
		[string]$installPhase = 'Repair'

		## Handle Zero-Config MSI Repairs
		If ($useDefaultMsi) {
			[hashtable]$ExecuteDefaultMSISplat =  @{ Action = 'Repair'; Path = $defaultMsiFile; }; If ($defaultMstFile) { $ExecuteDefaultMSISplat.Add('Transform', $defaultMstFile) }
			Execute-MSI @ExecuteDefaultMSISplat
		}
		# <Perform Repair tasks here>
    
    Set-YAMLActions -installPhase $installPhase -yamlData $YamlObject.repair

		##*===============================================
		##* POST-REPAIR
		##*===============================================
		[string]$installPhase = 'Post-Repair'

		## <Perform Post-Repair tasks here>
    
    Set-YAMLActions -installPhase $installPhase -yamlData $YamlObject.postRepair


  }
	##*===============================================
	##* END SCRIPT BODY
	##*===============================================

	## Call the Exit-Script function to perform final cleanup operations
	Exit-Script -ExitCode $mainExitCode
#}
#Catch {
#	[int32]$mainExitCode = 60001
#	[string]$mainErrorMessage = "$(Resolve-Error)"
#	Write-Log -Message $mainErrorMessage -Severity 3 -Source $deployAppScriptFriendlyName
#	Show-DialogBox -Text $mainErrorMessage -Icon 'Stop'
#	Exit-Script -ExitCode $mainExitCode
#}
