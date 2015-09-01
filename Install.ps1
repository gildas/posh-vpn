[CmdletBinding()]
Param(
  [Parameter(Position=1, Mandatory=$false)]
  $Path
)

if ([string]::IsNullOrEmpty($Path))
{
  $my_modules   = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'WindowsPowerShell\Modules'
  $module_paths = @($env:PSModulePath -split ';')

  if (! (Test-Path $my_modules))
  {
    Write-Verbose "Creating Personal Powershell Module folder"
    New-Item -ItemType Directory -Path $my_modules -ErrorAction Stop | Out-Null
  }

  if ($module_paths -notcontains $my_modules)
  {
    Write-Verbose "Adding Personal Powershell Module folder to Module Search list"
    $env:PSModulePath = $my_modules + ';' + $env:PSModulePath
    [Environment]::SetEnvironmentVariable('PSModulePath', $env:PSModulePath, 'User')
  }
  $Path = Join-Path $my_modules 'Posh-VPN'
}

if (! (Test-Path $Path))
{
  Write-Verbose "Creating Posh-VPN Module folder"
  New-Item -ItemType Directory -Path $Path -ErrorAction Stop | Out-Null
}

@(
  'Get-AnyConnect.ps1',
  'Get-VPNProfile.ps1',
  'Get-VPNStatus.ps1',
  'Disconnect-VPN.ps1',
  'Connect-VPN.ps1',
  'LICENSE',
  'README.md',
  'Posh-VPN.psd1',
  'Posh-VPN.psm1'
) | ForEach-Object {
  Start-BitsTransfer -DisplayName "Posh-VPN Installation" -Description "Installing $_" -Source "https://raw.githubusercontent.com/gildas/posh-vpn/master/$_" -Destination $Path -ErrorAction Stop
}
