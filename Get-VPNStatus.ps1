function Get-AnyConnectStatus() # {{{
{
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$true)]
    [PSCustomObject] $VPNSession
  )
  Write-Verbose "Starting the AnyConnect cli"
  $vpncli = New-Object System.Diagnostics.Process
  $vpncli.StartInfo = New-Object System.Diagnostics.ProcessStartInfo(Get-AnyConnect)
  $vpncli.StartInfo.Arguments = "state"
  $vpncli.StartInfo.CreateNoWindow  = $false
  $vpncli.StartInfo.UseShellExecute = $false
  $vpncli.StartInfo.RedirectStandardOutput = $true
  $vpncli.StartInfo.RedirectStandardError  = $true
  $vpncli.Start() | Out-Null

  $status = 'Unknown'
  Write-Verbose "Reading its output"
  for ($output = $vpncli.StandardOutput.ReadLine(); $output -ne $null; $output = $vpncli.StandardOutput.ReadLine())
  {
      Write-Debug $output
      if ($output -match '  >> note: (.*)')
      {
        Write-Warning $matches[1]
        $status = 'Note'
      }
      if ($output -match '  >> state: (.*)')
      {
        $status = $matches[1]
        Write-Verbose $status
      }
  }
  for ($output = $vpncli.StandardError.ReadLine(); $output -ne $null; $output = $vpncli.StandardError.ReadLine())
  {
      Write-Warning $output
  }
  return $status
} #}}}

function Get-VPNStatus() # {{{
{
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$true)]
    [PSCustomObject] $VPNSession
  )
  switch($VPNSession.Type)
  {
    'AnyConnect' { Get-AnyConnectStatus @PSBoundParameters }
    $null        { Throw [System.ArgumentException] "VPNSession misses a Type"; } 
    default      { Throw "Unsupported VPN Type: $VPNSession.Type" }
  }
} # }}}
