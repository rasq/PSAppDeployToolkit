$Global:PSScriptRoot            = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$Global:ParentScriptRoot        = Split-Path $PSScriptRoot -Parent

$Global:ConfigFilesPath         = $ParentScriptRoot + "\Sources\ConfigFiles"
$Global:PrerequisitesPath       = $ParentScriptRoot + "\Sources\Prerequisites"
$Global:SourcePath              = $ParentScriptRoot + "\Sources"
$Global:ProgramData             = $env:ProgramData
$Global:ProgramFiles64          = $env:ProgramFiles
$Global:ProgramFiles            = ${env:ProgramFiles(x86)}
$Global:windir                  = $env:windir
$Global:Temp                    = $env:Temp
$Global:PUBLIC                  = $env:PUBLIC
$Global:COMMONPROGRAMFILES64    = $env:COMMONPROGRAMFILES
$Global:PKGTMP                  = $ProgramData + "\PKGTmp\"
$Global:rootDrive               = $PSScriptRoot.SubString(0,2)
$Global:TagsDir                 = Join-Path -Path ${env:ProgramFiles(x86)} -ChildPath Logs

$Global:RCMissingParameter      = -1

#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function Set-YAMLActions {
  param(
      [Parameter(Mandatory = $True)]
      [String]$installPhase, 
      [Parameter(Mandatory = $True)]
      [AllowEmptyString()]
      [AllowNull()]
      $yamlData
  )

  if (($yamlData -ne "") -and ($yamlData -ne " ") -and ($null -ne $yamlData) -and ($empty -ne $yamlData)) {
    $yamlData.keys | ForEach-Object {
        $name = $_
        $actionDate = $yamlData.$name
        if ($name -like "msi_*") { Set-MSI -actionDate $actionDate }
        if ($name -like "exe_*") { Set-EXE -actionDate $actionDate }
        if ($name -like "file_*") { Set-File -actionDate $actionDate }
        if ($name -like "directory_*") { Set-Directory -actionDate $actionDate }
        if ($name -like "service_*") { Set-Service -actionDate $actionDate }
        if ($name -like "registry_*") { Set-Registry-actionDate $actionDate }
        if ($name -like "process_*") { Set-Process -actionDate $actionDate }
        if ($name -like "sleep_*") { Set-Sleep -actionDate $actionDate }
        if ($name -like "script_*") { Set-Script -actionDate $actionDate }
        if ($name -like "archive_*") { Set-Archive -actionDate $actionDate }
        if ($name -like "winfeature_*") { Set-WinFeature -actionDate $actionDate }
        if ($name -like "systemsettings_*") { Set-SysSettings -actionDate $actionDate }
        if ($name -like "dll_*") { Set-DLL -actionDate $actionDate }

    <# if (($Name -eq "DetectionMethod") -or ($Name -eq "DM")) { $RC = Set-DetectionMethod -actionName $Action -Data $Data -DataType $DataType } 
    if ($Name -eq "MSIInTune") { $RC = Set-MSIInTune -actionName $Action -Data $Data -DataType $DataType}
    if ($Name -eq "MSIInTuneMA") { $RC = Set-MSIInTuneMA -actionName $Action -Data $Data -DataType $DataType}
    if ($Name -eq "APPV") { $RC = Set-AppVAction -actionName $Action -Data $Data } 
    if ($Name -eq "AppVCG") { $RC = Set-AppVCGAction -actionName $Action -Data $Data } 
    if ($Name -eq "XMLAppVCG") { $RC = Create-AppVCGXML -actionName $Action -Data $Data } 
    if ($Name -eq "GETREG") { $RC = Get-Registry -actionName $Action -Data $Data } 
    if ($Name -eq "MSIVersion") { $RC = Get-MSIVersion -actionName $Action -Data $Data } 
    if ($Name -eq "DisplayWindow") { $RC = Set-DisplayWindow -actionName $Action -Data $Data } 
    if ($Name -eq "TAG") { $RC = Set-Tag -actionName $Action -Data $Data }
    if ($Name -eq "AS") { $RC = Set-ActiveSetupVal -actionName $Action -Data $Data }
    if ($Name -eq "VAR") { $RC = Set-Vars -actionName $Action -Data $Data }
    if ($Name -eq "SVAR") { $RC = Set-ScriptVars -actionName $Action -Data $Data }
    if ($Name -eq "IF") { $RC = Set-If -actionName $Action -Data $Data -actionState $actionName }
    if ($Name -eq "MSIX") { $RC = Set-MSIX -actionName $Action -Data $Data }
    if ($Name -eq "PERMISSIONS") { $RC = Set-Permissions -actionName $Action -Data $Data }
    if ($Name -eq "OFFICE") { $RC = Set-Office -actionName $Action -Data $Data -DataType $DataType }
    if ($Name -eq "UNBLOCKFILE") { $RC = Set-UnblockFiles -actionName $Action -Data $Data }
    if ($Name -eq "SCHEDULEDTASK") { $RC = Set-ScheduledTask -actionName $Action -Data $Data }
    if ($Name -eq "PINNEDAPPS") { $RC = Set-PinnedApps -actionName $Action -Data $Data }
    if ($Name -eq "LNK") { $RC = Set-Lnk -actionName $Action -Data $Data } #>
    }
  } 
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function Set-MSI {
  param(
      [Parameter(Mandatory = $True)]
      $actionDate
  )

  <# 
  appName: "testApp"
  appVer: "1.0.0"
  msiFile: "app.msi"
  mstFile: "app.mst"
  mspFile: "app.msp"
  GUID: "appFromReg"
  processName: "adf.vbs"
  params: "" #>

  #TODO:
  # - add  process checking durrin install and uninstall
  # - add version checking durring ADD if version prowided

  Write-Log -Message "Starting: $($MyInvocation.MyCommand)/$($actionDate.appName)." -Source $deployAppScriptFriendlyName

  $appName = $actionDate.appName
  $appVer = $actionDate.appVer
  $msiFile = $actionDate.msiFile
  $mstFile = $actionDate.mstFile
  $mspFile = $actionDate.mspFile
  $GUID = $actionDate.GUID
  $processName = $actionDate.processName
  $params = $actionDate.params

  $msiFile = Set-FullStringsFromVars -VarToCheck $msiFile
  $mstFile = Set-FullStringsFromVars -VarToCheck $mstFile
  $mspFile = Set-FullStringsFromVars -VarToCheck $mspFile

  $processName = Set-FullStringsFromVars -VarToCheck $processName
  $params = Set-FullStringsFromVars -VarToCheck $params

  If ($actionDate.action.ToUpper() -eq "ADD") {
    $msiFiles = Get-MultiData -SrcData $msiFile -PreData $SourcePath
    $mstFiles = Get-MultiData -SrcData $mstFile -PreData $SourcePath
    $mspFiles = Get-MultiData -SrcData $mspFile -PreData $SourcePath	
    
    $allParams = Get-MultiData -SrcData $params -Delimeter "|"
    $appNames = Get-MultiData -SrcData $appName

    if (($msiFiles.Length -gt 0) -and ($msiFiles[0] -ne "") -and ($null -ne $msiFiles[0])) { 
      $x = 0
      foreach($msi in $msiFiles) { 
        Test-IfParamFileExist -path $msi
        if ($msiFiles.Length -eq $mstFile.Length) { 
          Test-IfParamFileExist -path $mstFiles[$x]
          $CurrentMSIGUID = Get-MsiTableProperty -Path "$msi" -TransformPath "$($mstFiles[$x])" -Table 'Property' | Select-Object -ExpandProperty 'ProductCode' 
        } else { $CurrentMSIGUID = Get-MsiTableProperty -Path "$msi" -Table 'Property' | Select-Object -ExpandProperty 'ProductCode' }
        
        $regGUID = Get-InstalledApplication -ProductCode $CurrentMSIGUID	
        
        if ($CurrentMSIGUID -eq $regGUID) {
          Write-Log -Message "Uninstalling $CurrentMSIGUID." -Source $deployAppScriptFriendlyName	
          Remove-MSIApplications -Name $CurrentMSIGUID -LogNameV "$CurrentMSIGUID-uninstall"
        }

        if ($msiFiles.Length -eq $appNames.Length) { $logTagName = $appNames[$x] }
        else { $logTagName = $CurrentMSIGUID }

        if ($msiFiles.Length -eq $mstFile.Length) {
          if ($msiFiles.Length -eq $allParams.Length) { Execute-MSI -Action 'Install' "$msi" -Transform "$($mstFiles[$x])" -LogNameV "$logTagName" -AddParameters "$($allParams[$x])" }
          else { Execute-MSI -Action 'Install' "$msi" -Transform "$($mstFiles[$x])" -LogNameV "$logTagName" }
        } else { 
          if ($msiFiles.Length -eq $allParams.Length) { Execute-MSI -Action 'Install' "$msi" -LogNameV "$logTagName" -AddParameters "$($allParams[$x])" }
          else { Execute-MSI -Action 'Install' "$msi" -LogNameV "$logTagName" }
        }
        
        if ($msiFiles.Length -eq $mspFiles.Length) { 
          Test-IfParamFileExist -path $mspFiles[$x]
          Execute-MSP -Path "$($mspFiles[$x])" 
        }

        Set-Tags -actionDate "$logTagName"
        $x++
      }
    } elseif (($mspFiles.Length -gt 0) -and ($mspFiles[0] -ne "") -and ($null -ne $mspFiles[0])) { 
      foreach($msp in $mspFiles) { 
        Test-IfParamFileExist -path $msp
        Execute-MSP -Path "$msp" 
      }
    }
 
  } elseif ($actionDate.action.ToUpper() -eq "REMOVE") {
    $GUIDs = Get-MultiData -SrcData $GUID
    $appsVer = Get-MultiData -SrcData $appVer

    $allParams = Get-MultiData -SrcData $params -Delimeter "|"
    $appNames = Get-MultiData -SrcData $appName

    if (($GUIDs.Length -gt 0) -and ($GUIDs[0] -ne "") -and ($null -ne $GUIDs[0])) { 
      $x = 0
      foreach($app in $GUIDs) { 
        if (Test-IsGuid -ObjectGuid $app) {
          if ($GUIDs.Length -eq $appNames.Length) { 
            if ($GUIDs.Length -eq $allParams.Length) { Execute-MSI -Action 'Uninstall' -Path "$app" -AddParameters "$($allParams[$x])" -LogName $appNames[$x] }
            else { Execute-MSI -Action 'Uninstall' -Path "$app" -LogName $appNames[$x] }
          } else { 
            if ($GUIDs.Length -eq $allParams.Length) { Execute-MSI -Action 'Uninstall' -Path "$app" -AddParameters "$($allParams[$x])" }
            else { Execute-MSI -Action 'Uninstall' -Path "$app" }
          }
        } else {
          if ($GUIDs.Length -eq $appNames.Length) { 
            if ($GUIDs.Length -eq $allParams.Length) { 
              if ($GUIDs.Length -eq $appsVer.Length) { Remove-MSIApplications -Name $app -LogNameV $appNames[$x] -AddParameters "$($allParams[$x])" -FilterApplication ('DisplayVersion', $appsVer[$x], 'Exact') }
              else { Remove-MSIApplications -Name $app -LogNameV $appNames[$x] -AddParameters "$($allParams[$x])" }
            } else { 
              if ($GUIDs.Length -eq $appsVer.Length) { Remove-MSIApplications -Name $app -LogNameV $appNames[$x] -FilterApplication ('DisplayVersion', $appsVer[$x], 'Exact') }
              else { Remove-MSIApplications -Name $app -LogNameV $appNames[$x] }
            }
          } else {
            if ($GUIDs.Length -eq $allParams.Length) { 
              if ($GUIDs.Length -eq $appsVer.Length) { Remove-MSIApplications -Name $app -AddParameters "$($allParams[$x])" -FilterApplication ('DisplayVersion', $appsVer[$x], 'Exact') }
              else { Remove-MSIApplications -Name $app -AddParameters "$($allParams[$x])" }
            } else { 
              if ($GUIDs.Length -eq $appsVer.Length) { Remove-MSIApplications -Name $app -FilterApplication ('DisplayVersion', $appsVer[$x], 'Exact') }
              else { Remove-MSIApplications -Name $app }
            }
          }
        }

        if ($GUIDs.Length -eq $appNames.Length) { Set-Tags -actionDate $appNames[$x] }
        $x++
      }
    }
  } else {
    Write-Log -Message "Script failed, missing or bad ACTION parameter in $($MyInvocation.MyCommand)/$($actionDate.appName)" -Severity 3 -Source $deployAppScriptFriendlyName
    Exit-Script -ExitCode $Global:RCMissingParameter
  }

}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function Set-EXE {
  param(
      [Parameter(Mandatory = $True)]
      $actionDate
  )

  If ($actionDate.action.ToUpper() -eq "ADD") {
  } elseif ($actionDate.action.ToUpper() -eq "REMOVE") {
  }
  
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function Set-File {
  param(
      [Parameter(Mandatory = $True)]
      $actionDate
  )

  If ($actionDate.action.ToUpper() -eq "ADD") {
  } elseif ($actionDate.action.ToUpper() -eq "REMOVE") {
  } elseif ($actionDate.action.ToUpper() -eq "COPY") {
  } elseif ($actionDate.action.ToUpper() -eq "MOVE") {
  } elseif ($actionDate.action.ToUpper() -eq "EDIT") {
  }
  
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function Set-Directory {
  param(
      [Parameter(Mandatory = $True)]
      $actionDate
  )

  If ($actionDate.action.ToUpper() -eq "ADD") {
  } elseif ($actionDate.action.ToUpper() -eq "REMOVE") {
  } elseif ($actionDate.action.ToUpper() -eq "COPY") {
  } elseif ($actionDate.action.ToUpper() -eq "MOVE") {
  }
  
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function Set-Script {
  param(
      [Parameter(Mandatory = $True)]
      $actionDate
  )

  <# script_1:
    scriptName: "script.ps1"
    scriptDir: "c:\\asd"
    scriptParam: "-uninstall true" #>
  
  Write-Log -Message "Starting: $($MyInvocation.MyCommand)/$($actionDate.appName)." -Source $deployAppScriptFriendlyName

    $scriptName = Get-MultiData -SrcData $scriptName
    $scriptDir = Get-MultiData -SrcData $scriptDir
    $scriptParam = Get-MultiData -SrcData $scriptParam

  if (($scriptName.Length -gt 0) -and ($msiFiles[0] -ne "") -and ($null -ne $msiFiles[0])) { 
    $x = 0
    foreach($msi in $msiFiles) { 
    }
  } else {
    Write-Log -Message "Script failed, missing or bad scriptName parameter in $($MyInvocation.MyCommand)" -Severity 3 -Source $deployAppScriptFriendlyName
    Exit-Script -ExitCode $Global:RCMissingParameter
  }
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function Set-Tags {
  param(
      [Parameter(Mandatory = $True)]
      $actionDate,
      [Parameter(Mandatory = $False)]
      $Action = "ADD"
  )

  
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function Set-FullStringsFromVars {
    param(
        [Parameter(Mandatory = $True)]
        [AllowEmptyString()]
        [AllowNull()]
        [String]$VarToCheck
    )

    if (($VarToCheck -eq "") -or ($VarToCheck -eq " ") -or ($null -eq $VarToCheck) -or ($empty -eq $VarToCheck)) { Return "" }
    else {
      $tempered = $False
      $VarToCheckBak  = $VarToCheck
      $VarToCheck     = $VarToCheck.ToLower()


          if (Get-IsToChange -VarToTest "%programdata%" -VarToChange $VarToCheckBak) { $VarToCheck = $VarToCheckBak.Replace("%programdata%",$ProgramData); $tempered = $True }
          if (Get-IsToChange -VarToTest "%logfiles%" -VarToChange $VarToCheck) { $VarToCheck = $VarToCheck.Replace("%logfiles%",$env:LOGFILES); $tempered = $True }
          if (Get-IsToChange -VarToTest "%programfiles(x86)%" -VarToChange $VarToCheck) { $VarToCheck = $VarToCheck.Replace("%programfiles(x86)%",$ProgramFiles); $tempered = $True }
          if (Get-IsToChange -VarToTest "%programfiles64%" -VarToChange $VarToCheck) { $VarToCheck = $VarToCheck.Replace("%programfiles64%",$ProgramFiles64); $tempered = $True }
          #if (($VarToCheck -like "%programfiles64%*") -or ($VarToCheck -like "*%programfiles64%*") -or ($VarToCheck -like "%programfiles64%") -or ($VarToCheck -like "*%programfiles64%")) { $VarToCheck = $VarToCheck.Replace("%programfiles64%",$ProgramFiles64); $tempered = $True }
          #if (($VarToCheck -like "%programfiles%*") -or ($VarToCheck -like "*%programfiles%*") -or ($VarToCheck -like "%programfiles%") -or ($VarToCheck -like "*%programfiles%")) { $VarToCheck = $VarToCheck.Replace("%programfiles%",$ProgramFiles); $tempered = $True }
          if (Get-IsToChange -VarToTest "%configfilespath%" -VarToChange $VarToCheck) { $VarToCheck = $VarToCheck.Replace("%configfilespath%",$ConfigFilesPath); $tempered = $True }
          if (Get-IsToChange -VarToTest "%srcfilepath%" -VarToChange $VarToCheck) { $VarToCheck = $VarToCheck.Replace("%srcfilepath%",$SourcePath); $tempered = $True }
          if (Get-IsToChange -VarToTest "%windir%" -VarToChange $VarToCheck) { $VarToCheck = $VarToCheck.Replace("%windir%",$windir); $tempered = $True }
          if (Get-IsToChange -VarToTest "%allusers%" -VarToChange $VarToCheck) { $VarToCheck = $VarToCheck.Replace("%allusers%",""); $tempered = $True } 
          if (Get-IsToChange -VarToTest "%temp%" -VarToChange $VarToCheck) { $VarToCheck = $VarToCheck.Replace("%temp%",$Temp); $tempered = $True }
          if (Get-IsToChange -VarToTest "%public%" -VarToChange $VarToCheck) { $VarToCheck = $VarToCheck.Replace("%public%",$PUBLIC); $tempered = $True }
          if (Get-IsToChange -VarToTest "%programdata%" -VarToChange $VarToCheck) { $VarToCheck = $VarToCheck.Replace("%programdata%",$ProgramData); $tempered = $True }
          if (Get-IsToChange -VarToTest "%commonprogramfiles%" -VarToChange $VarToCheck) { $VarToCheck = $VarToCheck.Replace("%commonprogramfiles%",$COMMONPROGRAMFILES64); $tempered = $True }
          if (Get-IsToChange -VarToTest "%systemdrive%" -VarToChange $VarToCheck) { $VarToCheck = $VarToCheck.Replace("%systemdrive%",$env:SystemDrive); $tempered = $True }
          if (Get-IsToChange -VarToTest "%rootdrive%" -VarToChange $VarToCheck) { $VarToCheck = $VarToCheck.Replace("%rootdrive%",$env:SystemDrive); $tempered = $True }
          if (Get-IsToChange -VarToTest "%pkglogdir%" -VarToChange $VarToCheck) { $VarToCheck = $VarToCheck.Replace("%pkglogdir%",$configToolkitLogDir); $tempered = $True }
          if (Get-IsToChange -VarToTest "%PKGName%" -VarToChange $VarToCheck) { $VarToCheck = $VarToCheck.Replace("%PKGName%",$Global:PKGName); $tempered = $True }
          if (Get-IsToChange -VarToTest "%hostname%" -VarToChange $VarToCheck) { $VarToCheck = $VarToCheck.Replace("%hostname%",$env:computername); $tempered = $True }
          if (Get-IsToChange -VarToTest "%prelogdir%" -VarToChange $VarToCheck) { $VarToCheck = $VarToCheck.Replace("%prelogdir%",$PreLogDir); $tempered = $True }
          if (Get-IsToChange -VarToTest "%computername%" -VarToChange $VarToCheck) { $VarToCheck = $VarToCheck.Replace("%computername%",$env:computername); $tempered = $True }
          if (Get-IsToChange -VarToTest "%domain%" -VarToChange $VarToCheck) { $VarToCheck = $VarToCheck.Replace("%domain%",$env:USERDOMAINNAME); $tempered = $True }

          if (Get-IsToChange -VarToTest "%datetime%" -VarToChange $VarToCheck) { 
              $DateTime = Get-Date -Format "yyyy_MM_dd_hh_mm_ss"
              $VarToCheck = $VarToCheck.Replace("%datetime%",$DateTime)
              $tempered = $True 
          }
              
      # %SYSTEMDRIVE% %COMMONPROGRAMFILES(x86)%
      # AllUsersStartMenu AllUsersPrograms AllUsersStartup AllUsersDesktop Fonts		
      
      If ($tempered) { Return $VarToCheck }
      else { Return $VarToCheckBak }
    }
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function Get-IsToChange {
  param(
      [Parameter(Mandatory = $True)]
      [String]$VarToTest,
      [Parameter(Mandatory = $True)]
      [String]$VarToChange
  )
  
  if (($VarToChange -like "$VarToTest*") -or ($VarToChange -like "*$VarToTest*") -or ($VarToChange -like "$VarToTest") -or ($VarToChange -like "*$VarToTest")) { return $true }
  else { return $false } 
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function Get-MultiData {
  param(
      [Parameter(Mandatory = $True)]
      [String]$SrcData,
      [Parameter(Mandatory = $False)]
      [String]$PreData = "null",
      [Parameter(Mandatory = $False)]
      [String]$Delimeter = ","
  )
  
  if (($SrcData -like "*$Delimeter*") -or ($SrcData -like "*$Delimeter") -or ($SrcData -like "$Delimeter*")) { $returnData = $SrcData.Split($Delimeter) }
  else { $returnData = $SrcData }

  if ($PreData -ne "null") {
    $x = 0
    foreach ($data in $returnData) {
      if (($data -like "\*") -or ((-not ($data -like "*:\*")))) { $returnData[0] = "$PreData\$data" }
      $x++
    }
  }

  Return $returnData
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function Test-IfParamFileExist {
    param(
        [Parameter(Mandatory = $True)]
        [String]$path
    )

    Write-Log -Message "Testing if: $path is a path or file and if param exist."

    If ((Test-Path -Path $path) -eq $True) { Write-Log -Message "Path: $path exist, going next."; Return $True }
    elseif (([System.IO.File]::Exists($path)) -eq $True) { Write-Log -Message "File: $path exist, going next."; Return $True }
    elseif ("null" -eq $path) { Write-Log -Message "Skipping param, is null."; Return $True }
    else { Write-Log -Message "$path missing, exiting script with RC = -1."; Set-Finalize -ExitCode -1 }
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function Test-IsGuid {
  [OutputType([bool])]
  param (
    [Parameter(Mandatory = $true)]
    [string]$ObjectGuid
  )
  
  [regex]$guidRegex = '(?im)^[{(]?[0-9A-F]{8}[-]?(?:[0-9A-F]{4}[-]?){3}[0-9A-F]{12}[)}]?$'
  
  return $ObjectGuid -match $guidRegex
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
