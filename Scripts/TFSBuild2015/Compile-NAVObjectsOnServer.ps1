Param (
	[String]$NavIde,
	[String]$Files,
	[String]$LogFolder,
	[Bool]$CompileAll,
	[String]$Server,
	[String]$Database,
        [String]$ServerInstance
)
if (Test-Path $env:BUILD_SOURCESDIRECTORY\setup.xml) {
    $config = (. "$PSScriptRoot\..\Get-NAVGITSetup.ps1" -SetupFile "$env:BUILD_SOURCESDIRECTORY\setup.xml")
}
if (-not $Files) {
    $Files = $config.Files
}

if (-not $Server)
{
    $Server = $config.Server
}

if (-not $Database)
{
    $Database = $config.Database
}

if (-not $ServerInstance)
{
    $ServerInstance = $config.ServerInstance
}

Import-Module CommonPSFunctions -Force -DisableNameChecking
Import-Module NVR_NAVScripts -Force -DisableNameChecking
Import-Module (Get-NAVAdminModuleName -NAVVersion $config.NAVVersion) -Force

$ProgressPreference="SilentlyContinue"
Write-Host 'Compiling uncompiled system tables...'
Compile-NAVApplicationObject2 -DatabaseServer $Server -DatabaseName $Database -Filter 'Type=Table;Id=2000000000..' -LogPath $LogFolder -SynchronizeSchemaChanges Force -NavServerName localhost -NavServerInstance $ServerInstance
#Preventing the error about "Must be compiled..."
Write-Host 'Compiling uncompiled menusuites...'
Compile-NAVApplicationObject2 -DatabaseServer $Server -DatabaseName $Database -Filter 'Type=MenuSuite;Compiled=0' -LogPath $LogFolder -SynchronizeSchemaChanges Force -ErrorAction SilentlyContinue -NavServerName localhost -NavServerInstance $ServerInstance
Write-Host 'Compiling rest of objects...'
if ($CompileAll -eq 1) {
    #	Compile-NAVApplicationObjectFilesMulti -Files $Files -Server $Server -Database $Database -LogFolder $LogFolder -NavIde $NavIde
    Write-Host 'Compiling non-test objects...'
    Compile-NAVApplicationObjectMulti -Server $Server -Database $Database -Filter 'Compiled=0|1;Version List=<>*Test*'-LogFolder $LogFolder -NavIde $NavIde  -SynchronizeSchemaChanges Force -AsJob -NavServerName localhost -NavServerInstance $ServerInstance
    Write-Host 'Compiling test objects...'
    Compile-NAVApplicationObjectMulti -Server $Server -Database $Database -Filter 'Compiled=0|1;Version List=*Test*'-LogFolder $LogFolder -NavIde $NavIde  -SynchronizeSchemaChanges Force -AsJob -NavServerName localhost -NavServerInstance $ServerInstance
} else {
    Write-Host 'Compiling non-test objects...'
    Compile-NAVApplicationObject2 -DatabaseServer $Server -DatabaseName $Database -Filter 'Compiled=0;Version List=<>*Test*' -LogPath $LogFolder -SynchronizeSchemaChanges Force -NavServerName localhost -NavServerInstance $ServerInstance
    Write-Host 'Compiling test objects...'
    Compile-NAVApplicationObject2 -DatabaseServer $Server -DatabaseName $Database -Filter 'Compiled=0;Version List=*Test*' -LogPath $LogFolder -SynchronizeSchemaChanges Force -NavServerName localhost -NavServerInstance $ServerInstance
}
Sync-NAVTenant -ServerInstance $ServerInstance -Mode Force -Force
$ProgressPreference="Continue"
