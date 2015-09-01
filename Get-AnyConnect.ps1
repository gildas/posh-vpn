function Get-AnyConnect() # {{{
 {
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$false)]
    [Alias('ui', 'graphics')]
    [switch] $gui
  )

  $AnyConnectPath = Join-Path ${env:ProgramFiles(x86)} (Join-Path 'Cisco' 'Cisco AnyConnect Secure Mobility Client')
  if (Test-Path $AnyConnectPath)
  {
    if ($gui) { $application = 'vpnui.exe' } else { $application = 'vpncli.exe' }
    return (Join-Path $AnyConnectPath $application)
  }
  Throw [System.IO.FileNotFoundException] "AnyConnect is not installed"
 } # }}}
