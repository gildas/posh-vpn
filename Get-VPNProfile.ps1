function Get-AnyConnectProfile() # {{{
{
  [CmdletBinding()]
  Param(
  )
  Write-Verbose "Starting the AnyConnect cli"
  $vpncli = New-Object System.Diagnostics.Process
  $vpncli.StartInfo = New-Object System.Diagnostics.ProcessStartInfo(Get-AnyConnect)
  $vpncli.StartInfo.Arguments = "hosts"
  $vpncli.StartInfo.CreateNoWindow  = $false
  $vpncli.StartInfo.UseShellExecute = $false
  $vpncli.StartInfo.RedirectStandardOutput = $true
  $vpncli.StartInfo.RedirectStandardError  = $true
  $vpncli.Start() | Out-Null

  $profiles = @()
  Write-Verbose "Reading its output"
  for ($output = $vpncli.StandardOutput.ReadLine(); $output -ne $null; $output = $vpncli.StandardOutput.ReadLine())
  {
      Write-Debug $output
      if ($output -match '  >> note: (.*)')
      {
        Write-Warning $matches[1]
        $status = 'Note'
      }
      elseif ($output -match '.*\[hosts\]')
      {
        Write-Verbose "Found VPN profiles:"
      }
      elseif ($output -match '.*> (.*)')
      {
        Write-Verbose "  Adding $($matches[1])"
        $profiles += $matches[1]
      }
  }
  for ($output = $vpncli.StandardError.ReadLine(); $output -ne $null; $output = $vpncli.StandardError.ReadLine())
  {
      Write-Warning $output
  }
  return $profiles
} #}}}

function Get-VPNProfile() # {{{
{
  [CmdletBinding()]
  Param(
    [Parameter(Position=1, Mandatory=$true)]
    [ValidateSet('AnyConnect')]
    [string] $Type
  )
  $PSBoundParameters.Remove('Type') | Out-Null
  switch($Type)
  {
    'AnyConnect' { Get-AnyConnectProfile @PSBoundParameters }
    default      { Throw "Unsupported VPN Type: $Type" }
  }
} # }}}
