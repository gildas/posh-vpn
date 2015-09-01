function Disconnect-AnyConnect() # {{{
{
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$false)]
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

<#
.SYNOPSIS
  Disconnect from a VPN Session or Provider.

.DESCRIPTION
  Disconnect this computer from a given VPN Session or Provider.

.NOTES
  Only Cisco AnyConnect VPNs are supported as of now.

.PARAMETER Provider
  The VPN Provider to use.
  One of: AnyConnect

.PARAMETER VPNSession
  The VPN session object returned by Connect-VPN.

.LINK
  https://github.com/gildas/posh-vpn

.EXAMPLE
  $session = Connect-VPN -Provider AnyConnect -ComputerName vpn.acme.com -Credentials (Get-Credential ACME\gildas)

  Disconnect-VPN $session

  Description
  -----------
  Disconnects from a Cisco AnyConnect VPN session

.EXAMPLE
  Disconnect-VPN -Provider AnyConnect

  Description
  -----------
  Disconnects from any Cisco AnyConnect VPN
#>
function Disconnect-VPN() # {{{
{
  [CmdletBinding(DefaultParameterSetName='Session')]
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
        'AnyConnect' { Disconnect-AnyConnect @PSBoundParameters }
        $null        { Throw [System.ArgumentException] "VPNSession misses a Provider"; } 
        default      { Throw "Unsupported VPN Type: $VPNSession.Provider" }
      }
    }
    'Provider'
    {
      $PSBoundParameters.Remove('Provider') | Out-Null
      switch($Provider)
      {
        'AnyConnect' { Disconnect-AnyConnect @PSBoundParameters }
        default      { Throw "Unsupported VPN Type: $VPNSession.Provider" }
      }
    }
  }
} # }}}
