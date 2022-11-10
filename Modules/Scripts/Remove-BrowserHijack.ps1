#Requires -RunAsAdministrator
<#
.SYNOPSIS
Removes corporate browser hijacking (default home page, broken Restore Pages feature, etc)

.DESCRIPTION
Removes group policy registry keys that are created by Waters IT in an attempt to waste
time by constantly directing users to a site they are not trying to visit.

.PARAMETER Install
Create a schedueled task that will periodically remove the hijack.
#>
[CmdletBinding(DefaultParameterSetName = 'Fix')]
param(
    [Parameter(ParameterSetName = 'Install')]
    [switch] $Install = $false,
    [Parameter(ParameterSetName = 'Uninstall')]
    [switch] $Uninstall = $false
)

Begin
{
    $taskName = 'Remove-BrowserHijack'

    function InstallHijack
    {
        $user = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

        $pwsh = [System.Diagnostics.Process]::GetCurrentProcess().Path
        $command = "& '${PSCommandPath}'"
        $command = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($command))

        $action = New-ScheduledTaskAction -Execute $pwsh `
            -Argument "-NonInteractive -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -EncodedCommand ${command}"

        $dailyTrigger = New-ScheduledTaskTrigger -Daily -At '7:00'
        $logonTrigger = New-ScheduledTaskTrigger -AtLogOn -User $user

        Register-ScheduledTask $taskName -Action $action -Trigger $dailyTrigger, $logonTrigger -User $user -RunLevel Highest
    }
	
    function UninstallHijack
    {
        Unregister-ScheduledTask $taskName
    }

    function RemoveHijack
    {
        param($0, $p)
        if (Test-Path $0)
        {
            $p | foreach { 
                if ((Get-ItemProperty $0).$_ -ne $null) {
                    Write-Host "removing $0 " -NoNewline -ForegroundColor DarkGray
                    Write-Host $_
                    Remove-ItemProperty $0 $_
                }
            }
        }    
    }

    function RemoveHijackKey
    {
        param($0)
        if (Test-Path $0) {
            Write-Host "removing $0"
            Remove-Item -Force -Recurse $0
        }
    }
}
Process
{
    if ($PSCmdlet.ParameterSetName -eq 'Install')
    {
        InstallHijack
        return
    }

    if ($PSCmdlet.ParameterSetName -eq 'Uninstall')
    {
        UninstallHijack
        return
    }

    # fix it now!


    #HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\MDM\AppDB

    # Chrome
    RemoveHijack 'HKCU:\SOFTWARE\Policies\Google\Chrome' @('HomePageLocation', 'RestoreOnStartup', 'ShowHomeButton')
    RemoveHijack 'HKLM:\SOFTWARE\Policies\Google\Chrome' @('HomePageLocation', 'RestoreOnStartup', 'ShowHomeButton')
    RemoveHijack 'HKCU:\SOFTWARE\Policies\Google\Chrome\Recommended' @('HomePageLocation', 'RestoreOnStartup', 'ShowHomeButton')
    RemoveHijack 'HKLM:\SOFTWARE\Policies\Google\Chrome\Recommended' @('HomePageLocation', 'RestoreOnStartup', 'ShowHomeButton')
    RemoveHijack 'HKCU:\SOFTWARE\Policies\Google\Chrome\RestoreOnStartupURLs' @('HomepageLocation')
    RemoveHijack 'HKCU:\SOFTWARE\Policies\Google\Chrome\Recommended\RestoreOnStartupURLs' @('HomepageLocation')

    RemoveHijackKey 'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Chrome~Policy~googlechrome~Startup'
    RemoveHijackKey 'HKLM:\SOFTWARE\Policies\Google\Chrome\RestoreOnStartupURLs'
    RemoveHijackKey 'HKLM:\SOFTWARE\WOW6432Node\Policies\Google\Chrome\RestoreOnStartupURLs'
    RemoveHijackKey 'HKLM:\SOFTWARE\WOW6432Node\Policies\Google\Chrome\Recommended\RestoreOnStartupURLs'
    RemoveHijackKey 'HKLM:\SOFTWARE\Microsoft\PolicyManager\AdmxDefault\89FA9032-04AF-4BA8-BD43-936A846F7EFE\Chrome~Policy~googlechrome_recommended~Startup_recommended'
    RemoveHijackKey 'HKLM:\SOFTWARE\Microsoft\PolicyManager\AdmxDefault\89FA9032-04AF-4BA8-BD43-936A846F7EFE\Chrome~Policy~googlechrome~Startup'
    RemoveHijackKey 'HKLM:\SOFTWARE\Microsoft\PolicyManager\Providers\89FA9032-04AF-4BA8-BD43-936A846F7EFE\default\Device\Chrome~Policy~googlechrome~Startup'

    # Edge
    RemoveHijack 'HKCU:\SOFTWARE\Policies\Microsoft\Edge\Recommended' @('HomepageLocation', 'RestoreOnStartup', 'ShowHomeButton', 'InternetExplorerIntegrationSiteList')
    RemoveHijack 'HKCU:\SOFTWARE\Policies\Microsoft\Edge\Internet Settings' @('ProvisionedHomePages')
    RemoveHijack 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' @('HomepageLocation', 'RestoreOnStartup', 'ShowHomeButton', 'InternetExplorerIntegrationSiteList')

    RemoveHijackKey 'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\microsoft_edge~Policy~microsoft_edge~Startup'
    RemoveHijackKey 'HKLM:\SOFTWARE\Policies\Microsoft\Edge\RestoreOnStartupURLs'
    RemoveHijackKey 'HKLM:\SOFTWARE\WOW6432Node\Policies\Microsoft\Policies\Microsoft\Edge\RestoreOnStartupURLs'
    RemoveHijackKey 'HKLM:\SOFTWARE\Microsoft\PolicyManager\AdmxDefault\89FA9032-04AF-4BA8-BD43-936A846F7EFE\microsoft_edge~Policy~microsoft_edge_recommended~Startup_recommended'
    RemoveHijackKey 'HKLM:\SOFTWARE\Microsoft\PolicyManager\AdmxDefault\89FA9032-04AF-4BA8-BD43-936A846F7EFE\microsoft_edge~Policy~microsoft_edge~Startup'
    RemoveHijackKey 'HKLM:\SOFTWARE\Microsoft\PolicyManager\Providers\89FA9032-04AF-4BA8-BD43-936A846F7EFE\default\Device\microsoft_edge~Policy~microsoft_edge~Startup'

    # Firefox
    RemoveHijackKey 'HKCU:\SOFTWARE\Policies\Mozilla\Firefox\Homepage'
}
