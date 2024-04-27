﻿<#
	.SYNOPSIS
	Download Office 2019, 2021, and 365

	.PARAMETER Branch
	Choose Office branch: 2019, 2021, and 365

	.PARAMETER Channel
	Choose Office channel: 2019, 2021, and 365

	.PARAMETER Components
	Choose Office components: Access, OneDrive, Outlook, Word, Excel, PowerPoint, Teams

	.EXAMPLE Download Office 2019 with the Word, Excel, PowerPoint components
	Download.ps1 -Branch ProPlus2019Retail -Channel Current -Components Word, Excel, PowerPoint

	.EXAMPLE Download Office 2021 with the Excel, Word components
	Download.ps1 -Branch ProPlus2021Volume -Channel PerpetualVL2021 -Components Excel, Word

	.EXAMPLE Download Office 365 with the Excel, Word, PowerPoint components
	Download.ps1 -Branch O365ProPlusRetail -Channel SemiAnnual -Components Excel, OneDrive, Outlook, PowerPoint, Teams, Word

	.EXAMPLE Download Office 365 with the Excel, Word components using Beta channel
	Download.ps1 -Branch O365ProPlusRetail -Channel BetaChannel -Components Excel, Word

	.LINK
	https://config.office.com/deploymentsettings

	.LINK
	https://docs.microsoft.com/en-us/deployoffice/vlactivation/gvlks

	.NOTES
	Run as non-admin
#>
[CmdletBinding()]
param
(
	[Parameter(Mandatory = $true)]
	[ValidateSet("ProPlus2019Retail", "ProPlus2021Volume", "O365ProPlusRetail")]
	[string]
	$Branch,

	[Parameter(Mandatory = $true)]
	[ValidateSet("BetaChannel", "Current", "PerpetualVL2021", "SemiAnnual")]
	[string]
	$Channel,

	[Parameter(Mandatory = $true)]
	[ValidateSet("Access", "OneDrive", "Outlook", "Word", "Excel", "PowerPoint", "Teams")]
	[string[]]
	$Components
)

