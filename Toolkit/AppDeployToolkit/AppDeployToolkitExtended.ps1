$Global:PSScriptRoot            = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$Global:ParentScriptRoot        = Split-Path $PSScriptRoot -Parent

$Global:SourcePath              = $ParentScriptRoot + "\Sources"
$Global:ConfigFilesPath         = $SourcePath + "\ConfigFiles"
$Global:PrerequisitesPath       = $SourcePath + "\Prerequisites"
$Global:Configs                 = $ParentScriptRoot + "\AppDeployToolkit\CustomStandards"
$Global:ProgramFiles64          = $env:ProgramFiles
$Global:ProgramFiles            = ${env:ProgramFiles(x86)}
$Global:windir                  = $env:windir
$Global:Temp                    = $env:Temp
$Global:PUBLIC                  = $env:PUBLIC
$Global:COMMONPROGRAMFILES64    = $env:COMMONPROGRAMFILES
$Global:ProgramData             = $env:ProgramData
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

  Write-Log -Message "Starting: $($MyInvocation.MyCommand)." -Source $deployAppScriptFriendlyName
  
  $RC = 0

  if (($yamlData -ne "") -and ($yamlData -ne " ") -and ($null -ne $yamlData) -and ($empty -ne $yamlData)) {
    $yamlData.keys | ForEach-Object {
      $name = $_
      $actionDate = $yamlData

      Write-Log -Message "Proceed with: $($name)." -Source $deployAppScriptFriendlyName

      if ($name -like "msi_*") { Set-MSI -actionDate $actionDate -name $name }                            #Basic tests: ok.
      if ($name -like "directory_*") { Set-Directory -actionDate $actionDate -name $name }                #Basic tests: ok.
      if ($name -like "script_*") { Set-Script -actionDate $actionDate -name $name }                      #Basic tests: ok.
      if ($name -like "sleep_*") { Set-Sleep -actionDate $actionDate -name $name }                        #Basic tests: ok.
      if ($name -like "archive_*") { Set-Archive -actionDate $actionDate -name $name }                    #Basic tests: ok. 
      if ($name -like "dll_*") { Set-DLL -actionDate $actionDate -name $name }                            #Basic tests: ok.
      if ($name -like "winfeature_*") { Set-WinFeature -actionDate $actionDate -name $name }              #Basic tests: ok.
      if ($name -like "appv_*") { Set-APPV -actionDate $actionDate -name $name }                          #Basic tests: ok.
      if ($name -like "msix_*") { Set-MSIX -actionDate $actionDate -name $name }                          #Basic tests: ok.
      if ($name -like "file_*") { Set-File -actionDate $actionDate -name $name }                          #Basic tests: ok. Need to add: move, add, edit, check.
      if ($name -like "exe_*") { Set-EXE -actionDate $actionDate -name $name }                            #to test, basic logic was done. Need to add version check.
      if ($name -like "service_*") { Set-Services -actionDate $actionDate -name $name }                   #to test, basic logic was done.
      if ($name -like "registry_*") { Set-Registry -actionDate $actionDate -name $name }                  #to test, basic logic was done.
      if ($name -like "process_*") { Set-Process -actionDate $actionDate -name $name }                    #to test, basic logic was done. Only kill addedd.
      if ($name -like "systemsettings_*") { Set-SysSettings -actionDate $actionDate -name $name }         #to test, basic logic was done. Need to change internal functions handling.
      if ($name -like "unblockfiles_*") { Set-UnblockFiles -actionDate $actionDate -name $name }          #to test, basic logic was done.
      if ($name -like "scheduledtask_*") { Set-ScheduledTask -actionDate $actionDate -name $name }        #to test, basic logic was done. Need to add: new, set.
      if ($name -like "detectionmethod_*") { Set-DetectionMethod -actionDate $actionDate -name $name }    #to test, basic logic was done.
      if ($name -like "pins_*") { Set-Pin -actionDate $actionDate -name $name }                           #to test, basic logic was done.
      if ($name -like "office_*") { Set-MSOffice -actionDate $actionDate -name $name }                    #to test, basic logic was done.
      if ($name -like "activesetup_*") { Set-ActiveSetups -actionDate $actionDate -name $name }           #to test, basic logic was done.
      if ($name -like "permissions_*") { Set-Permissions -actionDate $actionDate -name $name }            #to test, basic logic was done.
      if ($name -like "variable_*") { Set-VARs -actionDate $actionDate -name $name }                      #to test, basic logic was done.
      if ($name -like "shortcut_*") { Set-Shortcut -actionDate $actionDate -name $name }                  #started but need to be done from sratch.
      if ($name -like "if_*") { Set-ifStatement -actionDate $actionDate -name $name }                     #todo
      if ($name -like "appvCG_*") { Set-APPVCG -actionDate $actionDate -name $name }                      #todo
      if ($name -like "tag_*") { Set-TAG -actionDate $actionDate -name $name }                            #todo
      if ($name -like "window_*") { Set-Window -actionDate $actionDate -name $name }                      #todo
      if ($Name -like "getreg_") { $RC = Get-Registry -actionDate $actionDate -name $name }               #todo
      if ($Name -like "getmsiver_") { $RC = Get-MSIVersion -actionDate $actionDate -name $name }          #todo
    }
  } 

  Return $RC
  Write-Log -Message "Ending: $($MyInvocation.MyCommand)." -Source $deployAppScriptFriendlyName
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function Set-MSI {
  param(
    [Parameter(Mandatory = $True)]
    $actionDate,
    [Parameter(Mandatory = $True)]
    $name
  )

  <# 
  appName: "testApp"
  appVer: "1.0.0"
  msifile: "app.msi"
  mstFile: "app.mst"
  mspFile: "app.msp"
  GUID: "appFromReg"
  processName: "adf.vbs"
  params: "" #>

  #TODO:
  # - add  process checking durrin install and uninstall
  # - add version checking durring ADD if version prowided
  # - veryfity GUID as parameter for installation (needed or not?)

  Write-Log -Message "Starting: $($MyInvocation.MyCommand)/$($actionDate.$name.appName)." -Source $deployAppScriptFriendlyName

  $action = $actionDate.$name.action
  $appName = $actionDate.$name.appName
  $appVer = $actionDate.$name.appVer
  $msifile = $actionDate.$name.msifile
  $mstFile = $actionDate.$name.mstFile
  $mspFile = $actionDate.$name.mspFile
  $GUID = $actionDate.$name.GUID
  $processName = $actionDate.$name.processName
  $params = $actionDate.$name.params

  $tagLogName = $actionDate.$name.tagLogName

  $msifile = Set-FullStringsFromVars -VarToCheck $msifile
  $mstFile = Set-FullStringsFromVars -VarToCheck $mstFile
  $mspFile = Set-FullStringsFromVars -VarToCheck $mspFile

  $processName = Set-FullStringsFromVars -VarToCheck $processName
  $params = Set-FullStringsFromVars -VarToCheck $params

  if ($action.ToUpper() -eq "ADD") {
    $msifiles = Get-MultiData -SrcData $msifile -PreData $SourcePath
    $mstFiles = Get-MultiData -SrcData $mstFile -PreData $SourcePath
    $mspFiles = Get-MultiData -SrcData $mspFile -PreData $SourcePath	
    
    $allParams = Get-MultiData -SrcData $params -Delimeter "|"
    $appNames = Get-MultiData -SrcData $appName
    $tagLogNames = Get-MultiData -SrcData $tagLogName

    if (($msifiles.Length -gt 0) -and ($msifiles[0] -ne "") -and ($null -ne $msifiles[0])) { 
      $x = 0
      foreach($msi in $msifiles) { 
        $msi = Set-FileExtension -file $msi -extension ".msi"

        Test-ifParamFileExist -path $msi
        if ($msifiles.Length -eq $mstFile.Length) { 
          $mst = $mstFiles[$x]
          $mst = Set-FileExtension -file $mst -extension ".mst"
          Test-ifParamFileExist -path $mst
          $CurrentMSIGUID = Get-MsiTableProperty -Path "$msi" -TransformPath "$($mst)" -Table 'Property' | Select-Object -ExpandProperty 'ProductCode' 
        } else { $CurrentMSIGUID = Get-MsiTableProperty -Path "$msi" -Table 'Property' | Select-Object -ExpandProperty 'ProductCode' }
        
        $regGUID = Get-InstalledApplication -ProductCode $CurrentMSIGUID	
        
        if ($CurrentMSIGUID -eq $regGUID) {
          Write-Log -Message "Uninstalling $CurrentMSIGUID." -Source $deployAppScriptFriendlyName	
          Remove-MSIApplications -Name $CurrentMSIGUID #-LogNameV "$CurrentMSIGUID-uninstall"
        }

        #if ($msifiles.Length -eq $appNames.Length) { $logTagName = $appNames[$x] }
        #else { $logTagName = $CurrentMSIGUID }

        if ($msifiles.Length -eq $tagLogNames.Length) { $logTagName = $tagLogNames[$x] } #todo: use for log name 
  
        if ($msifiles.Length -eq $mstFile.Length) {
          $mst = $mstFiles[$x]
          $mst = Set-FileExtension -file $mst -extension ".mst"
          if ($msifiles.Length -eq $allParams.Length) { Execute-MSI -Action 'Install' "$msi" -Transform "$($mst)" <#-LogNameV "$logTagName" #>-AddParameters "$($allParams[$x])" }
          else { Execute-MSI -Action 'Install' "$msi" -Transform "$($mst)" <#-LogNameV "$logTagName"#> }
        } else { 
          if ($msifiles.Length -eq $allParams.Length) { Execute-MSI -Action 'Install' "$msi" <#-LogNameV "$logTagName" #>-AddParameters "$($allParams[$x])" }
          else { Execute-MSI -Action 'Install' "$msi" <#-LogNameV "$logTagName"#> }
        }
        
        if ($msifiles.Length -eq $mspFiles.Length) { 
          $msp = $mspFiles[$x]
          $msp = Set-FileExtension -file $msp -extension ".msp"
          Test-ifParamFileExist -path $msp
          Execute-MSP -Path "$($msp)" 
        }

        if ($GUIDs.Length -eq $tagLogNames.Length) { Set-Tags -actionDate "$logTagName" }
        $x++
      }
    } elseif (($mspFiles.Length -gt 0) -and ($mspFiles[0] -ne "") -and ($null -ne $mspFiles[0])) { 
      foreach($msp in $mspFiles) { 
        $msp = Set-FileExtension -file $msp -extension ".msp"
        Test-ifParamFileExist -path $msp
        Execute-MSP -Path "$msp" 
      }
    }
 
  } elseif ($action.ToUpper() -eq "REMOVE") {
    $GUIDs = Get-MultiData -SrcData $GUID
    $appsVer = Get-MultiData -SrcData $appVer

    $allParams = Get-MultiData -SrcData $params -Delimeter "|"
    $appNames = Get-MultiData -SrcData $appName
    $tagLogNames = Get-MultiData -SrcData $tagLogName

    if (($GUIDs.Length -gt 0) -and ($GUIDs[0] -ne "") -and ($null -ne $GUIDs[0])) { 
      $x = 0
      
      foreach($app in $GUIDs) { 
        if ($msifiles.Length -eq $tagLogNames.Length) { $logTagName = $tagLogNames[$x] } #todo: use for log name 

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
              else { Remove-MSIApplications -Name $app <#-LogNameV $appNames[$x] #>-AddParameters "$($allParams[$x])" }
            } else { 
              if ($GUIDs.Length -eq $appsVer.Length) { Remove-MSIApplications -Name $app -LogNameV $appNames[$x] -FilterApplication ('DisplayVersion', $appsVer[$x], 'Exact') }
              else { Remove-MSIApplications -Name $app <#-LogNameV $appNames[$x]#> }
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

        if ($GUIDs.Length -eq $tagLogNames.Length) { Set-Tags -actionDate $tagLogNames[$x] }
        $x++
      }
    }
  } else {
    Write-Log -Message "Script failed, missing or bad ACTION parameter in $($MyInvocation.MyCommand)/$($actionDate.$name.appName)" -Severity 3 -Source $deployAppScriptFriendlyName
    Exit-Script -ExitCode $Global:RCMissingParameter
  }

  Write-Log -Message "Ending: $($MyInvocation.MyCommand)." -Source $deployAppScriptFriendlyName
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function Set-DLL {
  param(
    [Parameter(Mandatory = $True)]
    $actionDate,
    [Parameter(Mandatory = $True)]
    $name
  )

  Write-Log -Message "Starting: $($MyInvocation.MyCommand)." -Source $deployAppScriptFriendlyName

  $action = $actionDate.$name.action
  $DllFile = $actionDate.$name.dllFile
  $DllPath = $actionDate.$name.dllPath
  $x = 0


  if (!(Test-forVariable -varName $DllFile)) {
    $DllPaths = Get-MultiData -SrcData $DllPath
    $DllFiles = Get-MultiData -SrcData $DllFile
    $rootDllPath = ""

    #if (($DllPaths.Length -eq 1) -and ($DllPaths[0] -ne '') -and (-not ([string]::IsNullOrEmpty($DllPaths[0])))) { $rootDllPath = $DllPaths[0] }
    
    foreach ($dll in $DllFiles) {
      if (Test-forVariable -varName $DllPath) { $rootDllPath = $SourcePath }
      elseif ((Test-forArrays -arr1 $DllPaths -arr2 $DllFiles) -eq $True) { $rootDllPath = $DllPaths[$x] }
      else { $rootDllPath = $DllPath }

      $rootDllPath = Set-FullStringsFromVars -VarToCheck $rootDllPath
      $rootDllPath = Set-RelativePath -path $rootDllPath
      $DllFile = Set-FileExtension -file $DllFile -extension ".dll"

      if ($rootDllPath -ne "") { $dllFullPath = "$rootDllPath\$DllFile" }
      elseif (($DllPaths[$x] -ne '') -and (-not ([string]::IsNullOrEmpty($DllPaths[$x])))) { $dllFullPath = "$($DllPaths[$x])\$DllFile" }
      Else { $dllFullPath = "$SourcePath\$DllFile" }

      if ($action.ToUpper() -eq "REMOVE") { 
        Test-ifParamFileExist -path $dllFullPath
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
      } Elseif ($action.ToUpper() -eq "ADD") { 
        Test-ifParamFileExist -path $dllFullPath
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
      $x++
    }
  } else {
    Write-Log -Message "Script failed, missing DllFile parameter in $($MyInvocation.MyCommand)" -Severity 3 -Source $deployAppScriptFriendlyName
    Exit-Script -ExitCode $Global:RCMissingParameter
  }  

  Write-Log -Message "Ending: $($MyInvocation.MyCommand)." -Source $deployAppScriptFriendlyName
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function Set-Archive {
  param(
    [Parameter(Mandatory = $True)]
    $actionDate,
    [Parameter(Mandatory = $True)]
    $name
  )

  Write-Log -Message "Starting: $($MyInvocation.MyCommand)." -Source $deployAppScriptFriendlyName

  $7zipDatasA = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName -like "7-Zip*" }
  $7zipDatasB = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName -like "7-Zip*" }

  if (-not(Test-forVariable -varName $7zipDatasA)) { $7zipInstDir = $7zipDatasA.InstallLocation }
  elseif (-not(Test-forVariable -varName $7zipDatasB)) { $7zipInstDir = $7zipDatasB.InstallLocation }
  else { $7zipInstDir = "null" }

  $drives = (Get-PSDrive -PSProvider FileSystem).Root
  foreach ($drive in $drives) { $discSpace = Get-DiscSpace -drive $drive }
  
  Write-Log -Message "Current disc space: $discSpace" -Source $deployAppScriptFriendlyName

  $action = $actionDate.$name.action
  $DirPath = $actionDate.$name.path
  $ArchName = $actionDate.$name.archName
  $TargetDir = $actionDate.$name.targetPath
  $ArchType = $actionDate.$name.type

  $DirsPath = Get-MultiData -SrcData $DirPath
  $ArchsName = Get-MultiData -SrcData $ArchName

  $x = 0

  if (!(Test-forVariable -varName $ArchName)) {
    if ($ArchType -eq "7Z") { 
      if ($7zipInstDir -eq "null") { 
        Write-Log -Message "Script failed, missing 7zip prerequisite." -Severity 3 -Source $deployAppScriptFriendlyName
        Exit-Script -ExitCode -100 
      }
    }

    if ($action.ToUpper() -eq "ADD") {
      foreach ($dir in $DirsPath) {
        if ((Test-forArrays -arr1 $DirsPath -arr2 $ArchsName) -eq $True) { $zipName = $ArchsName[$x] }
        else { $zipName = "$ArchName" }

        Set-NewDirectory -path $dir
        $dir = Set-TrimLastChar -string $dir

        if ($ArchType -eq "7Z") {
          Test-ifParamFileExist -path "$7zipInstDir\7z.exe"
          Write-Log -Message "$7zipInstDir\7z.exe a $zipName.7z $TargetDir." -Source $deployAppScriptFriendlyName
          & "$7zipInstDir\7z.exe" a "$zipName.7z" "$TargetDir"  
        } elseif ($ArchType -eq "ZIP") { 
          Add-Type -AssemblyName System.IO.Compression.FileSystem
          Write-Log -Message "[System.IO.Compression.ZipFile]::CreateFromDirectory($TargetDir,$dir\$zipName.zip)" -Source $deployAppScriptFriendlyName
          [System.IO.Compression.ZipFile]::CreateFromDirectory("$TargetDir" ,"$dir\$zipName.zip")
        } elseif ($ArchType -eq "PSZIP") { 
          Write-Log -Message "New-ZipFile -DestinationArchiveDirectoryPath $dir -DestinationArchiveFileName $zipName.zip -SourceDirectory $TargetDir -OverWriteArchive $True" -Source $deployAppScriptFriendlyName
          New-ZipFile -DestinationArchiveDirectoryPath "$dir" -DestinationArchiveFileName "$zipName.zip" -SourceDirectory "$TargetDir" -OverWriteArchive $True 
        }
        $x++
      }
    } elseif ($action.ToUpper() -eq "UNPACK") {
      $TargetDir = Set-FullStringsFromVars -VarToCheck $TargetDir

      foreach ($dir in $DirsPath) {
        if ((Test-forArrays -arr1 $DirsPath -arr2 $ArchsName) -eq $True) {
          if (Test-forVariable -varName $dir) { $Directory = $SourcePath  } 
          else { $Directory = Set-FullStringsFromVars -VarToCheck $dir }
          $archFullPath = "$Directory\$($ArchsName[$x])"
          $TargetDir = "$TargetDir\$($ArchsName[$x])"
        } else { 
          $Directory = $dir 
          $archFullPath = "$Directory\$ArchName"
          $TargetDir = "$TargetDir\$ArchName"
        }
        
        if ($ArchType -eq "7Z") { 
          Test-ifParamFileExist -path "$archFullPath.7z"
          Write-Log -Message "ExtractToDirectory($archFullPath.7z, $TargetDir)"
          Test-ifParamFileExist -path "$7zipInstDir\7z.exe"
          & "$7zipInstDir\7z.exe" x "$archFullPath.7z" -o"$TargetDir" -y  
        } elseif ($ArchType -eq "ZIP") { 
          Test-ifParamFileExist -path "$archFullPath.zip"
          Write-Log -Message "ExtractToDirectory($archFullPath.zip, $TargetDir)"
          Add-Type -AssemblyName System.IO.Compression.FileSystem
          [System.IO.Compression.ZipFile]::ExtractToDirectory("$archFullPath.zip" ,"$TargetDir")
        } elseif ($ArchType -eq "PSZIP") { 
          Test-ifParamFileExist -path "$archFullPath.zip"
          Write-Log -Message "ExtractToDirectory($archFullPath.zip, $TargetDir)"
          Expand-Archive -LiteralPath $archFullPath -DestinationPath "$TargetDir" -Force 
        }
        $x++
      }
    }  
  } else {
    Write-Log -Message "Script failed, missing ArchName parameter in $($MyInvocation.MyCommand)" -Severity 3 -Source $deployAppScriptFriendlyName
    Exit-Script -ExitCode $Global:RCMissingParameter
  }
  
  Write-Log -Message "Ending: $($MyInvocation.MyCommand)." -Source $deployAppScriptFriendlyName
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function Set-Services {
  param(
    [Parameter(Mandatory = $True)]
    $actionDate,
    [Parameter(Mandatory = $True)]
    $name
  )

  $action = $actionDate.$name.action
  
  $ServiceName = $actionDate.$name.serviceName
  $ServiceNames = Get-MultiData -SrcData $ServiceName

  $ServiceBinary = $actionDate.$name.serviceBinary
  $ServiceBinarys = Get-MultiData -SrcData $ServiceBinary
  $StartupType = $actionDate.$name.startupType
  $StartupTypes = Get-MultiData -SrcData $StartupType
  $DependsOn = $actionDate.$name.dependsOn
  $ListDependsOn = Get-MultiData -SrcData $DependsOn

  Write-Log -Message "Starting: $($MyInvocation.MyCommand)." -Source $deployAppScriptFriendlyName 

  $x = 0

  foreach ($service in $ServiceNames) {
    if($action.ToUpper() -eq "ADD") { 
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
      } 
    New-Service @params 
    } elseif ($action.ToUpper() -eq "STOP") { if (Get-Service $service -ErrorAction SilentlyContinue) { Get-Service -Name $service | Set-Service -Status Stopped -PassThru -Force }
    } elseif ($action.ToUpper() -eq "REMOVE") {
        if (Get-Service -Name $service -ErrorAction SilentlyContinue) {
          Write-Log -Message "Removing: $service."
          Stop-Service $service
          Get-CimInstance -ClassName Win32_Service -Filter "Name=$service" | Remove-CimInstance
        } else { Write-Log -Message "$service is not present, nothink to remove. Going to next step." }
    } elseif ($action.ToUpper() -eq "START") { if (Get-Service $service -ErrorAction SilentlyContinue) { Get-Service -Name $service | Set-Service  -Status Running -PassThru }
    } elseif ($action.ToUpper() -eq "PAUSE") { if (Get-Service $service -ErrorAction SilentlyContinue) {Get-Service -Name $service | Set-Service -Status Paused }
    } elseif ($action.ToUpper() -eq "DISABLE") { if (Get-Service $service -ErrorAction SilentlyContinue) {Get-Service -Name $service | Set-Service -StartupType Disabled -PassThru }}
    $x++
  }
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function Set-Process {
  param(
    [Parameter(Mandatory = $True)]
    $actionDate,
    [Parameter(Mandatory = $True)]
    $name
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

  $action = $actionDate.$name.action

  $ProcessName = $actionDate.$name.processName
  $ProcessesNames = Get-MultiData -SrcData $ProcessName

  $x = 0

  foreach ($proces in $ProcessesNames) {
    if ($action.ToUpper() -eq "STOP") {

    } elseif ($action.ToUpper() -eq "KILL") {
      $ProcName = $proces.ToLower()
      $ProcName = $ProcName.Replace(".exe","")
      $KillProc = [System.Collections.ArrayList]@()

      Write-Log -Message "ProcName fo handle: $ProcName "
      Write-Log -Message "stop-process -name $ProcName -force"
      
      Get-Process -Name $ProcName | Stop-Process -Force

      if ($Action.Length -eq 2) {  
        if (!(Test-forVariable -varName $ProcName)) {
          foreach ($ProcName in $Process) { Write-Log -Message "Adding: $ProcName to process list."; $KillProc.Add($ProcName) }
          if ($Action[1] -eq "block") { Block-AppExecution -ProcessName ($KillProc) } 
          elseif ($Action[1] -eq "unblock") { Unblock-AppExecution }
        }
      } elseif ($Action.Length -eq 3) {
        if (($Action[0] -eq "kill") -and ($Action[1] -eq "null")) {
          Write-Log -Message "stop-process -name $ProcName -force"
          stop-process -name $ProcName -force -ErrorAction SilentlyContinue
        } else {
          $cmdToKill = $Action[2]            
          Write-Log -Message "Set-Processes cmdToKill - $cmdToKill"
          if (!(Test-forVariable -varName $cmdToKill)) {
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
    } elseif ($action.ToUpper() -eq "START") {  }
    $x++
  }  
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function Set-SysSettings {
  param(
    [Parameter(Mandatory = $True)]
    $actionDate,
    [Parameter(Mandatory = $True)]
    $name
  )

  $action = $actionDate.$name.action

  $mainValue = $actionDate.$name.mainValue
  $mainValues = Get-MultiData -SrcData $mainValue

  if ($action.ToUpper() -eq "CULTURE") {
    foreach ($value in $mainValues) {
      Write-Log -Message "Set new value for Culture: $value"
      Set-Culture -CultureInfo $value
    }
  } elseif ($action.ToUpper() -eq "NETUSE") {
    foreach ($value in $mainValues) {
      Write-Log -Message "Set new value for NET USE: $value"
      NET USE $value
    }
  } elseif ($action.ToUpper() -eq "REBOOT") {
    Write-Log -Message "Set shutdown /f /r /t $mainValue"
    shutdown /f /r /t $mainValue
  } elseif ($action.ToUpper() -eq "CHROMEUPDATES") {
    Write-Log -Message "Disabling Google Chrome Updates"
    
    $data = @{
              "action" = "KILL" 
              "processName" = "googleupdate.exe"
            }
    Set-Processes -actionDate $data

    $arrA = @("STOP","REMOVE","STOP","REMOVE")
    $arrB = @("gupdate","gupdate","gupdatem","gupdatem")

    $x = 0
    foreach($action in $arrA) {
      $name = $arrB[$x]
      $data = @{
        "action" = "$action" 
        "serviceName" = "$name"
      }
      Set-Services -actionDate $data

      $x++
    }

    $task1 = "GoogleUpdateTaskMachineCore=null=null=null"
    $arr = $task1.Split("=")
    Set-ScheduledTask -ActionName "REMOVE" -Data $arr
    $task2 = "GoogleUpdateTaskMachineUA=null=null=null"
    $arr = $task2.Split("=")
    Set-ScheduledTask -ActionName "REMOVE" -Data $arr 

    $ufile = "C:\Program Files (x86)\Google\Update"
    $arr = $ufile.Split("=")
    Set-UnblockFiles -actionName "ADD" -Data $arr  
        
    $dir = "C:\Program Files (x86)\Google\Update=C:\Program Files (x86)\Google\Update1"
    $arr = $dir.Split("=")
    Set-DirAction -actionName "RENAME" -Data $arr 
  }
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function Set-EXE {
  param(
    [Parameter(Mandatory = $True)]
    $actionDate,
    [Parameter(Mandatory = $True)]
    $name
  )

  $action = $actionDate.$name.action

  $EXEFile = $actionDate.$name.exeFile
  $EXEFile = Set-FullStringsFromVars -VarToCheck $EXEFile
  $EXEFiles = Get-MultiData -SrcData $EXEFile
  $CMDParams = $actionDate.$name.params
  $CMDParams = Set-FullStringsFromVars -VarToCheck $CMDParams
  $CMDParameters = Get-MultiData -SrcData $CMDParams

  $PKGName = $actionDate.$name.appName
  $PKGNames = Get-MultiData -SrcData $PKGName
  $appVer = $actionDate.$name.appVer
  $appVers = Get-MultiData -SrcData $appVer
  $EXEGUID = $actionDate.$name.GUID
  $EXEGUIDs = Get-MultiData -SrcData $EXEGUID

  $RC = $actionDate.$name.rc
  $x = 0

  foreach ($exe in $EXEFiles) {
    if ($EXEFiles.Length -eq $CMDParameters.Length) { $CMDParam = $CMDParameters[$x] } else { $CMDParam = "" }
    if ($EXEFiles.Length -eq $EXEGUIDs.Length) { $GUID = $EXEGUIDs[$x] } else { $GUID = " " }
    if ($EXEFiles.Length -eq $PKGNames.Length) { $TAG = $PKGNames[$x] } else { $TAG = " " }

    Write-Log -Message "Will run $exe with $CMDParam."

    if (($exe -like "\*") -or (((-not ($exe -like "*:\*")) -and (-not ($exe -like "*%*"))))) { $exe = "$SourcePath\$exe"}     
    if (!(Test-forVariable -varName $RC)) { $SuccessCode = "$SuccessCode,$RC" }

    if ($GUID -ne ' ') { $isInstalled = (Get-InstalledApplication -ProductCode $GUID).DisplayName }
    else { $isInstalled = " " }

    if ($action.ToUpper() -eq "ADD") { $action = "ADD" } else { $action = "REMOVE" }
    if (Test-forVariable -varName $isInstalled) { $isInstalled = $false } else { $isInstalled = $true }
      
    if ((($isInstalled -eq $false) -and ($action -eq "ADD")) -or (($isInstalled -eq $true) -and ($action -eq "REMOVE"))) { 
      $exe = "$exe" 
      Test-ifParamFileExist -path $exe
      Write-Log -Message "Execute-Process -Path $exe -Parameters $CMDParam"
      Execute-Process -Path $exe -Parameters $CMDParam -WindowStyle 'Hidden' -IgnoreExitCodes $SuccessCode 
      if (Test-forVariable -varName $TAG) { Set-Tags -actionDate "$TAG" }
    } else { 
      if ($action -eq "ADD") { Write-Log -Message "GUID present, application already installed. Going to next step." }
      if ($action -eq "REMOVE") { Write-Log -Message "GUID not present, nothing to uninstall. Going to next step." }
    }
    
    $x++
  }
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function Set-WinFeature {
  param(
    [Parameter(Mandatory = $True)]
    $actionDate,
    [Parameter(Mandatory = $True)]
    $name
  )

  $action = $actionDate.$name.action

  $FeatureName = $actionDate.$name.featureName

  if (!(Test-forVariable -varName $FeatureName)) {
    $FeatureNames = Get-MultiData -SrcData $FeatureName

    foreach ($feature in $FeatureNames) {
      if ($action.ToUpper() -eq "ADD") {
        Write-Log -Message "Enable-WindowsOptionalFeature -Online -FeatureName $feature -norestart -All"
        Enable-WindowsOptionalFeature -Online -FeatureName $feature -norestart -all
      } Elseif ($action.ToUpper() -eq "REMOVE") {   
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
    $actionDate,
    [Parameter(Mandatory = $True)]
    $name
  )

  Write-Log -Message "Starting: $($MyInvocation.MyCommand)/$($actionDate.$name.time)." -Source $deployAppScriptFriendlyName

  $Time = $actionDate.$name.time

  Write-Log -Message "Starts sleep for $Time."

  if (($Time -like "*s") -or ($Time -like "*S")) {
    $Time = $Time.Replace("s","")
    $Time = $Time.Replace("S","")
    Start-Sleep -Seconds $Time 
  } else { Start-Sleep -Milliseconds $Time } 

  Write-Log -Message "Ending: $($MyInvocation.MyCommand)." -Source $deployAppScriptFriendlyName
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function Set-Registry {
  param(
    [Parameter(Mandatory = $True)]
    $actionDate,
    [Parameter(Mandatory = $True)]
    $name
  )

  $action = $actionDate.$name.action

  $Key = $actionDate.$name.key
  $Key = Set-FullStringsFromVars -VarToCheck $Key
  $Keys = Get-MultiData -SrcData $Key

  $Name = $actionDate.$name.name
  $Type = $actionDate.$name.type
  $Value = $actionDate.$name.value

  if ($Key.ToUpper() -like "*.REG") {
    if ($action.ToUpper() -eq "ADD") {
      foreach ($reg in $Keys) {
        $keyPath = Set-RelativePath -path $reg
        Test-ifParamFileExist -path $keyPath

        $startprocessParams = @{
            FilePath     = "$Env:SystemRoot\REGEDIT.exe"
            ArgumentList = '/s', $keyPath
            Verb         = 'RunAs'
            PassThru     = $true
            Wait         = $true
        }

        $proc = Start-Process @startprocessParams
        
        if ($proc.ExitCode -eq 0) { 'Success!' }
        else { "Fail! Exit code: $($Proc.ExitCode)" }
      }
    } else { 
      Write-Log -Message "Script failed, action type missmatch $($MyInvocation.MyCommand)" -Severity 3 -Source $deployAppScriptFriendlyName
      Exit-Script -ExitCode $Global:RCMissingParameter
    }
  } else { 
    if ($Keys.Lengts -gt 1) {
      Write-Log -Message "Script failed, to many key for ADD, CHANGE actions, please split them for different actions in $($MyInvocation.MyCommand)" -Severity 3 -Source $deployAppScriptFriendlyName
      Exit-Script -ExitCode $Global:RCMissingParameter 
    } else {
      $Key = Convert-RegistryPath -Key $Key
      Write-Log -Message "Set-Registry will proceed with: $Key."

      if (($action.ToUpper() -eq "ADD") -or ((Test-Path -Path $Key) -and ($action.ToUpper() -eq "CHANGE"))) {
        if (($Key -like "Registry::HKCU*") -or ($Key -like "Registry::HKEY_CURRENT_USER*") -or ($Key -like "Registry::HKEY_USERS*") -or ($Key -like "Registry::HKU*")) {
          Write-Log -Message "Will edit users registry."

          $Key = $Key.Replace("Registry::HKCU\","")
          $Key = $Key.Replace("Registry::HKEY_CURRENT_USER\","")
          $Key = $Key.Replace("Registry::HKEY_USERS\","")
          $Key = $Key.Replace("Registry::HKU\","")

          Write-Log -Message "Reg Path = $Key."

          Set-RegistryValueForAllUnloadedUsers -Name $Name -Type $Type -Value $Value -Path $Key -Action $Action
        } else {
          if (($Name -eq "null") -and ($Name -eq "null") -and ($Name -eq "null")) { Set-RegistryKey -Key $Key } #TODO check issues when path do not exist, check paths translations
          else {
            Set-RegistryKey -Key $Key
            if (-not (Test-RegValExists($Key, $Name))) {
              if (($Key -ne "null") -and ($Name -ne "null") -and ($Type -ne "null") -and ($Value -ne "null")) { Set-RegistryKey -Key $Key -Name $Name -Type $Type -Value $Value } 
              Elseif (($Key -ne "null") -and ($Name -ne "null") -and ($Value -ne "null")) { Set-RegistryKey -Key $Key -Name $Name -Value $Value } 
              Elseif (($Key -ne "null") -and ($Value -ne "null")) { Set-RegistryKey -Key $Key -Value $Value }
            } Else {
              Write-Log -Message "Registry key $key\$name exists. Removing the key."
              Remove-RegistryKey -Key $Key -Name $Name
              
              if (($Key -ne "null") -and ($Name -ne "null") -and ($Type -ne "null") -and ($Value -ne "null")) { Set-RegistryKey -Key $Key -Name $Name -Type $Type -Value $Value } 
              Elseif (($Key -ne "null") -and ($Name -ne "null") -and ($Value -ne "null")) { Set-RegistryKey -Key $Key -Name $Name -Value $Value } 
              Elseif (($Key -ne "null") -and ($Value -ne "null")) { Set-RegistryKey -Key $Key -Value $Value }            
            }
          }
        }
      } 
    } elseif ($action.ToUpper() -eq "REMOVE") {
      foreach ($reg in $Keys) {
        if (($reg -like "Registry::HKCU*") -or ($reg -like "Registry::HKEY_CURRENT_USER*") -or ($reg -like "Registry::HKEY_USERS*") -or ($reg -like "Registry::HKU*")) {
          Write-Log -Message "Will edit users registry."

          $reg = $reg.Replace("Registry::HKCU\","")
          $reg = $reg.Replace("Registry::HKEY_CURRENT_USER\","")
          $reg = $reg.Replace("Registry::HKEY_USERS\","")
          $reg = $reg.Replace("Registry::HKU\","")

          Write-Log -Message "Reg Path = $reg."

          Set-RegistryValueForAllUnloadedUsers -Name $Name -Type $Type -Value $Value -Path $reg -Action $Action
        } else {
          if (($reg -ne "null") -and ($Name -ne "null")) { Remove-RegistryKey -Key $reg -Name $Name } 
          else { Remove-RegistryKey -Key $reg } 
        }
      }
    } 
  }
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function Set-ScheduledTask {
  param(
    [Parameter(Mandatory = $True)]
    $actionDate,
    [Parameter(Mandatory = $True)]
    $name
  )

  $action = $actionDate.$name.action

  $TaskName = $actionDate.$name.taskName
  $TasksNames = Get-MultiData -SrcData $TaskName
    
  if ($action.ToUpper() -eq "NEW") { }
  elseif ($action.ToUpper() -eq "SET") { }
  elseif ($action.ToUpper() -eq "REMOVE") {
    foreach ($task in $TasksNames) {
      if(Get-ScheduledTask $task -ErrorAction Ignore) { 
        Write-Log -Message "Removing Scheduled Task: $task."
        Unregister-ScheduledTask -TaskName $task -Confirm:$false
      } else { Write-Log -Message "$task is not present, nothink to remove. Going to next step." }
    }
  }
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function Set-DUMMYFunction {
  param(
    [Parameter(Mandatory = $True)]
    $actionDate,
    [Parameter(Mandatory = $True)]
    $name
  )

  $action = $actionDate.$name.action

  if ($action.ToUpper() -eq "ADD") {
  } elseif ($action.ToUpper() -eq "REMOVE") {
  } elseif ($action.ToUpper() -eq "COPY") {
  } elseif ($action.ToUpper() -eq "MOVE") {
  } elseif ($action.ToUpper() -eq "EDIT") {
  }
  
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function Set-Pin { 
  param(
    [Parameter(Mandatory = $True)]
    $actionDate,
    [Parameter(Mandatory = $True)]
    $name
  )

  $action = $actionDate.$name.action

  $FilePath = $actionDate.$name.filePath
  $FilePaths = Get-MultiData -SrcData $FilePath

  $LnkType = $actionDate.$name.lnkType
  $LnkTypes = Get-MultiData -SrcData $LnkType

  $forAllUsers = $False
  $x = 0

  foreach ($file in $FilePaths) {
  
    if ($FilePaths.Length -eq $LnkTypes.Length) { $type = $LnkTypes[$x] }
    else { $type = $LnkType }

    if (($file -like "*%allusers%*") -or ($file -like "%allusers%*")) { $forAllUsers = $True }
    $file = Set-FullStringsFromVars -VarToCheck $file

    Write-Log -Message "Starting setting pinned item acctions ."

    if ($forAllUsers) {
      ForEach ($User In (Get-WmiObject Win32_UserProfile -F "Special != True" | Select-Object -Expand LocalPath)) {
        $file = $file.Replace("%allusers%\","")
        $file = "$($User)$file"
              
        Write-Log -Message "FilePath - $file "

        if ($action.ToUpper() -eq "ADD") {
          if ($type.ToUpper() -eq "TASKBAR") { Set-PinnedApplication -Action "PintoTaskbar" -FilePath $FilePath }
          elseif ($type.ToUpper() -eq "STARTMENU") { Set-PinnedApplication -Action "PintoStartMenu" -FilePath $FilePath }
          else {}
        }
        if ($action.ToUpper() -eq "REMOVE") { 
          if ($type.ToUpper() -eq "TASKBAR") { Set-PinnedApplication -Action "UnpinfromTaskbar" -FilePath $FilePath }
          elseif ($type.ToUpper() -eq "STARTMENU") { Set-PinnedApplication -Action "UnpinfromStartMenu" -FilePath $FilePath }
          else {}
        }  
      }
    } else {
      if ($action.ToUpper() -eq "ADD") {
        if ($type.ToUpper() -eq "TASKBAR") { Set-PinnedApplication -Action "PintoTaskbar" -FilePath $FilePath }
        elseif ($type.ToUpper() -eq "STARTMENU") { Set-PinnedApplication -Action "PintoStartMenu" -FilePath $FilePath }
        else {}
      }
      if ($action.ToUpper() -eq "REMOVE") { 
        if ($type.ToUpper() -eq "TASKBAR") { Set-PinnedApplication -Action "UnpinfromTaskbar" -FilePath $FilePath }
        elseif ($type.ToUpper() -eq "STARTMENU") { Set-PinnedApplication -Action "UnpinfromStartMenu" -FilePath $FilePath }
        else {}
      }  
    }
    $x++
  }
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function Set-Shortcut {
  param(
    [Parameter(Mandatory = $True)]
    $actionDate,
    [Parameter(Mandatory = $True)]
    $name
  )

  $action = $actionDate.$name.action

  if ($action.ToUpper() -eq "ADD") {
  } elseif ($action.ToUpper() -eq "REMOVE") {
  } elseif ($action.ToUpper() -eq "EDIT") {
  }

  <#

  $LnkName = $Data[0]
  $LnkPath = $Data[1]
  $PropertyName = $Data[2]
  $PropertyValue = $Data[3]
 
  $fileName = $LnkName
  $folder = $LnkPath
  [string]$from = "\\uncpath1\shares\" 
  [string]$to = $PropertyValue

  $list = Get-ChildItem -Path $folder -Filter $fileName -Recurse | Where-Object { $_.Attributes -ne "Directory" } | Select-Object -ExpandProperty FullName 
  $obj = New-Object -ComObject WScript.Shell 
    
  ForEach($lnk in $list) { 
    $obj = New-Object -ComObject WScript.Shell 
    $link = $obj.CreateShortcut($lnk) 

    [string]$tmp = $link.TargetPath  
    [string]$tmp = [string]$tmp.Replace($from.tostring(),$to.ToString()) 
        
    #if you need workingdirectory change please uncomment the below line.
    #$link.WorkingDirectory = [string]$WorkingDirectory.Replace($from.tostring(),$to.ToString()) 
    #$link.Arguments = "-arguments" 

    $link.TargetPath = [string]$tmp 
    $link.Save() 
  }  #>

}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function Set-Directory {
  param(
    [Parameter(Mandatory = $True)]
    $actionDate,
    [Parameter(Mandatory = $True)]
    $name
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
    
  Write-Log -Message "Starting: $($MyInvocation.MyCommand)/$($actionDate.$name.targetDir)." -Source $deployAppScriptFriendlyName

  $action = $actionDate.$name.action

  $Directory = $actionDate.$name.targetDir
  $SrcDirectory = $actionDate.$name.sourceDir

  $forAllUsers = $False
  if (($Directory -like "*%allusers%*") -or ($Directory -like "%allusers%*")) { $forAllUsers = $True }
  if (($SrcDirectory -like "*%allusers%*") -or ($SrcDirectory -like "%allusers%*")) { $forAllUsers = $True }

  $Directory = Set-FullStringsFromVars -VarToCheck $Directory
  $Dirs = Get-MultiData -SrcData $Directory

  $SrcDirectory = Set-FullStringsFromVars -VarToCheck $SrcDirectory
  $SrcDirs = Get-MultiData -SrcData $SrcDirectory

  $newName = $actionDate.$name.newName

  $isForce = $actionDate.$name.force
  if (!(Test-forVariable -varName $isForce)) { $isAllForce = Get-MultiData -SrcData $isForce }

  $mode = $actionDate.$name.mode
  if (!(Test-forVariable -varName $mode)) { $allModes = Get-MultiData -SrcData $mode }

  if ($action.ToUpper() -eq "ADD") {
    $x = 0
    foreach ($dir in $Dirs) {
      if ($isAllForce.Length -eq $Dirs.Length) { $localForce = $isAllForce[$x] }
      elseif (!(Test-forVariable -varName $isForce)) { $localForce = $isForce }
      else { $localForce = $true }

      if ($forAllUsers -eq $True) {
        ForEach ($User In (Get-WmiObject Win32_UserProfile -F "Special != True" | Select-Object -Expand LocalPath)) {
          Write-Log -Message "\User\dir - $($User)$dir"
          $dirU = "$User$dir"
          Set-NewDirectory -path $dirU -force $localForce
        }
      } else { Set-NewDirectory -path $dir -force $localForce }
      $x++
    }
  } elseif ($action.ToUpper() -eq "REMOVE") {
    $x = 0
    foreach ($dir in $Dirs) {
      if ($allModes.Length -eq $Dirs.Length) { $dirMode = $allModes[$x] }
      elseif (!(Test-forVariable -varName $allModes)) { $dirMode = $mode }
      else { $dirMode = "" }

      if ($isAllForce.Length -eq $Dirs.Length) { $localForce = $isAllForce[$x] }
      elseif (Test-forVariable -varName $isForce) { $localForce = $isForce }
      else { $localForce = $true }

      $LastChar = $Directory.Substring($dir.get_Length()-1)

      if ($forAllUsers -eq $True) {
        ForEach ($User In (Get-WmiObject Win32_UserProfile -F "Special != True" | Select-Object -Expand LocalPath)) {
          Write-Log -Message "\User\dir - $($User)$dir"
          $dirU = "$User$dir"

          if ($LastChar -eq "*") {
            $BaseDir = ""
            $DirArr = $dirU.Split("\")
            $ArrLeng = $DirArr.Length

            Write-Log -Message -Message "ArrLeng: $ArrLeng " -Severity 2 -Source $deployAppScriptFriendlyName

            For ($x = 0; $x -lt $ArrLeng - 1; $x++) {
                Write-Log -Message -Message "DirArr[$x]: $DirArr[$x] " -Severity 2 -Source $deployAppScriptFriendlyName
                if ($BaseDir -eq "") { $BaseDir = $DirArr[$x] }
                else { $BaseDir = $BaseDir + "\" + $DirArr[$x] }
            }

            $PartName = ($DirArr[$DirArr.Length - 1]).Trim("*")
            $Paths = Get-ChildItem $BaseDir | Where-Object {$_.Attributes -match'Directory'}

            if (!($Paths)) { Write-Log -Message "There is no folders match the criterium." } 
            Else {
              Write-Log -Message -Message "PartName: $PartName " -Severity 2 -Source $deployAppScriptFriendlyName
              Write-Log -Message -Message "BaseDir: $BaseDir " -Severity 2 -Source $deployAppScriptFriendlyName
              Write-Log -Message -Message "Paths: $Paths " -Severity 2 -Source $deployAppScriptFriendlyName

              foreach($path in $Paths) {
                $dirP = $path.FullName
                if (($dirP -like "*$PartName*") -or ($dirP -like "*$PartName")) {
                  Write-Log -Message -Message "Directory: $dirP" -Severity 2 -Source $deployAppScriptFriendlyName
                  Remove-Dir -dir $dir -dirMode $dirMode -localForce $localForce
                }
              }
            }
          } else { Remove-Dir -dir $dirU -dirMode $dirMode -localForce $localForce }
        }
      } else { 
        if ($LastChar -eq "*") { 
          $BaseDir = ""
          $DirArr = $dir.Split("\")
          $ArrLeng = $DirArr.Length

          Write-Log -Message -Message "ArrLeng: $ArrLeng " -Severity 2 -Source $deployAppScriptFriendlyName

          For ($x = 0; $x -lt $ArrLeng - 1; $x++) {
              Write-Log -Message -Message "DirArr[$x]: $DirArr[$x] " -Severity 2 -Source $deployAppScriptFriendlyName
              if ($BaseDir -eq "") { $BaseDir = $DirArr[$x] }
              else { $BaseDir = $BaseDir + "\" + $DirArr[$x] }
          }

          $PartName = ($DirArr[$DirArr.Length - 1]).Trim("*")
          $Paths = Get-ChildItem $BaseDir | Where-Object {$_.Attributes -match'Directory'}

          if (!($Paths)) { Write-Log -Message "There is no folders match the criterium." 
          } else {
            Write-Log -Message -Message "PartName: $PartName " -Severity 2 -Source $deployAppScriptFriendlyName
            Write-Log -Message -Message "BaseDir: $BaseDir " -Severity 2 -Source $deployAppScriptFriendlyName
            Write-Log -Message -Message "Paths: $Paths " -Severity 2 -Source $deployAppScriptFriendlyName

            foreach($path in $Paths) {
              $dirP = $path.FullName
              if (($dirP -like "*$PartName*") -or ($dirP -like "*$PartName")) {
                Write-Log -Message -Message "Directory: $dirP" -Severity 2 -Source $deployAppScriptFriendlyName
                Remove-Dir -dir $dir -dirMode $dirMode -localForce $localForce
              }
            }
          }
        } else { Remove-Dir -dir $dir -dirMode $dirMode -localForce $localForce }
      }
      $x++
    }
  } elseif ($action.ToUpper() -eq "COPY") {
    $x = 0
    foreach ($OldDir in $SrcDirs) {
      if ($SrcDirs.Length -eq $Dirs.Length) { $NewDir = $Dirs[$x] }
      else { $NewDir = $Directory }

      Write-Log -Message "Copy directory from: $OldDir to: $NewDir."

      if ($forAllUsers -eq $True) {
        ForEach ($User In (Get-WmiObject Win32_UserProfile -F "Special != True" | Select-Object -Expand LocalPath)) {
          Write-Log -Message "\User\NewDir - $($User)$NewDir"
          $UserDir = "$User$NewDir"
          $OldDir = Set-TrimLastChar -string $OldDir 
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
  } elseif ($action.ToUpper() -eq "MOVE") {
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
  } elseif ($action.ToUpper() -eq "RENAME") {
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
  
  Write-Log -Message "Ending: $($MyInvocation.MyCommand)." -Source $deployAppScriptFriendlyName
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function Remove-Dir {
  param(
    [Parameter(Mandatory = $True)]
    $dir,
    [Parameter(Mandatory = $False)]
    $dirMode = "",
    [Parameter(Mandatory = $False)]
    $localForce = $True
  )

  $areFiles = $False

  if (Test-Path "$dir") {
    Write-Log -Message "Directory $dir exists."
    if (($localForce -eq $True) -or ($dirMode.ToLower() -eq "recurse")) { Get-ChildItem "$dir" -Recurse | Remove-Item -Recurse -Force }

    $dirs = Get-ChildItem "$dir" -Recurse | Where-Object { $_.PSIsContainer } | Select-Object FullName

    foreach ($container in $dirs) { if ((Get-ChildItem -LiteralPath "$($container.FullName)" -File -Force | Select-Object -First 1 | Measure-Object).Count -ne 0) { $areFiles = $True } }

    if ($areFiles) { Write-Log -Message "$dir will not be removed because is not set to Force and directory is not empty." } 
    else { Write-Log -Message "$dir will be removed."; Remove-Item "$dir" }

    Write-Log -Message "$dir removed."
  } Else { Write-Log -Message "Directory $dir doesn't exist." } 
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function Set-Script {
  param(
    [Parameter(Mandatory = $True)]
    $actionDate,
    [Parameter(Mandatory = $True)]
    $name
  )
  
  Write-Log -Message "Starting: $($MyInvocation.MyCommand)/$($actionDate.$name.appName)." -Source $deployAppScriptFriendlyName

  $scriptName = $actionDate.$name.scriptName
  $scriptDir = $actionDate.$name.scriptDir
  $scriptParam = $actionDate.$name.scriptParam

  $scriptNames = Get-MultiData -SrcData $scriptName
  $scriptDirs = Get-MultiData -SrcData $scriptDir
  $scriptParams = Get-MultiData -SrcData $scriptParam

  if (($scriptNames.Length -gt 0) -and ($scriptNames[0] -ne "") -and ($null -ne $scriptNames[0])) { 
  $x = 0
    foreach($script in $scriptNames) { 
      $script = Set-FullStringsFromVars -VarToCheck $script

      if (Test-forArrays -arr1 $scriptNames -arr2 $scriptDirs) { $scriptDirectory = Set-FullStringsFromVars -VarToCheck $scriptDirs[$x] } 
      else { $scriptDirectory = Set-FullStringsFromVars -VarToCheck $scriptDir }

      if ((Test-forArrays -arr1 $scriptNames -arr2 $scriptParams) -eq $True) { $scriptParameter = Set-FullStringsFromVars -VarToCheck $scriptParams[$x] } 
      else { $scriptParameter = Set-FullStringsFromVars -VarToCheck $scriptParam }

      Write-Log -Message "Trying to start: $scriptDirectory\$script $scriptParameter"

      if (Test-forVariable -varName $scriptDirectory) { $scriptPath = "$SourcePath\$script" } 
      else { $scriptPath = "$scriptDirectory\$script" }
  
      Test-ifParamFileExist -path "$scriptPath"

      if ($script.ToLower() -like "*.vbs") {
        if (Test-forVariable -varName $scriptParameter) { 
          Write-Log -Message "Command to run: $scriptPath"; 
          & wscript /nologo "$scriptPath" 
        } else { 
          Write-Log -Message "Command to run: $scriptPath $scriptParameter"; 
          & wscript /nologo "$scriptPath" "$scriptParameter" 
        } 
      } elseif ($script.ToLower() -like "*.cmd") { 
        if (Test-forVariable -varName $scriptParameter) { 
          Write-Log -Message "Command to run: $scriptPath"; 
          Start-Process "$scriptPath" 
        } else {
          Write-Log -Message "Command to run: $scriptPath $scriptParameter"; 
          Start-Process "$scriptPath" "$scriptParameter" 
        }
      } elseif ($script.ToLower() -like "*.ps1") { 
        if (Test-forVariable -varName $scriptParameter) { 
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
    $actionDate,
    [Parameter(Mandatory = $True)]
    $name
  )

  $DirPath = $actionDate.$name.path
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
Function Set-File {
  param(
    [Parameter(Mandatory = $True)]
    $actionDate,
    [Parameter(Mandatory = $True)]
    $name
  )

<# 
file_1:
  action: "REMOVE"
  inPath: "c:\\"
  outPath: "c:\\test\\"
  fileName: "app.exe"
  force: "false"
file_2:
  action: "COPY"
  inPath: "c:\\"
  outPath: "c:\\test\\"
  fileName: "app.exe"
  force: "false"
file_3:
  action: "MOVE"
  inPath: "c:\\"
  outPath: "c:\\test\\"
  fileName: "app.exe"
  force: "false" 
file_:
  action: "CHECK"
  inPath: "c:\\"
  fileName: "app.exe"
  exit: "ifMissing" #ifInPlace noExit 
#>

  $forAllUsers = $False
  $x = 0

  $action = $actionDate.$name.action

  $OldDir = $actionDate.$name.inPath
  $NewDir = $actionDate.$name.outPath
  $FileName = $actionDate.$name.fileName
  $NewFileName = $actionDate.$name.newFileName
  $isForce = $actionDate.$name.force
  $isExit = $actionDate.$name.exit

  if (($OldDir -like "*%allusers%*") -or ($OldDir -like "%allusers%*")) { $forAllUsers = $True }
  if (($NewDir -like "*%allusers%*") -or ($NewDir -like "%allusers%*")) { $forAllUsers = $True }
  
  $NewDir = Set-FullStringsFromVars -VarToCheck $NewDir
  $OldDir = Set-FullStringsFromVars -VarToCheck $OldDir
  $FileNames = Get-MultiData -SrcData $FileName
  $NewFileNames = Get-MultiData -SrcData $NewFileName

  if (Test-forVariable -varName $isExit) { $isExit = "noExit" }


  if ($action.ToUpper() -eq "COPY") {
    foreach ($file in $FileNames) {
      $FileName = $file
      $Directory = $OldDir
      $TargetDirectory = $NewDir

      if ($Directory -like "") { $Directory = $SourcePath }
      $Directory = Set-TrimLastChar -string $Directory

      if ($forAllUsers -eq $True) {
        Write-Log -Message "Will copy $Directory\$FileName to $TargetDirectory."

        ForEach ($User In (Get-WmiObject Win32_UserProfile -F "Special != True" | Select-Object -Expand LocalPath)) {
          
          $DirectoryUser = Set-RelativePath -path $Directory -prePath $User
          $TargetDirectoryU = Set-RelativePath -path $TargetDirectory -prePath $User

          if ($FileName -eq "*") {
            Set-NewDirectory -path $TargetDirectory -force $True
            Copy-Item -Path "$Directory\*" -Destination "$TargetDirectory" -Recurse -Force
          } else {
            $DestToUser = '"'+"$TargetDirectoryU\$FileName"+'"'
            $DirectoryU = '"'+"$DirectoryUser\$FileName"+'"'

            if (-not (Test-Path -Path $DestToUser)) {
              Set-NewDirectory -path $TargetDirectoryU -force $True
              Write-Log -Message "cmd /C copy /Y $DirectoryU $DestToUser"
              & cmd /C "copy /Y $DirectoryU $DestToUser"
            }
          }
        }
      } else {
        if ($FileName -eq "*") {
          if (Test-Path -Path $TargetDirectory) { Write-Log -Message "$TargetDirectory exists. Copying content of $Directory." } 
          else { New-Item -ItemType directory -Path "$TargetDirectory" }

          $TargetDirectory = Set-TrimLastChar -string $TargetDirectory
          $Directory = Set-TrimLastChar -string $Directory

          robocopy "$Directory" "$TargetDirectory" /Mir

          $AllFiles = Get-ChildItem -Path "$TargetDirectory\" -Name
          Write-Log -Message "Files in: $TargetDirectory\."
          foreach ($f in $AllFiles) { Write-Log -Message "- $f." }
        } else {

          if ($isForce -eq "true") { if (Test-Path -Path $TargetDirectory) { Remove-Item $TargetDirectory } }
          if (Test-Path -Path $TargetDirectory) { Write-Log -Message "$TargetDirectory exists. Copying $FileName." } 
          else {
              Write-Log -Message "$TargetDirectory doesn't exist, creating."
              New-Item -ItemType directory -Path "$TargetDirectory"
          }

          $NewDir = '"'+$TargetDirectory+'"'
          if (-not(Test-Path -Path $TargetDirectory)) {
              Write-Log -Message "copy $Directory $TargetDirectory"
              & cmd /C "copy $Directory $TargetDirectory"
          }
        }
      }
      $x++
    }
  } elseif ($action.ToUpper() -eq "REMOVE") {
    foreach ($file in $FileNames) {
      $FileName = $file
      $Directory = $NewDir

      Write-Log -Message "Removing: $Directory\$FileName"
      $Directory = Set-TrimLastChar -string $Directory

      if ($forAllUsers -eq $True) {
        ForEach ($User In (Get-WmiObject Win32_UserProfile -F "Special != True" | Select-Object -Expand LocalPath)) {
          $DirectoryUser = Set-RelativePath -path $Directory -prePath $User
           
          if ($FileName.Contains("*")) { 
            Write-Log -Message "Remove all files includes $FileName in $DirectoryUser"
            Remove-Item "$DirectoryUser\*.*" | Where-Object { ! $_.PSIsContainer }
          } else {
            Write-Log -Message "Remove-Item $DirectoryUser\$FileName"
            if (Test-Path -Path "$DirectoryUser\$FileName") { Remove-Item "$DirectoryUser\$FileName" }
          } 
        }
      } else {
        if ($FileName.Contains("*")) { 
          Write-Log -Message "Remove all files includes $file in $Directory"
          Remove-Item "$Directory\*.*" | Where-Object { ! $_.PSIsContainer }
        } else {
          Write-Log -Message "cmd /C del $Directory$File"
          & cmd /C "del $Directory\$File" 
        }
      }
    }
  } elseif ($action.ToUpper() -eq "RENAME") {
    if ((Test-forArrays -arr1 $FileNames -arr2 $NewFileNames) -eq $True) {
      foreach ($file in $FileNames) {
        $FileName = $file
        if ($NewFileNames -is [array]) { $NewFileName = $NewFileNames[$x] } else { $NewFileName = $NewFileName }
        $Directory = $NewDir

        if ($forAllUsers -eq $True) {
          ForEach ($User In (Get-WmiObject Win32_UserProfile -F "Special != True" | Select-Object -Expand LocalPath)) {
            $DirectoryUser = "$User$Directory"
            Write-Log -Message "\User\Directory - $DirectoryUser"
                
            $FileU = '"' + $DirectoryUser + "\" + $FileName + '"'
            $NewFileName = '"' + $NewFileName + '"'
            Write-Log -Message "RENAME $FileU $NewFileName."
            & cmd /C "RENAME $FileU $NewFileName"
          }
        } else {
          $File = '"' + $Directory + "\" + $FileName + '"'
          $NewFileName = '"' + $NewFileName + '"'
          Write-Log -Message "RENAME $File $NewFileName."
          & cmd /C "RENAME $File $NewFileName"
        }
        $x++
      }
    } else {
      Write-Log -Message "Script failed, diffrent number of files in parameteres in  $($MyInvocation.MyCommand)" -Severity 3 -Source $deployAppScriptFriendlyName
      Exit-Script -ExitCode $Global:RCMissingParameter
    }
  } elseif ($action.ToUpper() -eq "MOVE") {
  } elseif ($action.ToUpper() -eq "ADD") {
  } elseif ($action.ToUpper() -eq "EDIT") {
  } elseif ($action.ToUpper() -eq "CHECK") {
  }

}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function Set-DetectionMethod {
  param(
    [Parameter(Mandatory = $True)]
    $actionDate
  )

  #INSTALL,ADD,DetectionMethod,GUID=PKGName=file=registry;regvalue,ExitCodeValue;allNegative    
  #can test for negative or positive. if - is added as first sign on GUID, PKGName,File orRegistry then script will end if -not will be as result,
  #if + or simply - will be missing test will be done for positive.

  $GUIDResult     = 0
  $TAGResult      = 0
  $FileResult     = 0
  $RegResult      = 0
  $ExitScript     = $False

  if (Test-forVariable -varName $actionDate.$name.exitCode) { $ExitCodeVarName = 0 }
  else { $ExitCodeVarName = $actionDate.$name.exitCode }

  if (Test-forVariable -varName $actionDate.$name.allNegative) { $allNegative = 'false' }
  else { $allNegative = $actionDate.$name.allNegative }

  $AppGUID = $actionDate.$name.GUID
  if (Test-forVariable -varName $AppGUID) { $testForGUID = $false } 
  else { 
    if ($AppGUID -like "-*") { $GUIDForNegative = $True; $AppGUID = $AppGUID.substring(1) } 
    else { $GUIDForNegative = $False }
    $testForGUID = $true
  }

  $AppPKGName = $actionDate.$name.TAG
  if (Test-forVariable -varName $AppPKGName) { $testForPKGName = $false } 
  else {
    if ($AppPKGName -like "-*") { $TAGForNegative = $True; $AppPKGName = $AppPKGName.substring(1) }
    else { $TAGForNegative = $False }
    $testForPKGName = $true
  }

  $File = $actionDate.$name.filePath 
  if (Test-forVariable -varName $File) { $testForFile = $false } 
  else {
    if ($File -like "-*") { $FILEForNegative = $True; $File = $File.substring(1) } 
    else { $FILEForNegative = $False } 
    $testForFile = $true
  }
  
  $RegPath = $actionDate.$name.registryPath
  if (Test-forVariable -varName $RegPath) { $testForReg = $false } 
  else {
    if ($RegPath -like "-*") { $REGForNegative = $True; $RegPath = $RegPath.substring(1) } 
    else { $REGForNegative = $False }
    $testForReg = $true
  }

  $RegVarName = $actionDate.$name.registryVariableName
  $RegValue =$actionDate.$name.registryVariableValue


  if ($testForGUID) {
    $AppGUIDs = Get-MultiData -SrcData $AppGUID

    if (($AppGUIDs.Length -gt 0) -and ($AppGUIDs[0] -ne "") -and ($null -ne $AppGUIDs[0])) {
      foreach ($GUID in $AppGUIDs) {
        if (($GUID -ne "") -and ($null -ne $GUID)) {
          $isInstalled = (Get-InstalledApplication -ProductCode $GUID).DisplayName
          Write-Log -Message "isInstalled - $isInstalled"

          if ([string]::IsNullOrEmpty($isInstalled) -or ($isInstalled -eq "") -or $isInstalled -eq " ") {
            $ProdCode = (Get-InstalledApplication -Name $GUID).ProductCode
                  
            if ([string]::IsNullOrEmpty($ProdCode) -or ($ProdCode -eq "") -or $ProdCode -eq " ") { $GUIDResult = 1 } 
            else { $GUIDResult = 0 }
          } else { $GUIDResult = 0 }
        } else { $GUIDResult = 2 }
      }
    } else { $GUIDResult = 2 }
  }
  

  if ($testForPKGName) {
    $AppPKGNames = Get-MultiData -SrcData $AppPKGName

    if (($AppPKGNames.Length -gt 0) -and ($AppPKGNames[0] -ne "") -and ($null -ne $AppPKGNames[0])) {
      foreach ($tag in $AppPKGNames) {
        $TAGFile = "$TagsDir\$tag.tag"
        Write-Log -Message "Testing: - $TAGFile"

        if (Test-Path $TAGFile) { $TAGResult = 0 }
        else { $TAGResult = 1 }
      }
    } else { $TAGResult = 2 }
  }
  

  if ($testForFile) {
    $Files = Get-MultiData -SrcData $File

    if (($Files.Length -gt 0) -and ($Files[0] -ne "") -and ($null -ne $Files[0])) {
      foreach ($path in $Files) {
        if (Test-Path $path) { $FileResult = 0 }
        else { $FileResult = 1 }
      }
    } else { $FileResult = 2 }
  }
  

  if ($testForReg) { #TODO handle registry variable name and value
    $RegPaths = Get-MultiData -SrcData $RegPath
    $RegVarNames = Get-MultiData -SrcData $RegVarName
    $RegValues = Get-MultiData -SrcData $RegValues


    if (($RegPaths.Length -gt 0) -and ($RegPaths[0] -ne "") -and ($null -ne $RegPaths[0])) {
      foreach ($reg in $RegPaths) {
        $RegPathArr = $reg.split('\')
        $TMPRegPath = ""
        $TMPRegVar = $RegPathArr[-1]
        $x = 0

        foreach ($arrItem in $RegPathArr) { 
          if ($arrItem -ne $TMPRegVar) {
            if ($x -eq 0) { $TMPRegPath = $arrItem }
            else { $TMPRegPath = "$TMPRegPath\$arrItem" }
          }
          $x++
        }

        $TestConstainer = Test-Path $RegPath -PathType 'Container'
        if (($RegValue -eq "NULL") -or ($RegValue -eq "null")) {
          Write-Log -Message "No regValue option."
          if ($TestConstainer) { $RegResult = 0 
          } else { 
            $TestRegVal = Test-RegistryValue -Key $TMPRegPath -Value $TMPRegVar
            if ($TestRegVal) { $RegResult = 0 }
            else { $RegResult = 1 }      
          }
        } else {
          Write-Log -Message "RegValue option."
          if (Test-RegistryValue -Key $TMPRegPath -Value $TMPRegVar) { 
            $ReadReg = Get-ItemPropertyValue $TMPRegPath -Name $TMPRegVar
            Write-Log -Message "ReadReg - $ReadReg"
            if (($ReadReg -like "*$RegValue") -or ($ReadReg -like "*$RegValue*") -or ($ReadReg -like "$RegValue") -or ($ReadReg -like "$RegValue*")) { $RegResult = 0 }
            else { $RegResult = 1 }
          } else { $RegResult = 1 }
        }
      }
    } else { $RegResult = 2 }
  }

  if ((($GUIDResult -eq 0) -and ($GUIDForNegative -eq $True)) -or (($GUIDResult -eq 1) -and ($GUIDForNegative -eq $False))) { $GUIDResult = 1 }
  else { $GUIDResult = 0 }

  if ((($TAGResult -eq 0) -and ($TAGForNegative -eq $True)) -or (($TAGResult -eq 1) -and ($TAGForNegative -eq $False))) { $TAGResult = 1 }
  else { $TAGResult = 0 }

  if ((($FileResult -eq 0) -and ($FILEForNegative -eq $True)) -or (($FileResult -eq 1) -and ($FILEForNegative -eq $False))) { $FileResult = 1 }
  else { $FileResult = 0 }

  if ((($RegResult -eq 0) -and ($REGForNegative -eq $True)) -or (($RegResult -eq 1) -and ($REGForNegative -eq $False))) { $RegResult = 1 }
  else { $RegResult = 0 }
  
  Write-Log -Message "Detection method, testing results are:"
  Write-Log -Message "GUIDResult: $GUIDResult"
  Write-Log -Message "GUIDForNegative: $GUIDForNegative"
  Write-Log -Message "TAGResult: $TAGResult"
  Write-Log -Message "TAGForNegative: $TAGForNegative"
  Write-Log -Message "FileResult: $FileResult"
  Write-Log -Message "FILEForNegative: $FILEForNegative"
  Write-Log -Message "RegResult: $RegResult"
  Write-Log -Message "REGForNegative: $REGForNegative"

  if ($allNegative -eq 'true') { 
    if (($GUIDForNegative -eq $True) -and ($GUIDResult -ne 0)) { $ExitScriptA = $True }
    elseif (($GUIDForNegative -eq $False) -and ($GUIDResult -eq 0)) { $ExitScriptA = $True }
    else { $ExitScriptA = $False }

    if (($TAGForNegative -eq $True) -and ($TAGResult -ne 0)) { $ExitScriptB = $True }
    elseif (($TAGForNegative -eq $False) -and ($TAGResult -eq 0)) { $ExitScriptB = $True }
    else { $ExitScriptB = $False }

    if (($FILEForNegative -eq $True) -and ($FileResult -ne 0)) { $ExitScriptC = $True } 
    elseif (($FILEForNegative -eq $False) -and ($FileResult -eq 0)) { $ExitScriptC = $True }
    else { $ExitScriptC = $False }

    if (($REGForNegative -eq $True) -and ($RegResult -ne 0)) { $ExitScriptD = $True } 
    elseif (($REGForNegative -eq $False) -and ($RegResult -eq 0)) { $ExitScriptD = $True }
    else { $ExitScriptD = $False }

    Write-Log -Message "ExitScriptA: $ExitScriptA"
    Write-Log -Message "ExitScriptB: $ExitScriptB"
    Write-Log -Message "ExitScriptC: $ExitScriptC"
    Write-Log -Message "ExitScriptD: $ExitScriptD"

    if (($ExitScriptA -eq $True) -and ($ExitScriptB -eq $True) -and ($ExitScriptC -eq $True) -and ($ExitScriptD -eq $True)) { $ExitScript = $False }
    else { $ExitScript = $True }
  } else {
    if (($GUIDResult -eq 0) -and ($TAGResult -eq 0) -and ($FileResult -eq 0) -and ($RegResult -eq 0)) { $ExitScript = $True } #tests passed so script can stop - nothing to change
    else { $ExitScript = $False } #some of the tests failed, so script need to proceed
  }
    
  $ExitCodeVarName = $ExitCodeVarName.replace(' ','')
  
  if (($ExitCodeVarName -like "NULL*") -or ($ExitCodeVarName -like "null*") -or ($ExitCodeVarName -like "NULL") -or ($ExitCodeVarName -like "null")) { $ExitCodeVarName = 0 } 
  else { 
    try {
      $null = Get-Variable -Scope Global -Name $ExitCodeVarName -ErrorAction Stop
      $variableExists = $true
    } catch { $variableExists = $false }

    if ($variableExists) { $ExitCodeVarName = Get-Variable -Scope Global $ExitCodeVarName -ValueOnly }
  }

  [int]$intNum = [convert]::ToInt32($ExitCodeVarName, 10)

  if ($ExitScript -eq $True) { Write-Log -Message "Tests passed, going to next function, RC = 0." }
  else  {   
    Write-Log -Message "Will Exit Script - ExitCodeVarName = $ExitCodeVarName."
    Exit-Script -ExitCode $intNum 
  }
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function Set-MSIX {
  param(
    [Parameter(Mandatory = $True)]
    $actionDate,
    [Parameter(Mandatory = $True)]
    $name
  )

  Write-Log -Message "Starting: $($MyInvocation.MyCommand)." -Source $deployAppScriptFriendlyName

  $action = $actionDate.$name.action

  $MSIXFile = $actionDate.$name.file
  $MSIXName = $actionDate.$name.name
  $MSIXContext = $actionDate.$name.context
  $VolumeName = $actionDate.$name.volumeName
  $AppID = $actionDate.$name.appID
  $CMDToRun = $actionDate.$name.cmdToRun

  $x = 0
    
  if ($action.ToUpper() -eq "ADD") {
    $MSIXFiles = Get-MultiData -SrcData $MSIXFile
    foreach ($msix in $MSIXFiles) {
      $msix = Set-FullStringsFromVars -VarToCheck $msix 
      if (($msix -like "\*") -or (((-not ($msix -like "*:\*")) -and (-not ($msix -like "*%*"))))) { $msix = "$SourcePath\$msix"}  
      Test-ifParamFileExist -path $msix
      Write-Log -Message "Adding msix app: $msix." -Source $deployAppScriptFriendlyName
      Add-AppPackage -path "$msix"
    }
  } Elseif ($action.ToUpper() -eq "REMOVE"){
    $MSIXNames = Get-MultiData -SrcData $MSIXName
    $MSIXsContext = Get-MultiData -SrcData $MSIXContext
    foreach ($name in $MSIXNames) {
      if ((Test-forArrays -arr1 $MSIXNames -arr2 $MSIXsContext) -eq $True) { 
        if (!(Test-forVariable -varName $MSIXsContext[$x])) { $Context = $MSIXContext[$x] } 
      } else { 
        if (!(Test-forVariable -varName $MSIXContext)) { $Context = $MSIXContext }
      }
      Write-Log -Message "Removing msix app: $name $Context." -Source $deployAppScriptFriendlyName
      if (Test-forVariable -varName $Context) { Remove-AppPackage -Package $name }
      else { Remove-AppPackage -Package $name $Context }
      $x++
    }
  } Elseif ($action.ToUpper() -eq "MOVE"){
    $MSIXNames = Get-MultiData -SrcData $MSIXName
    $VolumeNames = Get-MultiData -SrcData $VolumeName
    foreach ($name in $MSIXNames) {
      if ((Test-forArrays -arr1 $MSIXNames -arr2 $MSIXsContext) -eq $True) { Move-AppPackage -Package $name -Volume $VolumeNames[$x] }
      elseif (Test-forVariable -varName $VolumeName) { Move-AppPackage -Package $name -Volume $VolumeName }
      else {  
        Write-Log -Message "Will Exit Script."
        Exit-Script -ExitCode $intNum  
      }
      $x++
    }  
  } Elseif ($action.ToUpper() -eq "RUN"){
    $MSIXNames = Get-MultiData -SrcData $MSIXName
    $AppIDs = Get-MultiData -SrcData $AppID
    $CMDsToRun = Get-MultiData -SrcData $CMDToRun
    foreach ($name in $MSIXNames) {
      if (((Test-forArrays -arr1 $MSIXNames -arr2 $AppIDs) -eq $True) -and ((Test-forArrays -arr1 $MSIXNames -arr2 $CMDsToRun) -eq $True)) {
        $CMDsToRun[$x] = Set-FullStringsFromVars -VarToCheck $CMDsToRun[$x]
        Write-Log -Message "Running msix app: $($CMDsToRun[$x])." -Source $deployAppScriptFriendlyName
        Invoke-CommandInDesktopPackage -PackageFamilyName $name -appid $AppIDs[$x] -command $CMDsToRun[$x] -preventbreakaway
      }
      $x++
    }
  }    
  
  Write-Log -Message "Ending: $($MyInvocation.MyCommand)." -Source $deployAppScriptFriendlyName

  #Move-AppPackage -Package "Caphyon.MyApp_1.0.0.0_neutral__8wekyb3d8bbwe" -Volume E:\
  #To dismount a volume you can use Dismount-AppVolume -Volume E:\
  #To remove a volume use Remove-AppVolume -Volume E:\
  #Invoke-CommandInDesktopPackage -PackageFamilyName "Caphyon.SampleMSIXPackage_r21n0w1rc5s2y" -appid "SampleMSIXPackage" -command "cmd.exe" -preventbreakaway
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function Set-APPV {
  param(
    [Parameter(Mandatory = $True)]
    $actionDate,
    [Parameter(Mandatory = $True)]
    $name
  )

  Write-Log -Message "Starting: $($MyInvocation.MyCommand)." -Source $deployAppScriptFriendlyName

  $action = $actionDate.$name.action

  $AppVFile = $actionDate.$name.file
  $Context = $actionDate.$name.context
  $LogType = $actionDate.$name.logType
  $AppVPKGName = $actionDate.$name.appVPKGName

  $x = 0

  if ($action.ToUpper() -eq "ADD") {
    $AppVFiles = Get-MultiData -SrcData $AppVFile
    $Contexts = Get-MultiData -SrcData $Context
    $LogTypes = Get-MultiData -SrcData $LogType
    $AppVPKGNames = Get-MultiData -SrcData $AppVPKGName
  
    foreach ($appv in $AppVFiles) {
      if (($AppVFiles.Length -eq $Contexts.Length) -and ($AppVFiles.Length -eq $LogTypes.Length) -and ($AppVFiles.Length -eq $AppVPKGNames.Length)) {
        $appv = Set-FileExtension -file $appv -extension ".appv"
        
        $appv = Set-FullStringsFromVars -VarToCheck $appv
        if (($appv -like "\*") -or (((-not ($appv -like "*:\*")) -and (-not ($appv -like "*%*"))))) { $appv = "$SourcePath\$appv"}  
        
        Test-ifParamFileExist -path $appv
        Get-AppvClientPackage -Name $AppVPKGNames[$x] | Stop-AppvClientPackage | Remove-AppvClientPackage
        Write-Log -Message "Adding and publishing: $appv." -Source $deployAppScriptFriendlyName
        Add-AppvClientPackage -Path $appv | Publish-AppvClientPackage -Global | Mount-AppvClientPackage -Verbose	
      }
      $x++
    }
  } elseif ($action.ToUpper() -eq "REMOVE") {
    $AppVPKGNames = Get-MultiData -SrcData $AppVPKGName
    foreach ($appv in $AppVPKGNames) { 
      Write-Log -Message "Stoping and removing appv: $AppVPKGName." -Source $deployAppScriptFriendlyName
      Get-AppvClientPackage -Name $AppVPKGName | Stop-AppvClientPackage | Remove-AppvClientPackage 
    }
  }
  
  Write-Log -Message "Ending: $($MyInvocation.MyCommand)." -Source $deployAppScriptFriendlyName
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function Set-ActiveSetups {
  param(
    [Parameter(Mandatory = $True)]
    $actionDate,
    [Parameter(Mandatory = $True)]
    $name
  )

  #INSTALL,ADD,AS,C:\Users\Public\Company\ProgramUserConfig.vbs=/Silent=Program User Config=ProgramUserConfig,null
  #UNINSTALL,ADD,AS,$envWinDir\regedit.exe=/S `"%SystemDrive%\Program Files (x86)\PS App Deploy\PSAppDeployHKCUSettings.reg`"=PS App Deploy Config=PS_App_Deploy_Config,null
  #UNINSTALL,REMOVE,AS,null=null=null={604F30E1-35F2-4E34-AA21-3E83CDE863E1};SAS_SASEnterpriseGuide,null

  Write-Log -Message "Starting: $($MyInvocation.MyCommand)." -Source $deployAppScriptFriendlyName

  $action = $actionDate.$name.action

  $Executable = $actionDate.$name.executable
  $Arguments = $actionDate.$name.parameters
  $Description = $actionDate.$name.description
  $Key =  = $actionDate.$name.keyName

  $AS32B = "SOFTWARE\Wow6432Node\Microsoft\Active Setup\Installed Components\"
  $AS64B = "SOFTWARE\Microsoft\Active Setup\Installed Components\"
  
  if ($action.ToUpper() -eq "ADD") {
    Write-Log -Message "Will ADD Active Setup with: $Executable $Arguments." -Source $deployAppScriptFriendlyName
    
    $Executable = Set-FullStringsFromVars -VarToCheck $Executable
    $Arguments = Set-FullStringsFromVars -VarToCheck $Arguments
    if (Test-forVariable -varName $Arguments) { $Arguments = "" }
    Set-ActiveSetup -StubExePath $Executable -Arguments $Arguments -Description $Description -Key $Key -Version $(get-date -f ddyHHmmss)
  } elseif ($action.ToUpper() -eq "REMOVE") {
    $Keys = Get-MultiData -SrcData $Key
    foreach ($KeyVar in $Keys) {
      Write-Log -Message "Will REMOVE Active Setup: $KeyVar." -Source $deployAppScriptFriendlyName
      if ($KeyVar -match "\*") { 
        $KeyVar = $KeyVar.replace("*","")
        Write-Log -Message "Active Setup key to remove: $KeyVar."

        $Regs = Get-Item "HKLM:\$AS32B$KeyVar*"
        foreach($Reg in $Regs) { Write-Log -Message "Remove $Reg "; Remove-RegistryKey -Key $Reg }

        $Regs = Get-Item "HKLM:\$AS64B$KeyVar*"
        foreach($Reg in $Regs) { Write-Log -Message "Remove $Reg "; Remove-RegistryKey -Key $Reg }
      } else { Set-ActiveSetup -Key $KeyVar -PurgeActiveSetupKey; Remove-RegistryKey -Key "HKEY_LOCAL_MACHINE\$AS32B\$KeyVar" }
    }
  }  
  Write-Log -Message "Ending: $($MyInvocation.MyCommand)." -Source $deployAppScriptFriendlyName
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function Set-Permissions {
  param(
    [Parameter(Mandatory = $True)]
    $actionDate,
    [Parameter(Mandatory = $True)]
    $name
  )

  Write-Log -Message "Starting: $($MyInvocation.MyCommand)." -Source $deployAppScriptFriendlyName

  $path = $actionDate.$name.path
  $owner = $actionDate.$name.owner #user
  $accessType = $actionDate.$name.accessType #FullControl
  $blockType = $actionDate.$name.blockType #Allow

  $path = Set-FullStringsFromVars -VarToCheck $path
  $path = Set-RelativePath -path $path

  $CmdToRun = "icacls $path /reset /t /c"
  $Result = Invoke-Expression -Command:$CmdToRun
  if (($Result -eq "null") -or ([string]::IsNullOrEmpty($Result))) { Write-Log -Message "$Result" }

  $acl = Get-Acl -Path "$path"
  $acl.SetAccessRuleProtection($true,$false)
  $acl.Access | ForEach-Object { $acl.RemoveAccessRule($_) | Out-Null }
  $ace = New-Object System.Security.Accesscontrol.FileSystemAccessRule ($owner, $accessType, "ContainerInherit,ObjectInherit", "InheritOnly", $blockType)
  $acl.AddAccessRule($ace)

  Set-Acl -Path "$path" -AclObject $acl

  Write-Log -Message "Ending: $($MyInvocation.MyCommand)." -Source $deployAppScriptFriendlyName
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function Set-VARs {
  param(
    [Parameter(Mandatory = $True)]
    $actionDate,
    [Parameter(Mandatory = $True)]
    $name
  )

  #INSTALL,ADD,VAR,type=name=value=context,null
  #UNINSTALL,IF,VAR,2000,null
  #System,User,Process

  Write-Log -Message "Starting: $($MyInvocation.MyCommand)." -Source $deployAppScriptFriendlyName

  $action = $actionDate.$name.action

  $VarName = $actionDate.$name.path
  $VarValue = $actionDate.$name.path
  $VarType = $actionDate.$name.path
  $VarContext = $actionDate.$name.path

  $VarNames = Get-MultiData -SrcData $VarName
  $VarValues = Get-MultiData -SrcData $VarValue
  $VarContexts = Get-MultiData -SrcData $VarContext

  $x = 0

  foreach ($Name in $VarNames) {
    if ((-not(Test-forVariable -varName $VarValue)) -and ($action.ToUpper() -eq "ADD")) {
      if ((Test-forArrays -arr1 $VarNames -arr2 $VarValues) -eq $True) {
        $Value = $VarValues[$x]
      } else { 
        Write-Log -Message "Script failed, diffrent number of parameteres between VarNames and VarValues $($MyInvocation.MyCommand)" -Severity 3 -Source $deployAppScriptFriendlyName
        Exit-Script -ExitCode $Global:RCMissingParameter
      }
    } 

    if ($VarType.ToUpper() -eq 'ENV') {
      if ((Test-forArrays -arr1 $VarNames -arr2 $VarContext) -eq $True) { $Context = $VarContexts[$x] }
      else { $Context = $VarContext }
    } 

    if ($action.ToUpper() -eq "ADD") {
      if ($VarType.ToUpper() -eq 'ENV') {
        Write-Log -Message "Adding System variable: $Name => $Value in $Context context." -Source $deployAppScriptFriendlyName
        if (($Context.ToUpper() -eq 'MACHINE') -or ($Context -eq 'System')) { [System.Environment]::SetEnvironmentVariable($Name, $Value, [System.EnvironmentVariableTarget]::Machine) }
        if ($Context.ToUpper() -eq 'USER') { [System.Environment]::SetEnvironmentVariable($Name, $Value, [System.EnvironmentVariableTarget]::User) }
        if ($Context.ToUpper() -eq 'PROCESS') { [System.Environment]::SetEnvironmentVariable($Name, $Value, [System.EnvironmentVariableTarget]::Process) }
      } elseif ($VarType.ToUpper() -eq 'LOC') {
        Write-Log -Message "Adding Script variable: $Name => $Value." -Source $deployAppScriptFriendlyName
        Remove-Variable -Name $Name -Scope "Global"
        New-Variable -Name $Name -Value $Value -Scope "Global"
      }
    } elseIf ($action.ToUpper() -eq "REMOVE") {   
      if ($VarType.ToUpper() -eq 'ENV') {
        Write-Log -Message "Removing System variable: $Name in $Context context." -Source $deployAppScriptFriendlyName
        if (($Context.ToUpper() -eq 'MACHINE') -or ($Context -eq 'System')) { [System.Environment]::SetEnvironmentVariable($Name, $null, [System.EnvironmentVariableTarget]::Machine) }
        if ($Context.ToUpper() -eq 'USER') { [System.Environment]::SetEnvironmentVariable($Name, $null, [System.EnvironmentVariableTarget]::User) }
        if ($Context.ToUpper() -eq 'PROCESS') { [System.Environment]::SetEnvironmentVariable($Name, $null, [System.EnvironmentVariableTarget]::Process) }
      } elseif ($VarType.ToUpper() -eq 'LOC') { 
        Write-Log -Message "Removing Script variable: $Name." -Source $deployAppScriptFriendlyName
        Remove-Variable -Name $Name -Scope "Global" }
    } 
    $x++
  }

  Write-Log -Message "Ending: $($MyInvocation.MyCommand)." -Source $deployAppScriptFriendlyName
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function Set-Tags {
  param(
    [Parameter(Mandatory = $True)]
    $actionDate,
    [Parameter(Mandatory = $True)]
    $name,
    [Parameter(Mandatory = $False)]
    $Action = "ADD"
  )

  $action = $actionDate.$name.action

}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function Set-MSOffice {
  param(
    [Parameter(Mandatory = $True)]
    $actionDate,
    [Parameter(Mandatory = $True)]
    $name,
    [Parameter(Mandatory = $False)]
    $Action = "ADD"
  )

    #PREINSTALL,ADD,OFFICE,EXEPath=xmlPath=PkgName,null
    #PREINSTALL,REMOVE,OFFICE,PkgGUID=LangCode=FamiliVer=PkgName,null
    #PREINSTALL,CHANGE,OFFICE,Module,null
  Write-Log -Message "Starting: $($MyInvocation.MyCommand)." -Source $deployAppScriptFriendlyName

  $officeToClick = "Common Files\Microsoft Shared\ClickToRun\OfficeClickToRun.exe" 
  $procList = @("PROFLWIZ","communicator","GroupChatConsole","AttendantConsole","DW20","LYNC","ONEDRIVE","GROOVE","MSPSCAN","MSPVIEW","OFFDIAG","EXCEL","INFOPATH","MSACCESS","MSOSYNC","MSOUC","MSPUB","MSTORE","MSTORDB","MSTRDB","OIS","ONENOTE","ONENOTEM","OUTLOOK","POWERPNT","SELFCERT","SETLANG","WINWORD","DATABASECOMPARE","SPREADSHEETCOMPARE","OCPUBMGR","VISIO","WINPROJ","SPDESIGN")
  $products = @("VisioProRetail","O365ProPlusRetail")
  $EXEOTCFile = "$env:programfiles\$officeToClick"

  $action = $actionDate.$name.action

  $PkgGUID = $actionDate.$name.GUID
  $LangCode = $actionDate.$name.langugeCode
  $FamVer = $actionDate.$name.version
  $PKGName = $actionDate.$name.pkgName
  $isKillProcess = $actionDate.$name.killProcesses
  $Module = $actionDate.$name.module
  $EXEFile = $actionDate.$name.exeFile
  $XMLFile = $actionDate.$name.xmlFile

  if ($action.ToUpper() -eq "REMOVE") {
    Write-Log -Message "Will uninstall MS Office."
    Write-Log -Message "MS Office processes wil be check and killed: $isKillProcess."
    
    if ($isKillProcess.ToLower() -eq "true") { Set-KillProcesses -procList $procList }

    $regGUID = Get-InstalledApplication -ProductCode $PkgGUID	

    if (-not(Test-forVariable -varName $regGUID)) { 
      Write-Log -Message "Office $regGUID is installed, going to uninstall."
      
      foreach($product in $products) {
        if($PkgGUID -like "$product*") { $Params = "scenario=install scenariosubtype=ARP sourcetype=None productstoremove=$product."+$FamVer+"_"+$LangCode+"_x-none culture="+$LangCode+" version."+$FamVer+"="+$FamVer+".0 DisplayLevel=false" }
        Test-ifParamFileExist -path $EXEOTCFile
        Execute-Process -Path $EXEOTCFile -Parameters $Params -WindowStyle 'Hidden'
      }   
    } else { Write-Log -Message "Office $regGUID is not installed, going to next step." }
  } elseIf ($action.ToUpper() -eq "ADD") {
    Write-Log -Message "Will install MS Office."
    $EXEFile = Set-FullStringsFromVars -VarToCheck $EXEFile
    $EXEFile = Set-RelativePath -path $EXEFile
    $XMLFile = Set-FullStringsFromVars -VarToCheck $XMLFile
    $XMLFile = Set-RelativePath -path $XMLFile -prePath $ConfigFilesPath

    Set-FileExtension -file $EXEFile -extension ".exe"
    Set-FileExtension -file $XMLFile -extension ".xml"
    Test-ifParamFileExist -path $EXEFile
    Test-ifParamFileExist -path $XMLFile

    $Params = "/configure "+'"'+$XMLFile+'"'

    Execute-Process -Path "$EXEFile" -Parameters $Params -WindowStyle 'Hidden'
  } elseIf ($action.ToUpper() -eq "CHANGE") {
    if ($Module.ToLower() -eq "teams") {
      Write-Log -Message "Will uninstall MS Teams."
      if (Test-forVariable -varName $PkgGUID) { $PkgGUID = "{39AF0813-FA7B-4860-ADBE-93B9B214B914}" }
      Get-WmiObject -Class Win32_Product | Where-Object {$_.IdentifyingNumber -eq $PkgGUID} | Remove-WmiObject
      $TeamsPath = "AppData\Local\Microsoft\Teams"
      $TeamsUsers = Get-ChildItem -Path "$ENV:SystemDrive\Users"
      $TeamsUsers | ForEach-Object {
        Try {
          if ( Test-Path -Path "$ENV:SystemDrive\Users\$($_.Name)\$TeamsPath" -PathType Container ) { $Item = "$ENV:SystemDrive\Users\$($_.Name)\$TeamsPath" }
          else { $Item = "$ENV:SystemDrive\Users\$($_.Name)\$TeamsPath" }
          Write-Log -Message $item
          if (Test-Path $Item) { 
            Start-Process -FilePath "$Item\Update.exe" -ArgumentList "-uninstall -s"
            Remove-Item -Path $Item -Recurse -Force -ErrorAction Ignore 
          }
        } Catch { Out-Null }
      }
    }
  } else {
    Write-Log -Message "Will Exit Script - ExitCodeVarName = $ExitCodeVarName."
    Exit-Script -ExitCode $intNum 
  }

  Write-Log -Message "Ending: $($MyInvocation.MyCommand)." -Source $deployAppScriptFriendlyName
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

  #if (($VarToCheck -eq "") -or ($VarToCheck -eq " ") -or ($null -eq $VarToCheck) -or ($empty -eq $VarToCheck)) { Return "" }
  if (Test-forVariable -varName $VarToCheck) { Return "" }
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
          
    if (Get-IsToChange -VarToTest "%allusers%" -VarToChange $VarToCheck) { $VarToCheck = $VarToCheck.Replace("%allusers%",""); $tempered = $True } 
              
    # %SYSTEMDRIVE% %COMMONPROGRAMFILES(x86)%
    # AllUsersStartMenu AllUsersPrograms AllUsersStartup AllUsersDesktop Fonts		
      
    if ($tempered) { Return $VarToCheck }
    else { Return $VarToCheckBak }
  }
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function Get-IsToChange {
  [OutputType([bool])]
  param(
    [Parameter(Mandatory = $True)]
    [String]$VarToTest,
    [Parameter(Mandatory = $True)]
    [String]$VarToChange
  )
  
  $RC = $false
  if (($VarToChange -like "$VarToTest*") -or ($VarToChange -like "*$VarToTest*") -or ($VarToChange -like "$VarToTest") -or ($VarToChange -like "*$VarToTest")) { $RC = $true }
 
  Return $RC
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function Get-MultiData {
  param(
    [Parameter(Mandatory = $True)]
    [AllowEmptyString()]
    [AllowNull()]
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
      if (($data -like "\*") -or ((-not ($data -like "*:\*")))) { $returnData = "$PreData\$data" }
      $x++
    }
  }

  Return $returnData
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function Test-ifParamFileExist {
  [OutputType([bool])]
  param(
    [Parameter(Mandatory = $True)]
    [String]$path
  )

  Write-Log -Message "Testing if: $path is a path or file and if param exist."

  if ((Test-Path -Path $path) -eq $True) { Write-Log -Message "Path: $path exist, going next."; Return $True }
  elseif (([System.IO.File]::Exists($path)) -eq $True) { Write-Log -Message "File: $path exist, going next."; Return $True }
  elseif ("null" -eq $path) { Write-Log -Message "Skipping param, is null."; Return $True }
  else { Write-Log -Message "$path missing, exiting script with RC = -1."; Exit-Script -ExitCode -1 }
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


#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function Get-DiscSpace {
	param( 
		$drive="$Env:HOMEDRIVE"
	)

  Write-Log -Message "Testing free space for: $drive."

  $toGB =  (1024*1024*1024)
  $toMB =  (1024*1024)

  $space = Get-PSDrive $drive[0] | Select-Object Used,Free

  $freeMB = $space.Free / $toMB
  $freeGB = $space.Free / $toGB
  $usedMB = $space.Used / $toMB
  $usedGB = $space.Used / $toGB

  $Total = $freeGB + $usedGB 
    
  Write-Log -Message "Drive $drive space statistics:"
  Write-Log -Message "Free space in MB: $freeMB."
  Write-Log -Message "Free space in GB: $freeGB."
  Write-Log -Message "Used space in MB: $usedMB."
  Write-Log -Message "Used space in MB: $usedGB."
  Write-Log -Message "Total space in GB: $Total."

  Return $freeMB
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function Test-forVariable {
  [OutputType([bool])]
	param( 
		$varName
	)
  
  $RC = $False
  if ([string]::IsNullOrEmpty($varName) -or ($varName -eq "") -or ($varName -eq " ") -or ($varName.ToUpper() -eq "NULL")) { $RC = $True }
  
  Return $RC
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function Test-forArrays {
  [OutputType([bool])]
	param( 
		$arr1,
    $arr2
  )
  
  Write-Log -Message "Testing if arr1 and arr2 are arrays and if arr1.length is = arr2.length."
  $RC = $False
  if (((($arr1 -is [array]) -and ($arr2 -is [array])) -and ($arr1.Length -eq $arr2.Length)) -or ((!($arr1 -is [array])) -and (!($arr2 -is [array])))) { $RC = $True }

  if($RC) { 
    Write-Log -Message "arr1 and arr2 are equal." 
  } else { 
    Write-Log -Message "arr1 and arr2 are not equal arrays." 
  }
  
  if (((!($arr1 -is [array])) -and (!($arr2 -is [array])))) { 
    $RC = "STRING"
    Write-Log -Message "arr1 and arr2 are not arrays." 
  }
  
  Return $RC
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function Set-CustomStandards {
	param( 
		$iniName = "Default"
	)

  $Configs
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function Set-NewDirectory {
	param( 
    [Parameter(Mandatory = $true)]
		$path,
    $force = $True
	)

  Write-Log -Message "Will check if $path exist and will create if not."
  if (-not(Test-Path $path -PathType Container)) { New-Item -ItemType Directory -Path $path -Force:$force | Out-Null }
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function Set-TrimLastChar {
	param( 
    [Parameter(Mandatory = $true)]
		$string,
    $char = "\"
	)

  Write-Log -Message "Will trim $char from $string."
  if ($string -like "*$char") { $RC = $string.Substring(0,$string.Length-1) }
  else { $RC = $string }
  Write-Log -Message "Triming result: $RC."

  Return $RC
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function Set-RelativePath {
	param( 
    [Parameter(Mandatory = $true)]
    $path,
    $prePath = $SourcePath
	)

  Write-Log -Message "Will check if $path is an relative path."

  if (-not($path -like "*:\*")) { $RC = "$prePath\$path" }
  else { $RC = "$path" }

  Write-Log -Message "Returning path: $RC."

  Return $RC
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function Set-FileExtension {
	param( 
    [Parameter(Mandatory = $true)]
    $file,
    [Parameter(Mandatory = $true)]
    $extension
	)

  Write-Log -Message "Will check if $file have extension: $extension."

  if ($file.ToLower() -like "*$extension") { $file = $file }
  else { $file = "$file$extension" }

  Write-Log -Message "Returning file: $RC."

  Return $RC
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function Set-KillProcesses {
	param( 
    [Parameter(Mandatory = $true)]
    $procList
	)

  Write-Log -Message "Processes will be checked and killed."
  foreach ($process in $procList) { 
    Stop-process -name $process -force -ErrorAction SilentlyContinue
    Write-Log -Message "Stopping: $process." 
  }
  Write-Log -Message "All processes handled."

}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  

#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function Get-UserGroupSID {
	param( 
    [Parameter(Mandatory = $true)]
    $name
	)

  $objUser = New-Object System.Security.Principal.NTAccount("$GroupUser")
  $strSID = $objUser.Translate([System.Security.Principal.SecurityIdentifier])
  $GroupUserSID = $strSID.Value

  Write-Log -Message "$name SID is: $GroupUserSID."

  Return $GroupUserSID
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  




