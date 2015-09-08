function Get-AnyConnectProfile() # {{{
{
  [CmdletBinding()]
  [OutputType([string[]])]
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

<#
.SYNOPSIS
  Displays all profiles/Computers that can be used with a given Provider

.DESCRIPTION
  Displays all profiles/Computers that can be used with a given Provider

.NOTES
  Only Cisco AnyConnect VPNs are supported as of now.

.PARAMETER Provider
  The VPN Provider to use.
  One of: AnyConnect

.OUTPUTS
  System.String[]
  The list of profiles, servers that can be connected to from the local computer.

.LINK
  https://github.com/gildas/posh-vpn

.EXAMPLE
  $session = Get-VPNProfile -Provider AnyConnect
  vpn.acme.com

  Description
  -----------
  Gives the list of servers the user can connect to
#>
function Get-VPNProfile() # {{{
{
  [CmdletBinding()]
  [OutputType([string[]])]
  Param(
    [Parameter(Position=1, Mandatory=$true)]
    [ValidateSet('AnyConnect')]
    [string] $Provider
  )
  $PSBoundParameters.Remove('Provider') | Out-Null
  switch($Provider)
  {
    'AnyConnect' { Get-AnyConnectProfile @PSBoundParameters }
    default      { Throw "Unsupported VPN Provider: $Provider" }
  }
} # }}}
