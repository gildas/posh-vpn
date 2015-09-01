function Disconnect-AnyConnect() # {{{
{
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$true)]
    [PSCustomObject] $VPNSession
  )
  Write-Verbose "Starting the VPN cli"
  $vpncli = New-Object System.Diagnostics.Process
  $vpncli.StartInfo = New-Object System.Diagnostics.ProcessStartInfo(Get-AnyConnect)
  $vpncli.StartInfo.Arguments = "disconnect"
  $vpncli.StartInfo.CreateNoWindow  = $false
  $vpncli.StartInfo.UseShellExecute = $false
  $vpncli.StartInfo.RedirectStandardOutput = $true
  $vpncli.StartInfo.RedirectStandardError  = $true
  $vpncli.Start() | Out-Null

  Write-Verbose "Reading its output"
  for ($output = $vpncli.StandardOutput.ReadLine(); $output -ne $null; $output = $vpncli.StandardOutput.ReadLine())
  {
    Write-Debug $output
    if ($output -match '  >> note: (.*)')
    {
      Write-Warning $matches[1]
    }
    elseif ($output -match '  >> state: (.*)')
    {
      Write-Verbose $matches[1]
    }
  }
  for ($output = $vpncli.StandardError.ReadLine(); $output -ne $null; $output = $vpncli.StandardError.ReadLine())
  {
      Write-Warning $output
  }
} #}}}

function Disconnect-VPN() # {{{
{
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$true)]
    [PSCustomObject] $VPNSession
  )
  switch($VPNSession.Provider)
  {
    'AnyConnect' { Disconnect-AnyConnect @PSBoundParameters }
    $null        { Throw [System.ArgumentException] "VPNSession misses a Type"; } 
    default      { Throw "Unsupported VPN Type: $VPNSession.Provider" }
  }
} # }}}
