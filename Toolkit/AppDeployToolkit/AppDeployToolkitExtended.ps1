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
        if ($name -like "msix_*") { Set-MSIX -actionDate $actionDate }
        if ($name -like "exe_*") { Set-EXE -actionDate $actionDate }
        if ($name -like "appv_*") { Set-APPV -actionDate $actionDate }
        if ($name -like "appvCG_*") { Set-APPVCG -actionDate $actionDate }
        if ($name -like "file_*") { Set-File -actionDate $actionDate }
        if ($name -like "directory_*") { Set-Directory -actionDate $actionDate }                #to test, basic logic was done.
        if ($name -like "service_*") { Set-Services -actionDate $actionDate }                   #to test, basic logic was done.
        if ($name -like "registry_*") { Set-Registry-actionDate $actionDate }
        if ($name -like "process_*") { Set-Process -actionDate $actionDate }
        if ($name -like "sleep_*") { Set-Sleep -actionDate $actionDate }                        #to test, basic logic was done.
        if ($name -like "script_*") { Set-Script -actionDate $actionDate }                      #to test, basic logic was done.
        if ($name -like "archive_*") { Set-Archive -actionDate $actionDate }                    #to test, basic logic was done.
        if ($name -like "winfeature_*") { Set-WinFeature -actionDate $actionDate }              #to test, basic logic was done.
        if ($name -like "systemsettings_*") { Set-SysSettings -actionDate $actionDate }
        if ($name -like "dll_*") { Set-DLL -actionDate $actionDate }                            #to test, basic logic was done.
        if ($name -like "unblockfiles_*") { Set-UnblockFiles -actionDate $actionDate }          #to test, basic logic was done.
        if ($name -like "scheduledtask_*") { Set-ScheduledTask -actionDate $actionDate }
        if ($name -like "detectionmethod_*") { Set-DetectionMethod -actionDate $actionDate }

    <# 
    if ($Name -eq "GETREG") { $RC = Get-Registry -actionName $Action -Data $Data } 
    if ($Name -eq "MSIVersion") { $RC = Get-MSIVersion -actionName $Action -Data $Data } 
    if ($Name -eq "DisplayWindow") { $RC = Set-DisplayWindow -actionName $Action -Data $Data } 
    if ($Name -eq "TAG") { $RC = Set-Tag -actionName $Action -Data $Data }
    if ($Name -eq "AS") { $RC = Set-ActiveSetupVal -actionName $Action -Data $Data }
    if ($Name -eq "VAR") { $RC = Set-Vars -actionName $Action -Data $Data }
    if ($Name -eq "SVAR") { $RC = Set-ScriptVars -actionName $Action -Data $Data }
    if ($Name -eq "IF") { $RC = Set-If -actionName $Action -Data $Data -actionState $actionName }
    if ($Name -eq "PERMISSIONS") { $RC = Set-Permissions -actionName $Action -Data $Data }
    if ($Name -eq "OFFICE") { $RC = Set-Office -actionName $Action -Data $Data -DataType $DataType }
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

  if ($actionDate.action.ToUpper() -eq "ADD") {
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
Function Set-DLL {
  param(
      [Parameter(Mandatory = $True)]
      $actionDate
  )

  $DllFile = $actionDate.dllFile
  $DllPath = $actionDate.dllPath


  if (($DllFile -ne '') -and (-not ([string]::IsNullOrEmpty($DllFile)))) {
    $DllPaths = Get-MultiData -SrcData $DllPath
    $DllFiles = Get-MultiData -SrcData $DllFile
    $rootDllPath = ""

    if (($DllPaths.Length -eq 1) -and ($DllPaths[0] -ne '') -and (-not ([string]::IsNullOrEmpty($DllPaths[0])))) { $rootDllPath = $DllPaths[0] }
    
    foreach ($dll in $DllFiles) {
      if ($rootDllPath -ne "") { $dllFullPath = "$rootDllPath\$DllFile" }
      elseif (($DllPaths[$x] -ne '') -and (-not ([string]::IsNullOrEmpty($DllPaths[$x])))) { $dllFullPath = "$($DllPaths[$x])\$DllFile" }
      Else { $dllFullPath = "$SourcePath\$DllFile" }

      $dllFullPath = Set-FullStringsFromVars -VarToCheck $dllFullPath

      If ($actionDate.action.ToUpper() -eq "REMOVE") { 
          Test-IfParamFileExist -path $dllFullPath
          regsvr32 /s /u $dllFullPath 
      
          Switch ($LastExitCode) {
            0 {Write-Log -Message "Unregistration $dllFullPath succeeded. RC = 0."}
            1 {Write-Log -Message "Unregistration $dllFullPath failed. Invalid argument.RC = 1."}
            2 {Write-Log -Message "Unregistration $dllFullPath failed. OleInitialize failed. RC = 2."}
            3 {Write-Log -Message "Unregistration $dllFullPath failed. LoadLibrary failed. RC = 3."}
            4 {Write-Log -Message "Unregistration $dllFullPath failed. GetProcAdsress failed. RC = 4."}
            5 {Write-Log -Message "Unregistration $dllFullPath failed. DllUnregisterServer function failed. RC = 5."}
            Default { Write-Log -Message "Unregistration $dllFullPath status unknown."}
          }
      } ElseIf ($actionDate.action.ToUpper() -eq "ADD") { 
          Test-IfParamFileExist -path $dllFullPath
          regsvr32 /s $dllFullPath
          
          Switch ($LastExitCode) {
            0 {Write-Log -Message "Registration $dllFullPath succeeded. RC = 0."}
            1 {Write-Log -Message "Registration failed. Invalid argument. RC = 1."}
            2 {Write-Log -Message "Registration failed. OleInitialize failed. RC = 2."}
            3 {Write-Log -Message "Registration failed. LoadLibrary failed. RC = 3."}
            4 {Write-Log -Message "Registration failed. GetProcAdsress failed. RC = 4."}
            5 {Write-Log -Message "Registration failed. DllUnregisterServer function failed. RC = 5."}
            Default { Write-Log -Message "Registration $dllFullPath status unknown."}
          }
      } 
    }
  } else {
    Write-Log -Message "Script failed, missing DllFile parameter in $($MyInvocation.MyCommand)" -Severity 3 -Source $deployAppScriptFriendlyName
    Exit-Script -ExitCode $Global:RCMissingParameter
  }  
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function Set-Archive {
  param(
      [Parameter(Mandatory = $True)]
      $actionDate
  )

  #TODO:
  # - add 7zip and system zip archive and 7zip install dir detection

  $driveLetter = Split-Path -Path "$PSScriptRoot" -Qualifier
  $discSpace = Get-DiscSpace -drive $driveLetter
  
  Write-Log -Message "Current disc space: $discSpace" -Source $deployAppScriptFriendlyName

  $DirPath = $actionDate.path
  $ArchName = $actionDate.archName
  $TargetDir = $actionDate.targetPath
  $ArchType = $actionDate.type

  $DirsPath = Get-MultiData -SrcData $DirPath
  $ArchsName = Get-MultiData -SrcData $ArchName

  if (($ArchName -ne '') -and (-not ([string]::IsNullOrEmpty($ArchName)))) {
    If ($actionDate.action.ToUpper() -eq "ADD") {
      foreach ($dir in $DirsPath) {
        if ($DirsPath.Length -eq $ArchsName.Length) { $zipName = $ArchsName[$x] }
        else { $zipName = "$($ArchsName[0])_$x" }

        if ($ArchType -eq "7Z") { }
        elseif ($ArchType -eq "ZIP") {}
        elseif ($ArchType -eq "PSZIP") { New-ZipFile -DestinationArchiveDirectoryPath "$TargetDir" -DestinationArchiveFileName "$zipName.zip" -SourceDirectory "$dir" -OverWriteArchive $True }
      }
    } elseif ($actionDate.action.ToUpper() -eq "UNPACK") {
      $TargetDir = Set-FullStringsFromVars -VarToCheck $TargetDir

      foreach ($arch in $ArchsName) {
        if ($DirsPath.Length -eq $ArchsName.Length) {
          if (($DirsPath[$x] -eq "") -or ([string]::IsNullOrEmpty($DirsPath[$x]))) { $Directory = $SourcePath  } 
          else { $Directory = Set-FullStringsFromVars -VarToCheck $DirsPath[$x] }
        } else { $Directory = $SourcePath }

        $archFullPath = "$Directory\$arch"
        Test-ParamFile -path $archFullPath
        Write-Log -Message "ExtractToDirectory($archFullPath, $TargetDir)"

        if ($ArchType -eq "7Z") { 
          Test-ParamFile -path "C:\Program Files\7-Zip\7z.exe"
          & "C:\Program Files\7-Zip\7z.exe" x "$archFullPath" -o"$TargetDir" -y  
        } elseif ($ArchType -eq "ZIP") { 
          Add-Type -AssemblyName System.IO.Compression.FileSystem
          [System.IO.Compression.ZipFile]::ExtractToDirectory("$archFullPath" ,"$TargetDir")
        } elseif ($ArchType -eq "PSZIP") { Expand-Archive -LiteralPath $archFullPath -DestinationPath "$TargetDir" -Force }
      }
    }  
  } else {
    Write-Log -Message "Script failed, missing ArchName parameter in $($MyInvocation.MyCommand)" -Severity 3 -Source $deployAppScriptFriendlyName
    Exit-Script -ExitCode $Global:RCMissingParameter
  }
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function Set-Services {
  param(
      [Parameter(Mandatory = $True)]
      $actionDate
  )

  $ServiceName = $actionDate.serviceName
  $ServiceNames = Get-MultiData -SrcData $ServiceName

  
  $ServiceBinary = $actionDate.serviceBinary
  $ServiceBinarys = Get-MultiData -SrcData $ServiceBinary
  $StartupType = $actionDate.startupType
  $StartupTypes = Get-MultiData -SrcData $StartupType
  $DependsOn = $actionDate.dependsOn
  $ListDependsOn = Get-MultiData -SrcData $DependsOn

  Write-Log -Message "Starting: $($MyInvocation.MyCommand)." -Source $deployAppScriptFriendlyName 

  $x = 0

  foreach ($service in $ServiceNames) {
    if($actionDate.action.ToUpper() -eq "ADD") { 
      $ServiceBinary = $ServiceBinarys[$x]
      $ServiceBinary = Set-FullStringsFromVars -VarToCheck $ServiceBinary
      $StartupType = $StartupTypes[$x]
      $DependsOn = $ListDependsOn[$x]

      if ($DependsOn -ne "null") {
        $params = @{
          Name = "$service"
          BinaryPathName = "$ServiceBinary"
          DependsOn = "$DependsOn"
          DisplayName = "$service"
          StartupType = "$StartupType"
          Description = "$service"
        }
      } else {
        $params = @{
          Name = "$service"
          BinaryPathName = "$ServiceBinary"
          DisplayName = "$service"
          StartupType = "$StartupType"
          Description = "$service"
        }
      } New-Service @params }
      elseif ($actionDate.action.ToUpper() -eq "STOP") { If (Get-Service $service -ErrorAction SilentlyContinue) { Get-Service -Name $service | Set-Service -Status Stopped -PassThru -Force }} 
      elseif ($actionDate.action.ToUpper() -eq "REMOVE") {
        if (Get-Service -Name $service -ErrorAction SilentlyContinue) {
          Write-Log -Message "Removing: $service."
          Stop-Service $service
          Get-CimInstance -ClassName Win32_Service -Filter "Name=$service" | Remove-CimInstance
        } else { Write-Log -Message "$service is not present, nothink to remove. Going to next step." }}
      elseif ($actionDate.action.ToUpper() -eq "START") { If (Get-Service $service -ErrorAction SilentlyContinue) { Get-Service -Name $service | Set-Service  -Status Running -PassThru }}
      elseif ($actionDate.action.ToUpper() -eq "PAUSE") { If (Get-Service $service -ErrorAction SilentlyContinue) {Get-Service -Name $service | Set-Service -Status Paused }}
      elseif ($actionDate.action.ToUpper() -eq "DISABLE") { If (Get-Service $service -ErrorAction SilentlyContinue) {Get-Service -Name $service | Set-Service -StartupType Disabled -PassThru }}
    $x++
  }
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function Set-Process {
  param(
      [Parameter(Mandatory = $True)]
      $actionDate
  )

<# 
  process_1:
    actiona: "STOP"
    processName: "script.exe"
    processCMD: ""
    mode: "BLOCK"
  process_2:
    actiona: "KILL"
    processName: "script.exe"
    processCMD: ""
  process_3:
    actiona: "START"
    processName: "script.exe"
    processCMD: ""
    mode: "UNBLOCK"
 #>

  $ProcessName = $actionDate.processName
  $ProcessesNames = Get-MultiData -SrcData $ProcessName

  $x = 0

  foreach ($proces in $ProcessesNames) {
    If ($actionDate.action.ToUpper() -eq "STOP") {
    } elseif ($actionDate.action.ToUpper() -eq "KILL") {
      $ProcName = $proces.ToLower()
      $ProcName = $ProcName.Replace(".exe","")
      $KillProc = [System.Collections.ArrayList]@()

      Write-Log -Message "ProcName fo handle: $ProcName "
      Write-Log -Message "stop-process -name $ProcName -force"
      
      Get-Process -Name $ProcName | Stop-Process -Force


      if ($Action.Length -eq 2) {  
        if (($ProcName -ne "") -and ($ProcName -ne " ") -and (-not ([string]::IsNullOrEmpty($ProcName)))) {
          foreach ($ProcName in $Process) { Write-Log -Message "Adding: $ProcName to process list."; $KillProc.Add($ProcName) }
          if ($Action[1] -eq "block") { Block-AppExecution -ProcessName ($KillProc) } 
          elseif ($Action[1] -eq "unblock") { Unblock-AppExecution }
        }
      } elseif ($Action.Length -eq 3) {
        If (($Action[0] -eq "kill") -and ($Action[1] -eq "null")) {
          Write-Log -Message "stop-process -name $ProcName -force"
          stop-process -name $ProcName -force -ErrorAction SilentlyContinue
        } else {
          $cmdToKill = $Action[2]            
          Write-Log -Message "Set-Processes cmdToKill - $cmdToKill"
          if (($cmdToKill -ne "") -and ($cmdToKill -ne " ") -and (-not ([string]::IsNullOrEmpty($cmdToKill)))) {
            #get-wmiobject win32_process | Where-Object commandline -like $cmdToKill | remove-wmiobject
            $processesA = Get-WmiObject Win32_Process -Filter "name = '$ProcessesNames'"
            Write-Log -Message "Set-Processes processesA - $processesA "

            foreach($proc in $processesA) {
              if (($proc.CommandLine -like "*$cmdToKill") -or ($proc.CommandLine -like "*$cmdToKill*") -or ($proc.CommandLine -like "$cmdToKill*") -or ($proc.CommandLine -like "$cmdToKill")) {
                Write-Log -Message "Stopping proccess $($proc.ProcessId) with $($proc.ThreadCount) threads; $($proc.CommandLine.Substring(0, 50))..."
                Stop-Process -F $proc.ProcessId
              } else { Write-Log -Message "Skipping proccess $($proc.ProcessId) with $($proc.ThreadCount) threads; $($proc.CommandLine.Substring(0, 50))..." }
            }
          }
        }
      }


    } elseif ($actionDate.action.ToUpper() -eq "START") {
    }

    $x++
  }





  $ProcessesNames = $Data[0]
  $Actions = $Data[1]

  $Process = $ProcessesNames.Split(";")
  $Action = $Actions.Split(";")

  Write-Log -Message "Set-Processes ProcessesNames: $ProcessesNames,  Action: $Action "
  Write-Log -Message "Set-Processes Process - $Process "

  If ($Action.Length -gt 0) {
      If (($actionName -eq "STOP") -AND ($Action[0] -eq "kill")) {
          foreach ($ProcName in $Process) {
              $ProcName = $ProcName.ToLower()
              $ProcName = $ProcName.Replace(".exe","")
              $KillProc = [System.Collections.ArrayList]@()

              Write-Log -Message "ProcName fo handle: $ProcName "

              if ($Action.Length -eq 1) { 
                  Write-Log -Message "stop-process -name $ProcName -force"
                  stop-process -name $ProcName -force -ErrorAction SilentlyContinue #need to test and fix this arghs counting. 
              } 

              $lng = $Action.Length
              Write-Log -Message "Action.Length = $lng"

              foreach ($actionEl in $Action) { Write-Log -Message "actionEl = $actionEl" } 

              if ($Action.Length -eq 2) {  
                  if (($ProcName -ne "") -and ($ProcName -ne " ") -and (-not ([string]::IsNullOrEmpty($ProcName)))) {
                      foreach ($ProcName in $Process) { Write-Log -Message "Adding: $ProcName to process list."; $KillProc.Add($ProcName) }
                      if ($Action[1] -eq "block") { Block-AppExecution -ProcessName ($KillProc) } 
                      elseif ($Action[1] -eq "unblock") { Unblock-AppExecution }
                  }
              } elseif ($Action.Length -eq 3) {
                  If  (($Action[0] -eq "kill") -and ($Action[1] -eq "null")) {
                      Write-Log -Message "stop-process -name $ProcName -force"
                      stop-process -name $ProcName -force -ErrorAction SilentlyContinue
                  } else {
                      $cmdToKill = $Action[2]            
                      Write-Log -Message "Set-Processes cmdToKill - $cmdToKill"
                      if (($cmdToKill -ne "") -and ($cmdToKill -ne " ") -and (-not ([string]::IsNullOrEmpty($cmdToKill)))) {
                          #get-wmiobject win32_process | Where-Object commandline -like $cmdToKill | remove-wmiobject
                          $processesA = Get-WmiObject Win32_Process -Filter "name = '$ProcessesNames'"
                          Write-Log -Message "Set-Processes processesA - $processesA "
          
                          foreach($proc in $processesA) {
                              if (($proc.CommandLine -like "*$cmdToKill") -or ($proc.CommandLine -like "*$cmdToKill*") -or ($proc.CommandLine -like "$cmdToKill*") -or ($proc.CommandLine -like "$cmdToKill")) {
                                  Write-Log -Message "Stopping proccess $($proc.ProcessId) with $($proc.ThreadCount) threads; $($proc.CommandLine.Substring(0, 50))..."
                                  Stop-Process -F $proc.ProcessId
                              } else { Write-Log -Message "Skipping proccess $($proc.ProcessId) with $($proc.ThreadCount) threads; $($proc.CommandLine.Substring(0, 50))..." }
                          }
                      }
                  }
              } else {
                  Write-Log -Message "stop-process -name $ProcName -force"
                  stop-process -name $ProcName -force -ErrorAction SilentlyContinue
              }
          }
      }    
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
Function Set-WinFeature {
  param(
      [Parameter(Mandatory = $True)]
      $actionDate
  )

    $FeatureName = $actionDate.featureName

    if (($FeatureName -ne '') -and (-not ([string]::IsNullOrEmpty($FeatureName)))) {
      $FeatureNames = Get-MultiData -SrcData $FeatureName

      foreach ($feature in $FeatureNames) {
        If ($actionDate.action.ToUpper() -eq "ADD") {
            Write-Log -Message "Enable-WindowsOptionalFeature -Online -FeatureName $feature -norestart -All"
            Enable-WindowsOptionalFeature -Online -FeatureName $feature -norestart -all
        } ElseIf ($actionDate.action.ToUpper() -eq "REMOVE") {   
            Write-Log -Message "Disable-WindowsOptionalFeature -Online -FeatureName $feature -norestart"
            Disable-WindowsOptionalFeature -Online -FeatureName $feature -norestart
        } 
      }
    } else {
      Write-Log -Message "Script failed, missing featureName parameter in $($MyInvocation.MyCommand)" -Severity 3 -Source $deployAppScriptFriendlyName
      Exit-Script -ExitCode $Global:RCMissingParameter
    }  
  }
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

  
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function Set-Sleep {
  param(
      [Parameter(Mandatory = $True)]
      $actionDate
  )

  $Time = $actionDate.time

  Write-Log -Message "Starts sleep for $Time."

  If (($Time -like "*s") -or ($Time -like "*S")) {
    $Time = $Time.Replace("s","")
    $Time = $Time.Replace("S","")
    Start-Sleep -Seconds $Time 
  } else { Start-Sleep -Milliseconds $Time } 
  
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

 <#  directory_1:
  action: "REMOVE"
  targetDir: "c:\\asd"
  force: "true"
directory_2:
  action: "ADD"
  targetDir: "c:\\asd"
directory_3:
  action: "COPY"
  targetDir: "c:\\asd"
  sourceDir: "c:\\test\\"
directory_4:
  action: "MOVE"
  targetDir: "c:\\asd"
  sourceDir: "c:\\test\\"
  directory_5:
    action: "RENAME"
    targetDir: "c:\\asd"
    newName: "test"#>

  $Directory = $actionDate.targetDir
  $Directory = Set-FullStringsFromVars -VarToCheck $Directory
  $Dirs = Get-MultiData -SrcData $Directory

  $SrcDirectory = $actionDate.sourceDir
  $SrcDirectory = Set-FullStringsFromVars -VarToCheck $SrcDirectory
  $SrcDirs = Get-MultiData -SrcData $SrcDirectory

  $newName = $actionDate.newName

  $isForce = $actionDate.force
  if (($isForce -ne '') -and (-not ([string]::IsNullOrEmpty($isForce)))) { $isAllForce = Get-MultiData -SrcData $isForce }

  $mode = $actionDate.mode
  if (($mode -ne '') -and (-not ([string]::IsNullOrEmpty($mode)))) { $allModes = Get-MultiData -SrcData $mode }

  $forAllUsers = $False
  if (($Directory -like "*%allusers%*") -or ($Directory -like "%allusers%*")) { $forAllUsers = $True }
  if (($SrcDirectory -like "*%allusers%*") -or ($SrcDirectory -like "%allusers%*")) { $forAllUsers = $True }

  If ($actionDate.action.ToUpper() -eq "ADD") {
    $x = 0
    foreach ($dir in $Dirs) {
      if ($isAllForce.Length -eq $Dirs.Length) { $localForce = $isAllForce[$x] }
      elseif (($isForce -ne '') -and (-not ([string]::IsNullOrEmpty($isForce)))) { $localForce = $isForce }
      else { $localForce = $true }

      if ($forAllUsers -eq $True) {
        ForEach ($User In (Get-WmiObject Win32_UserProfile -F "Special != True" | Select-Object -Expand LocalPath)) {
            Write-Log -Message "\User\dir - $($User)$dir"
            $dir = "$User$dir"
            if (-not(Test-Path $dir -PathType Container)) { New-Item -ItemType Directory -Path $dir -Force:$localForce | Out-Null }
        }
      } else { 
        if (-not(Test-Path $dir -PathType Container)) { New-Item -ItemType Directory -Path $dir -Force:$localForce | Out-Null }
      }

      $x++
    }
  } elseif ($actionDate.action.ToUpper() -eq "REMOVE") {
    $x = 0
    foreach ($dir in $Dirs) {
      if ($allModes.Length -eq $Dirs.Length) { $dirMode = $allModes[$x] }
      elseif (($allModes -ne '') -and (-not ([string]::IsNullOrEmpty($allModes)))) { $dirMode = $mode }
      else { $dirMode = $true }

      if ($isAllForce.Length -eq $Dirs.Length) { $localForce = $isAllForce[$x] }
      elseif (($isForce -ne '') -and (-not ([string]::IsNullOrEmpty($isForce)))) { $localForce = $isForce }
      else { $localForce = $true }

      $LastChar = $Directory.Substring($dir.get_Length()-1)

      if ($forAllUsers -eq $True) {
        ForEach ($User In (Get-WmiObject Win32_UserProfile -F "Special != True" | Select-Object -Expand LocalPath)) {
          Write-Log -Message "\User\dir - $($User)$dir"
          $dir = "$User$dir"

          If ($LastChar -eq "*") {
            $BaseDir = ""
            $DirArr = $dir.Split("\")
            $ArrLeng = $DirArr.Length

            Write-Log -Message -Message "ArrLeng: $ArrLeng " -Severity 2 -Source $deployAppScriptFriendlyName

            For ($x = 0; $x -lt $ArrLeng - 1; $x++) {
                Write-Log -Message -Message "DirArr[$x]: $DirArr[$x] " -Severity 2 -Source $deployAppScriptFriendlyName
                If ($BaseDir -eq "") { $BaseDir = $DirArr[$x] }
                else { $BaseDir = $BaseDir + "\" + $DirArr[$x] }
            }

            $PartName = ($DirArr[$DirArr.Length - 1]).Trim("*")
            $Paths = Get-ChildItem $BaseDir | Where-Object {$_.Attributes -match'Directory'}

            If (!($Paths)) { Write-Log -Message "There is no folders match the criterium." } 
            Else {
              Write-Log -Message -Message "PartName: $PartName " -Severity 2 -Source $deployAppScriptFriendlyName
              Write-Log -Message -Message "BaseDir: $BaseDir " -Severity 2 -Source $deployAppScriptFriendlyName
              Write-Log -Message -Message "Paths: $Paths " -Severity 2 -Source $deployAppScriptFriendlyName

              foreach($path in $Paths) {
                $dirP = $path.FullName
                If (($dirP -like "*$PartName*") -or ($dirP -like "*$PartName")) {
                  Write-Log -Message -Message "Directory: $dirP" -Severity 2 -Source $deployAppScriptFriendlyName
                  Remove-Dir -dir $dir -dirMode $dirMode -localForce $localForce
                }
              }
            }
          } else { Remove-Dir -dir $dir -dirMode $dirMode -localForce $localForce }
        }
      } else { 
        If ($LastChar -eq "*") { 
          $BaseDir = ""
          $DirArr = $dir.Split("\")
          $ArrLeng = $DirArr.Length

          Write-Log -Message -Message "ArrLeng: $ArrLeng " -Severity 2 -Source $deployAppScriptFriendlyName

          For ($x = 0; $x -lt $ArrLeng - 1; $x++) {
              Write-Log -Message -Message "DirArr[$x]: $DirArr[$x] " -Severity 2 -Source $deployAppScriptFriendlyName
              If ($BaseDir -eq "") { $BaseDir = $DirArr[$x] }
              else { $BaseDir = $BaseDir + "\" + $DirArr[$x] }
          }

          $PartName = ($DirArr[$DirArr.Length - 1]).Trim("*")
          $Paths = Get-ChildItem $BaseDir | Where-Object {$_.Attributes -match'Directory'}

          If (!($Paths)) { Write-Log -Message "There is no folders match the criterium." 
          } else {
            Write-Log -Message -Message "PartName: $PartName " -Severity 2 -Source $deployAppScriptFriendlyName
            Write-Log -Message -Message "BaseDir: $BaseDir " -Severity 2 -Source $deployAppScriptFriendlyName
            Write-Log -Message -Message "Paths: $Paths " -Severity 2 -Source $deployAppScriptFriendlyName

            foreach($path in $Paths) {
              $dirP = $path.FullName
              If (($dirP -like "*$PartName*") -or ($dirP -like "*$PartName")) {
                Write-Log -Message -Message "Directory: $dirP" -Severity 2 -Source $deployAppScriptFriendlyName
                Remove-Dir -dir $dir -dirMode $dirMode -localForce $localForce
              }
            }
          }
        } else { Remove-Dir -dir $dir -dirMode $dirMode -localForce $localForce }
      }

      $x++
    }
  } elseif ($actionDate.action.ToUpper() -eq "COPY") {
    $x = 0
    foreach ($OldDir in $SrcDirs) {
      if ($SrcDirs.Length -eq $Dirs.Length) { $NewDir = $Dirs[$x] }
      else { $NewDir = $Directory }

      Write-Log -Message "Copy directory from: $OldDir to: $NewDir."

      if ($forAllUsers -eq $True) {
        ForEach ($User In (Get-WmiObject Win32_UserProfile -F "Special != True" | Select-Object -Expand LocalPath)) {
          Write-Log -Message "\User\NewDir - $($User)$NewDir"
          $UserDir = "$User$NewDir"
          Write-Log -Message "Xcopy /E /I /S /H /Y $OldDir $UserDir"
          Xcopy /E /I /S /H /Y $OldDir $UserDir
        }
      } else { 
        if(-Not (Test-Path -Path $NewDir)) { 
          Write-Log -Message "Xcopy /E /I /S /H /Y $OldDir $NewDir"
          Xcopy /E /I /S /H /Y $OldDir $NewDir 
        } elseif ($OldDir.Chars($OldDir.Length - 1) -eq "*" ) { 
          Write-Log -Message "Xcopy /E /I /S /H /Y $OldDir $NewDir"
          Xcopy /E /I /S /H /Y $OldDir $NewDir 
        } 
      }

      $x++
    }
  } elseif ($actionDate.action.ToUpper() -eq "MOVE") {
    $x = 0
    foreach ($OldDir in $SrcDirs) {
      if ($SrcDirs.Length -eq $Dirs.Length) { $NewDir = $Dirs[$x] }
      else { $NewDir = $Directory }

      Write-Log -Message "Copy directory from: $OldDir to: $NewDir."

      if ($forAllUsers -eq $True) {
        ForEach ($User In (Get-WmiObject Win32_UserProfile -F "Special != True" | Select-Object -Expand LocalPath)) {
          Write-Log -Message "\User\NewDir - $($User)$NewDir"
          $UserDir = "$User$NewDir"
          Write-Log -Message "Xcopy /E /I /S /H /Y $OldDir $UserDir"
          Xcopy /E /I /S /H /Y $OldDir $UserDir
          Remove-Dir -dir $OldDir
        }
      } else { 
        if(-Not (Test-Path -Path $NewDir)) { 
          Write-Log -Message "Xcopy /E /I /S /H /Y $OldDir $NewDir"
          Xcopy /E /I /S /H /Y $OldDir $NewDir 
        } elseif ($OldDir.Chars($OldDir.Length - 1) -eq "*" ) { 
          Write-Log -Message "Xcopy /E /I /S /H /Y $OldDir $NewDir"
          Xcopy /E /I /S /H /Y $OldDir $NewDir 
        } 
        Remove-Dir -dir $OldDir
      }

      $x++
    }
  } elseif ($actionDate.action.ToUpper() -eq "RENAME") {
    Write-Log -Message "Rename folder: $Directory to: $newName."

    if ((get-item $Directory).PSIsContainer) { $oldFolderName = Split-Path $Directory -Leaf } 
    else { $oldFolderName = Split-Path $Directory }

    $newName = $Directory.Replace($oldFolderName, $newName)

    if ($forAllUsers -eq $True) {
      ForEach ($User In (Get-WmiObject Win32_UserProfile -F "Special != True" | Select-Object -Expand LocalPath)) {
          Write-Log -Message "\User\Directory - $($User)$Directory"
          $newName = "$User$newName"
          $Directory = "$User$Directory"
          
          if ((-not (Test-Path $Directory -PathType Container)) -and (Test-Path $newName -PathType Container)) { Write-Log -Message "It seems that renaming was done, skipping action now." }
          else { Rename-Item "$Directory" "$newName" }
      }
    } else { 
      if ((-not (Test-Path $Directory -PathType Container)) -and (Test-Path $newName -PathType Container)) { Write-Log -Message "It seems that renaming was done, skipping action now." }
      else { Rename-Item "$Directory" "$newName" }
    }
  }
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function Remove-Dir {
  param(
      [Parameter(Mandatory = $True)]
      $dir,
      [Parameter(Mandatory = $False)]
      $dirMode = "recurse",
      [Parameter(Mandatory = $False)]
      $localForce = $True
  )

  if (Test-Path "$dir") {
    Write-Log -Message "Directory $dir exists."
    if (($localForce -eq $True) -or ($dirMode.ToLower() -eq "recurse")) { Get-ChildItem "$dir" -Recurse | Remove-Item -Recurse -Force }
    Remove-Item "$dir"
    Write-Log -Message "$dir removed."
  } Else { Write-Log -Message "Directory $dir doesn't exist." } 
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function Set-Script {
  param(
      [Parameter(Mandatory = $True)]
      $actionDate
  )
  
  Write-Log -Message "Starting: $($MyInvocation.MyCommand)/$($actionDate.appName)." -Source $deployAppScriptFriendlyName

    $scriptNames = Get-MultiData -SrcData $scriptName
    $scriptDir = Get-MultiData -SrcData $scriptDir
    $scriptParam = Get-MultiData -SrcData $scriptParam

  if (($scriptNames.Length -gt 0) -and ($scriptNames[0] -ne "") -and ($null -ne $scriptNames[0])) { 
    $x = 0

    foreach($script in $scriptNames) { 
      $script = Set-FullStringsFromVars -VarToCheck $script
      $scriptDirectory = Set-FullStringsFromVars -VarToCheck $scriptDir[$x]
      $scriptParameter = Set-FullStringsFromVars -VarToCheck $scriptParam[$x]

      Write-Log -Message "Trying to start: $scriptDirectory\$script $scriptParameter"

      if (($scriptDirectory -eq "") -or ([string]::IsNullOrEmpty($scriptDirectory))) { $scriptPath = "$SourcePath\$script" } 
      else { $scriptPath = "$scriptDirectory\$script" }
  
      Test-ParamFile -path "$scriptPath"

      if ($script.ToLower() -like "*.vbs") {
        if (($scriptParameter -eq "") -or ([string]::IsNullOrEmpty($scriptParameter))) { 
          Write-Log -Message "Command to run: $scriptPath"; 
          & wscript /nologo "$scriptPath" 
        } else { 
          Write-Log -Message "Command to run: $scriptPath $scriptParameter"; 
          & wscript /nologo "$scriptPath" "$scriptParameter" 
        } 
      } elseif ($script.ToLower() -like "*.cmd") { 
        if (($scriptParameter -eq "") -or ([string]::IsNullOrEmpty($scriptParameter))) { 
          Write-Log -Message "Command to run: $scriptPath"; 
          Start-Process "$scriptPath" 
        } else {
          Write-Log -Message "Command to run: $scriptPath $scriptParameter"; 
          Start-Process "$scriptPath" "$scriptParameter" 
        }
      } elseif ($script.ToLower() -like "*.ps1") { 
        if (($scriptParameter -eq "") -or ([string]::IsNullOrEmpty($scriptParameter))) { 
          Write-Log -Message "Command to run: $scriptPath"; 
          Invoke-Expression "& '$scriptPath'" 
        } else { 
          Write-Log -Message "Command to run: $scriptPath $scriptParameter"; 
          Invoke-Expression "& '$scriptPath'" "$scriptParameter" 
        }
      } else {
        Write-Log -Message "Script failed, file extension was not recognized in $($MyInvocation.MyCommand)" -Severity 3 -Source $deployAppScriptFriendlyName
        Exit-Script -ExitCode $Global:RCMissingParameter
      }

      $x++
    }
  } else {
    Write-Log -Message "Script failed, missing or bad scriptName parameter in $($MyInvocation.MyCommand)" -Severity 3 -Source $deployAppScriptFriendlyName
    Exit-Script -ExitCode $Global:RCMissingParameter
  }
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function Set-UnblockFiles {
  param(
      [Parameter(Mandatory = $True)]
      $actionDate
  )

  $DirPath = $actionDate.path
  $DirsPath = Get-MultiData -SrcData $DirPath

  if (($DirsPath.Length -gt 0) -and ($DirsPath[0] -ne "") -and ($null -ne $DirsPath[0])) { 
    $x = 0

    foreach($path in $DirsPath) { 
      $path = Set-FullStringsFromVars -VarToCheck $path
      try {
        Write-Log -Message "Set-UnblockFiles execution started."        
        Close-HandleToFolder -Folder $path 
        Write-Log -Message "Set-UnblockFiles execution finished."
      } catch { Write-Log -Message "Unlocking file failed."; exit 2 } 
    }
    $x++
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
