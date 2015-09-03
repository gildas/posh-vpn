function Get-AnyConnectStatus() # {{{
{
  [CmdletBinding()]
  [OutputType([string])]
  Param(
    [Parameter(Mandatory=$false)]
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

<#
.SYNOPSIS
  Gets the current status of a VPN Session or a Provider.

.DESCRIPTION
  Gets the current status of a VPN Session or a Provider.

.NOTES
  Only Cisco AnyConnect VPNs are supported as of now.

.PARAMETER Provider
  The VPN Provider to use.
  One of: AnyConnect

.PARAMETER VPNSession
  The VPN session object returned by Connect-VPN.

.OUTPUTS
  System.String
  The current status of the VPN Session of the Provider.
  With AnyConnect, the values are typically: Connected, Disconnected, Unknown.

.LINK
  https://github.com/gildas/posh-vpn

.EXAMPLE
  $session = Connect-VPN -Provider AnyConnect -ComputerName vpn.acme.com -Credentials (Get-Credential ACME\gildas)

  Get-VPNStatus $session
  Connected

  Description
  -----------
  Gets the connection of a session

.EXAMPLE
  Get-VPNStatus -Provider AnyConnect
  Disconnected

  Description
  -----------
  Gets the status of Cisco AnyConnect VPN
#>
function Get-VPNStatus() # {{{
{
  [CmdletBinding(DefaultParameterSetName='Session')]
  [OutputType([string])]
  Param(
    [Parameter(Position=1, ParameterSetName='Session', Mandatory=$true)]
    [PSCustomObject] $VPNSession,
    [Parameter(Position=1, ParameterSetName='Provider', Mandatory=$true)]
    [ValidateSet('AnyConnect')]
    [string] $Provider
  )
  switch($PSCmdlet.ParameterSetName)
  {
    'Session'
    {
      switch($VPNSession.Provider)
      {
        'AnyConnect' { Get-AnyConnectStatus @PSBoundParameters }
        $null        { Throw [System.ArgumentException] "VPNSession misses a Provider"; } 
        default      { Throw "Unsupported VPN Type: $VPNSession.Provider" }
      }
    }
    'Provider'
    {
      $PSBoundParameters.Remove('Provider') | Out-Null
      switch($Provider)
      {
        'AnyConnect' { Get-AnyConnectStatus @PSBoundParameters }
        default      { Throw "Unsupported VPN Type: $VPNSession.Provider" }
      }
    }
  }
} # }}}
