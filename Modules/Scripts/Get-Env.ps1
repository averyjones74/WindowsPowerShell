<#
.SYNOPSIS
Print environment variables with optional highlighting.

.PARAMETER name
A string used to match and highlight entries based on their name.

.PARAMETER value
A string used to match and highlight entries based on their value.
#>

param (
	[string] $name,
	[string] $value)

Write-Host ("{0,-30} {1}" -f 'Name', 'Value')
Write-Host ("{0,-30} {1}" -f '----', '-----')

$pairs = Get-ChildItem env: | sort name | % `
{
	$ename = $_.Name.ToString()
	if ($ename.Length -gt 30) { $ename = $ename.Substring(0,27) + '...' }

	$evalue = $_.Value.ToString()
	$max = $host.UI.RawUI.WindowSize.Width - 32
	if ($evalue.Length -gt $max) { $evalue = $evalue.Substring(0, $max - 3) + '...' }

	if ($name -and ($_.Name -match $name))
	{
		Write-Host ("{0,-30} {1}" -f $ename, $evalue) -ForegroundColor Green
	}
	if ($value -and ($_.Value -match $value))
	{
		Write-Host ("{0,-30} {1}" -f $ename, $evalue) -ForegroundColor DarkGreen
	}
	elseif ([String]::IsNullOrEmpty($name) -and [String]::IsNullOrEmpty($value))
	{
		if ($_.Name -eq 'COMPUTERNAME' -or $_.Name -eq 'USERDOMAIN')
		{
			Write-Host ("{0,-30} {1}" -f $ename, $evalue) -ForegroundColor Blue				
		}
		elseif ($_.Name -match 'APPDATA' -or $_.Name -eq 'ProgramData')
		{
			Write-Host ("{0,-30} {1}" -f $ename, $evalue) -ForegroundColor Magenta
		}
		elseif ($evalue -match "$env:USERNAME(?:\\\w+){0,1}$")
		{
			Write-Host ("{0,-30} {1}" -f $ename, $evalue) -ForegroundColor DarkGreen
		}
		elseif ($_.Name -match 'ConEmu' -or $_.Value.IndexOf('\') -lt 0)
		{
			Write-Host ("{0,-30} {1}" -f $ename, $evalue) -ForegroundColor DarkGray
		}
		else
		{
			Write-Host ("{0,-30} {1}" -f $ename, $evalue)
		}
	}
	else
	{
		Write-Host ("{0,-30} {1}" -f $ename, $evalue)
	}
}
