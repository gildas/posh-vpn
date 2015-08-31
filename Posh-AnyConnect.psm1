if (Get-Module Posh-AnyConnect) { return }

if ($PSVersionTable.PSVersion.Major -lt 3)
{
  Write-Error "Posh-IC work only on Powershell 3.0 and higher"
  exit
}

Push-Location $PSScriptRoot
. .\Get-AnyConnectStatus.ps1
. .\Disconnect-AnyConnect.ps1
. .\Connect-AnyConnect.ps1
Pop-Location

Export-ModuleMember `
  -Function @(
    'Get-AnyConnectStatus',
    'Connect-AnyConnect',
    'Disconnect-AnyConnect'
  )