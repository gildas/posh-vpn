function Disconnect-AnyConnect() # {{{
{
  [CmdletBinding()]
  Param(
  )
  $AnyConnectPath = Join-Path ${env:ProgramFiles(x86)} (Join-Path 'Cisco' 'Cisco AnyConnect Secure Mobility Client')

  Write-Verbose "Starting the VPN cli"
  $vpncli = New-Object System.Diagnostics.Process
  $vpncli.StartInfo = New-Object System.Diagnostics.ProcessStartInfo(Join-Path $AnyConnectPath 'vpncli.exe')
  $vpncli.StartInfo.Arguments = "disconnect"
  $vpncli.StartInfo.CreateNoWindow  = $false
  $vpncli.StartInfo.UseShellExecute = $false
  $vpncli.StartInfo.RedirectStandardOutput = $true
  $vpncli.StartInfo.RedirectStandardError  = $true
  $vpncli.Start() | Out-Null

  Write-Verbose "Reading its output"
  for ($output = $vpncli.StandardOutput.ReadLine(); $output -ne $null; $output = $vpncli.StandardOutput.ReadLine())
  {
      Write-Verbose "OUTPUT: $output"
  }
  for ($output = $vpncli.StandardError.ReadLine(); $output -ne $null; $output = $vpncli.StandardError.ReadLine())
  {
      Write-Verbose "ERROR:  $output"
  }
} #}}}
