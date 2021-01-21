$Global:PSScriptRoot            = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$Global:ParentScriptRoot        = Split-Path $PSScriptRoot -Parent

$Global:ConfigFilesPath         = $ParentScriptRoot + "\_ConfigFiles"
$Global:PrerequisitesPath       = $ParentScriptRoot + "\_Prerequisites"
$Global:SourcePath              = $ParentScriptRoot + "\_Source"
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
        if ($name -like "file_*") { }
        if ($name -like "directory_*") { }
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

  Write-Log -Message "Starting: $($MyInvocation.MyCommand)/$($actionDate.appName)." -Source $deployAppScriptFriendlyName

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
          Remove-MSIApplications -Name $CurrentMSIGUID -LogNameV $PKGName
        }

        if ($msiFiles.Length -eq $appNames.Length) { $logName = $appNames[$x] }
        else { $logName = $CurrentMSIGUID }

        if ($msiFiles.Length -eq $mstFile.Length) {
          if ($msiFiles.Length -eq $allParams.Length) { Execute-MSI -Action 'Install' "$msi" -Transform "$($mstFiles[$x])" -LogNameV "$logName" -AddParameters "$($allParams[$x])" }
          else { Execute-MSI -Action 'Install' "$msi" -Transform "$($mstFiles[$x])" -LogNameV "$logName" }
        } else { 
          if ($msiFiles.Length -eq $allParams.Length) { Execute-MSI -Action 'Install' "$msi" -LogNameV "$logName" -AddParameters "$($allParams[$x])" }
          else { Execute-MSI -Action 'Install' "$msi" -LogNameV "$logName" }
        }
        
        if ($msiFiles.Length -eq $mspFiles.Length) { 
          Test-IfParamFileExist -path $mspFiles[$x]
          Execute-MSP -Path "$($mspFiles[$x])" 
        }
        $x++
      }
    } elseif (($mspFiles.Length -gt 0) -and ($mspFiles[0] -ne "") -and ($null -ne $mspFiles[0])) { 
      foreach($msp in $mspFiles) { 
        Test-IfParamFileExist -path $msp
        Execute-MSP -Path "$msp" 
      }
    }
 
  } elseif ($actionDate.action.ToUpper() -eq "REMOVE") {

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