if (-not (Test-Path -Path "$PSScriptRoot\Default.xml"))
{
	Write-Warning -Message "Default.xml doesn't exist"
	exit
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

if ($Host.Version.Major -eq 5)
{
	# Progress bar can significantly impact cmdlet performance
	# https://github.com/PowerShell/PowerShell/issues/2138
	$Script:ProgressPreference = "SilentlyContinue"
}

[xml]$Config = Get-Content -Path "$PSScriptRoot\Default.xml" -Encoding Default -Force

switch ($Branch)
{
	ProPlus2019Retail
	{
		($Config.Configuration.Add.Product | Where-Object -FilterScript {$_.ID -eq ""}).ID = "ProPlus2019Retail"
	}
	ProPlus2021Volume
	{
		($Config.Configuration.Add.Product | Where-Object -FilterScript {$_.ID -eq ""}).ID = "ProPlus2021Volume"
	}
	O365ProPlusRetail
	{
		($Config.Configuration.Add.Product | Where-Object -FilterScript {$_.ID -eq ""}).ID = "O365ProPlusRetail"
	}
}

switch ($Channel)
{
	BetaChannel
	{
		($Config.Configuration.Add | Where-Object -FilterScript {$_.Channel -eq ""}).Channel = "BetaChannel"
	}
	Current
	{
		($Config.Configuration.Add | Where-Object -FilterScript {$_.Channel -eq ""}).Channel = "Current"
	}
	PerpetualVL2021
	{
		($Config.Configuration.Add | Where-Object -FilterScript {$_.Channel -eq ""}).Channel = "PerpetualVL2021"
	}
	SemiAnnual
	{
		($Config.Configuration.Add | Where-Object -FilterScript {$_.Channel -eq ""}).Channel = "SemiAnnual"
	}
}

foreach ($Component in $Components)
{
	switch ($Component)
	{
		Access
		{
			$Node = $Config.SelectSingleNode("//ExcludeApp[@ID='Access']")
			$Node.ParentNode.RemoveChild($Node)
		}
		Excel
		{
			$Node = $Config.SelectSingleNode("//ExcludeApp[@ID='Excel']")
			$Node.ParentNode.RemoveChild($Node)
		}
		OneDrive
		{
			$OneDrive = Get-Package -Name "Microsoft OneDrive" -ProviderName Programs -Force -ErrorAction Ignore
			if (-not $OneDrive)
			{
				switch ((Get-CimInstance -ClassName Win32_OperatingSystem).Caption)
				{
					{$_ -match 10}
					{
						if (Test-Path -Path $env:SystemRoot\SysWOW64\OneDriveSetup.exe)
						{
							Write-Information -MessageData "" -InformationAction Continue
							Write-Verbose -Message "OneDrive Installing" -Verbose

							Start-Process -FilePath $env:SystemRoot\SysWOW64\OneDriveSetup.exe
						}
						else
						{
							$Script:OneDriveInstalled = $false
						}
					}
					{$_ -match 11}
					{
						if (Test-Path -Path $env:SystemRoot\System32\OneDriveSetup.exe)
						{
							Write-Information -MessageData "" -InformationAction Continue
							Write-Verbose -Message "OneDrive Installing" -Verbose

							Start-Process -FilePath $env:SystemRoot\SysWOW64\OneDriveSetup.exe
						}
						else
						{
							$Script:OneDriveInstalled = $false
						}
					}
				}

				if (-not $Script:OneDriveInstalled)
				{
					Write-Information -MessageData "" -InformationAction Continue
					Write-Verbose -Message "OneDrive Downloading" -Verbose

					# Parse XML to get the URL
					# https://go.microsoft.com/fwlink/p/?LinkID=844652
					$Parameters = @{
						Uri             = "https://g.live.com/1rewlive5skydrive/OneDriveProductionV2"
						UseBasicParsing = $true
						Verbose         = $true
					}
					$Content = Invoke-RestMethod @Parameters

					# Remove invalid chars
					[xml]$OneDriveXML = $Content -replace "ï»¿", ""

					$OneDriveURL = ($OneDriveXML).root.update.amd64binary.url | Select-Object -Index 1
					$DownloadsFolder = Get-ItemPropertyValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "{374DE290-123F-4565-9164-39C4925E467B}"
					$Parameters = @{
						Uri     = $OneDriveURL
						OutFile = "$DownloadsFolder\OneDriveSetup.exe"
						Verbose = $true
					}
					Invoke-WebRequest @Parameters

					Start-Process -FilePath "$DownloadsFolder\OneDriveSetup.exe" -Wait
					Remove-Item -Path "$DownloadsFolder\OneDriveSetup.exe" -Force
				}

				Get-ScheduledTask -TaskName "Onedrive* Update*" | Enable-ScheduledTask | Start-ScheduledTask
			}
		}
		Outlook
		{
			$Node = $Config.SelectSingleNode("//ExcludeApp[@ID='Outlook']")
			$Node.ParentNode.RemoveChild($Node)
		}
		Word
		{
			$Node = $Config.SelectSingleNode("//ExcludeApp[@ID='Word']")
			$Node.ParentNode.RemoveChild($Node)
		}
		PowerPoint
		{
			$Node = $Config.SelectSingleNode("//ExcludeApp[@ID='PowerPoint']")
			$Node.ParentNode.RemoveChild($Node)
		}
		Teams
		{
			$Node = $Config.SelectSingleNode("//ExcludeApp[@ID='Teams']")
			$Node.ParentNode.RemoveChild($Node)
		}
	}
}

$Config.Save("$PSScriptRoot\Config.xml")

# Microsoft blocks Russian and Belarusian regions for Office downloading
# https://docs.microsoft.com/en-us/windows/win32/intl/table-of-geographical-locations
# https://en.wikipedia.org/wiki/2022_Russian_invasion_of_Ukraine
if (((Get-WinHomeLocation).GeoId -eq "203") -or ((Get-WinHomeLocation).GeoId -eq "29"))
{
	# Set to Ukraine
	$Script:Region = (Get-WinHomeLocation).GeoId
	Set-WinHomeLocation -GeoId 241
	Write-Warning -Message "Region changed to Ukrainian"

	$Script:RegionChanged = $true
}

# It is needed to remove these keys to bypass Russian and Belarusian region blocks
Remove-Item -Path HKCU:\SOFTWARE\Microsoft\Office\16.0\Common\Experiment -Recurse -Force -ErrorAction Ignore
Remove-Item -Path HKCU:\SOFTWARE\Microsoft\Office\16.0\Common\ExperimentConfigs -Recurse -Force -ErrorAction Ignore
Remove-Item -Path HKCU:\SOFTWARE\Microsoft\Office\16.0\Common\ExperimentEcs -Recurse -Force -ErrorAction Ignore

# Download Office Deployment Tool
# https://www.microsoft.com/en-us/download/details.aspx?id=49117
if (-not (Test-Path -Path "$PSScriptRoot\setup.exe"))
{
	$Parameters = @{
		Uri              = "https://www.microsoft.com/en-us/download/confirmation.aspx?id=49117"
		UseBasicParsing  = $true
	}
	$ODTURL = ((Invoke-WebRequest @Parameters).Links | Where-Object {$_.outerHTML -match "click here to download manually"}).href
	$Parameters = @{
		Uri             = $ODTURL
		OutFile         = "$PSScriptRoot\officedeploymenttool.exe"
		UseBasicParsing = $true
		Verbose         = $true
	}
	Invoke-WebRequest @Parameters

	# Expand officedeploymenttool.exe
	Start-Process "$PSScriptRoot\officedeploymenttool.exe" -ArgumentList "/quiet /extract:`"$PSScriptRoot\officedeploymenttool`"" -Wait

	$Parameters = @{
		Path        = "$PSScriptRoot\officedeploymenttool\setup.exe"
		Destination = "$PSScriptRoot"
		Force       = $true
	}
	Move-Item @Parameters

	Start-Sleep -Seconds 1

	Remove-item -Path "$PSScriptRoot\officedeploymenttool", "$PSScriptRoot\officedeploymenttool.exe" -Recurse -Force
}

# Start downloading to the Office folder
Start-Process -FilePath "$PSScriptRoot\setup.exe" -ArgumentList "/download `"$PSScriptRoot\Config.xml`"" -Wait

if ($Script:RegionChanged)
{
	# Set to original region ID
	Set-WinHomeLocation -GeoId $Script:Region
	Write-Warning -Message "Region changed to original one"
}
