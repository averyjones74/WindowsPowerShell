<#
.SYNOPSIS
Create a persistent mapping of a folder to a new drive letter.

.PARAMETER DriveLabel
The volume label to apply to the new drive; default is to use the leaf folder
name indicated by Path.

.PARAMETER DriveLetter
The drive letter to map to Path. This drive letter must not be in use currently.

.PARAMETER Force
Force override of the source drive label when a mapping already exists on that drive
or force an override of the mapped drive letter if already mapped

.PARAMETER Path
Path to the folder to map to DriveLetter. This cannot be a root (C:\) or a top
level folder (C:\foo) - it must be at least a second level folder.

.PARAMETER SourceDriveLabel
New label to apply to the source drive; default it to retain the current label.
#>

using namespace System.IO

[CmdletBinding(SupportsShouldProcess = $true)]

param (
	[Parameter(Mandatory=$true, Position=0, HelpMessage='Drive letter must not be currently used')]
	[ValidateLength(1, 1)]
	[ValidatePattern('[A-Z]')]
	[ValidateScript({
		if (Get-Volume $_ -ErrorAction 'SilentlyContinue') {
			Throw 'Cannot reuse a physical drive letter'
		}
		$true
	})]
	[string] $DriveLetter,

	[Parameter(Mandatory=$true, Position=1, HelpMessage='Path must specify a valid folder path')]
	[ValidateScript({
		if (Test-Path $_) {
			$lev=0; $p = $_; do { $p = split-path $p; $lev++ } while ($p)
			if ($lev -gt 2) { return $true }
		}
		Throw 'Path does not exist or is not at least a second level folder'
	})]
	[string] $Path,

	[string] $SourceDriveLabel,
	[string] $DriveLabel,

	[switch] $Force
	)

Begin
{
	$DriveIconsKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\DriveIcons'
	$DOSDevicesKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\DOS Devices'

	function MapFolderToDriveLetter ()
	{
		$sourceLetter = ([Path]::GetPathRoot($Path))[0]

		# In order for this to work, the drive containing the source folder must be given a
		# label in the Registry but that would conflict with the volume name so we must first
		# clear the volume label; this will be rectified below by setting it in the Registry.
		# Filter by drive letter and only if it still has a volume name
		if ($WhatIfPreference) {
			Write-Host "clear label of $sourceLetter drive" -ForegroundColor DarkYellow
		} else {
			Write-Verbose "clear label of $sourceLetter drive"
			Get-Volume $sourceLetter | ? { $_.FileSystemLabel -ne '' } | Set-Volume -NewFileSystemLabel ''
		}
		Write-Verbose 'cleared label of source drive'

		# create new volume label for source drive if one doesn't already exist or if override
		if ($Force -or [String]::IsNullOrEmpty((Get-ItemPropertyValue `
			"$DriveIconsKey\$sourceLetter\DefaultLabel" -Name '(Default)' -ErrorAction 'SilentlyContinue')))
		{
			if ($WhatIfPreference) {
				Write-Host "Set-ItemProperty ""$DriveIconsKey\$sourceLetter"" -Name 'DefaultLabel' -Value $SourceDriveLabel" -ForegroundColor DarkYellow
			} else {
				Write-Verbose "Set-ItemProperty ""$DriveIconsKey\$sourceLetter"" -Name 'DefaultLabel' -Value $SourceDriveLabel"
				if (!(Test-Path "$DriveIconsKey\$sourceLetter")) {
					New-Item "$DriveIconsKey\$sourceLetter" -Force
				}
				Set-ItemProperty "$DriveIconsKey\$sourceLetter" -Name 'DefaultLabel' -Value $SourceDriveLabel -Force
			}
			Write-Verbose 'set new volume label for source drive'
		}

		# create volume label for mapped drive
		if ($WhatIfPreference) {
			Write-Host "Set-ItemProperty ""$DriveIconsKey\$DriveLetter"" -Name 'DefaultLabel' -Value $DriveLabel" -ForegroundColor DarkYellow
		} else {
			Write-Verbose "Set-ItemProperty ""$DriveIconsKey\$DriveLetter"" -Name 'DefaultLabel' -Value $DriveLabel"
			if (!(Test-Path "$DriveIconsKey\$DriveLetter")) {
				New-Item "$DriveIconsKey\$DriveLetter" -Force
			}
			Set-ItemProperty "$DriveIconsKey\$DriveLetter" -Name 'DefaultLabel' -Value $DriveLabel -Force
		}
		Write-Verbose 'set new volume label for mapped drive'

		# map virtual drive
		if ($WhatIfPreference) {
			Write-Host "Set-ItemProperty ""$DOSDevicesKey"" -Name ""${DriveLetter}:"" -Value ""\??\$Path""" -ForegroundColor DarkYellow
		} else {
			Write-Verbose "Set-ItemProperty ""$DOSDevicesKey"" -Name ""${DriveLetter}:"" -Value ""\??\$Path"""
			Set-ItemProperty "$DOSDevicesKey" -Name "${DriveLetter}:" -Value "\??\$Path" -Force
		}
		Write-Verbose 'mapped virtual drive'

		# restart (TODO: can we just restart Explorer?)
		#Restart-Computer -Force -Timeout 0
	}
}
Process
{
	if (!$Force -and ((Get-ItemPropertyValue "Registry::$DOSDevicesKey" -Name ('{0}:' -f $DriveLetter) -ErrorAction 'SilentlyContinue') -ne $null))
	{
		Throw 'Drive letter is already mapped; use -Force to override'
	}

	$Path = [Path]::GetFullPath($Path)

	if (!$SourceDriveLabel)
	{
		$SourceDriveLabel = (Get-Volume (([Path]::GetPathRoot($Path))[0])).FileSystemLabel
		if ([String]::IsNullOrEmpty($SourceDriveLabel))
		{
			$SourceDriveLabel = (Get-ItemPropertyValue "$DriveIconsKey\$sourceLetter\DefaultLabel" -Name '(Default)' -ErrorAction 'SilentlyContinue')
		}
	}

	if (!$DriveLabel)
	{
		$DriveLabel = $Path | Split-Path -Leaf
	}

	MapFolderToDriveLetter
}