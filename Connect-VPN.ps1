function Connect-AnyConnect() # {{{
{
  [CmdletBinding(DefaultParameterSetName='Credential')]
  [OutputType([PSCustomObject])]
  Param(
    [Parameter(Position=1, Mandatory=$true)]
    [Alias("Server")]
    [string] $ComputerName,
    [Parameter(Position=2, ParameterSetName='Credential', Mandatory=$true)]
    [System.Management.Automation.PSCredential] $Credential,
    [Parameter(Position=2, ParameterSetName='Plain', Mandatory=$true)]
    [Alias("Username")]
    [string] $User,
    [Parameter(Position=3, ParameterSetName='Plain', Mandatory=$true)]
    [string] $Password,
    [Parameter(Position=4, Mandatory=$false)]
    [switch] $AcceptNotice,
    [Parameter(Position=5, Mandatory=$false)]
    [int] $Timeout = 60
  )
  if ($PSCmdlet.ParameterSetName -eq 'Credential')
  {
    Write-Verbose "Loading PSCredentials"
    $User     = $Credential.UserName
    $Password = $Credential.GetNetworkCredential().password
  }
  else
  {
    $secret     = ConvertTo-SecureString $Password -AsPlainText -Force
    $Credential = New-Object System.Management.Automation.PSCredential($User, $secret)
    $secret     = $null
  }

  # Disconnect as needed
  $temp_session = [PSCustomObject] @{
    Provider='AnyConnect';
    ComputerName=$ComputerName;
    Credential=$Credential;
  }
  if ((Get-AnyConnectStatus -VPNSession $temp_session -Verbose:$false) -ne 'Disconnected')
  {
    Disconnect-AnyConnect -VPNSession $temp_session -Verbose:$Verbose
  }

  # First Stop any VPN cli and ui
  # There must be only one "client" running when connecting
  Get-Process | Where-Object ProcessName -match 'vpn(ui|cli)' | ForEach-Object {
    if (! $_.HasExited)
    {
      Write-Verbose "Stopping process $($_.Name) (pid: $($_.Id))"
      Stop-Process $_.Id
    }
    else
    {
      Write-Verbose "Process $($_.Name) is exiting (pid: $($_.Id))"
    }
  }

  Write-Debug "Starting AnyConnect to $ComputerName as $User (Password: $Password)"
  Write-Verbose "Starting the AnyConnect cli"
  $vpncli = New-Object System.Diagnostics.Process
  $vpncli.StartInfo = New-Object System.Diagnostics.ProcessStartInfo(Get-AnyConnect)
  $vpncli.StartInfo.Arguments = "-s"
  $vpncli.StartInfo.CreateNoWindow  = $true
  $vpncli.StartInfo.UseShellExecute = $false
  $vpncli.StartInfo.RedirectStandardInput  = $true
  $vpncli.StartInfo.RedirectStandardOutput = $true
  #$vpncli.StartInfo.RedirectStandardError  = $true

  if (! $vpncli.Start())
  {
    Throw "Cannot start AnyConnect Client, error: $LASTEXITCODE"
  }

  Write-Verbose "Waiting for process to be ready"
  Start-Sleep 2

  Write-Verbose "Sending connect"
  $vpncli.StandardInput.WriteLine('connect ' + """$ComputerName""")

  Write-Verbose "Sending user"
  $vpncli.StandardInput.WriteLine($User)

  Write-Verbose "Sending password"
  $vpncli.StandardInput.WriteLine($Password)

  If ( $AcceptNotice )
  {
    Write-Verbose "Accepting notice"
    $vpncli.StandardInput.WriteLine("y")
  }

  $timer = [Diagnostics.Stopwatch]::StartNew()
  Write-Verbose "Reading its output stream"
  for ($output = $vpncli.StandardOutput.ReadLine(); $null -ne $output -and $timer.Elapsed.TotalSeconds -lt $Timeout; $output = $vpncli.StandardOutput.ReadLine())
  {
    Write-Debug $output
    if ($output -eq '  >> Login failed.')
    {
      Throw [System.Security.Authentication.InvalidCredentialException]
    }
    elseif ($output -match '  >> note: (.*)')
    {
      Write-Warning $matches[1]
    }
    elseif ($output -match '  >> state: (.*)')
    {
      $state = $matches[1]
      Write-Verbose $state
      if ($state -eq 'Connected')
      {
        break
      }
    }
  }
  $timer.Stop()
  if ($timer.Elapsed.TotalSeconds -ge $Timeout)
  {
    Write-Error "Timeout ($Timeout seconds) while connecting to $ComputerName"
    return [PSCustomObject] @{}
  }
  Start-Process -FilePath (Get-Anyconnect -gui)

  return [PSCustomObject] @{
    Provider='AnyConnect';
    ComputerName=$ComputerName;
    Credential=$Credential;
  }
} #}}}

<#
.SYNOPSIS
  Connects to a VPN Provider.

.DESCRIPTION
  Connects this computer to a given VPN Provider.

.NOTES
  Only Cisco AnyConnect VPNs are supported as of now.

.PARAMETER Provider
  The VPN Provider to use.
  One of: AnyConnect

.PARAMETER ComputerName
  The ComputerName or VPN profile to use.
  The TAB completion will provide the list of possible values depending on the chosen Provider.

.PARAMETER Credential
  The PSCredential to use.

.PARAMETER User
  If no PSCredential is provided, a User and a (plain text) Password must be provided.

.PARAMETER Password
  If no PSCredential is provided, a User and a (plain text) Password must be provided.

.PARAMETER AcceptNotice
  Accept notice from the server, like a banner message.

.PARAMETER Timeout
  Maximum time in seconds to wait for the connection to be established.
  Default is 60 seconds.

.INPUTS
  The ComputerName can be piped in.

.OUTPUTS
  System.Management.Automation.PSObject
  Represents the VPN connection (its Provider, the ComputerName, and the Credential).

.LINK
  https://github.com/gildas/posh-vpn

.EXAMPLE
  $session = Connect-VPN -Provider AnyConnect -ComputerName vpn.acme.com -Credentials (Get-Credential ACME\gildas)

  Description
  -----------
  Connects to a Cisco AnyConnect VPN at vpn.acme.com with the PSCredential entered via Get-Credential

.EXAMPLE
  $session = Connect-VPN -Provider AnyConnect -ComputerName vpn.acme.com -User ACME\gildas -Password s3cr3t

  Description
  -----------
  Connects to a Cisco AnyConnect VPN at vpn.acme.com with the clear text user and password
#>
function Connect-VPN # {{{
{
  [CmdletBinding(DefaultParameterSetName='Credential')]
  [OutputType([PSCustomObject])]
  Param(
    [Parameter(Position=1, Mandatory=$true)]
    [ValidateSet('AnyConnect')]
    [string] $Provider,
    #[Parameter(Position=2, Mandatory=$true)]
    #[Alias("Server")]
    #[string] $ComputerName,
    [Parameter(Position=3, ParameterSetName='Credential', Mandatory=$true)]
    [System.Management.Automation.PSCredential] $Credential,
    [Parameter(Position=3, ParameterSetName='Plain', Mandatory=$true)]
    [Alias("Username")]
    [string] $User,
    [Parameter(Position=4, ParameterSetName='Plain', Mandatory=$true)]
    [string] $Password,
    [Parameter(Position=5, Mandatory=$false)]
    [switch] $AcceptNotice,
    [Parameter(Position=6, Mandatory=$false)]
    [int] $Timeout = 60
  )
  DynamicParam
  {
    $parameters = New-Object -Type System.Management.Automation.RuntimeDefinedParameterDictionary

    #[Parameter(Position=2, Mandatory=$true)]
    $attributes = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
    $parameter_attribute = New-Object -Type System.Management.Automation.ParameterAttribute
    $parameter_attribute.Position  = 2
    $parameter_attribute.Mandatory = $true
    $parameter_attribute.ValueFromPipeline = $true
    #$parameter_attribute.ParameterSetName = @('Credential', 'Plain')
    $attributes.Add($parameter_attribute)
    if ($Provider -eq 'AnyConnect')
    {
      #[ValidateSet(Get-VPNProfiles -Provider AnyConnect)]
      $vpnProfiles = Get-VPNProfile -Provider AnyConnect

      if($vpnProfiles -gt 0)
      {
          $validateset = New-Object -Type System.Management.Automation.ValidateSetAttribute($vpnProfiles)
          $attributes.Add($validateset)
      }
    }
    #[Alias("Server")]
    $aliases = New-Object -Type  System.Management.Automation.AliasAttribute(@('Server'))
    $attributes.Add($aliases)
    #[string] $ComputerName,
    $parameter = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("ComputerName", [string], $attributes)
    $parameters.Add('ComputerName', $parameter)

    return $parameters
  }
  process
  {
    $PSBoundParameters.Remove('Provider') | Out-Null
    switch($Provider)
    {
      'AnyConnect' { Connect-AnyConnect @PSBoundParameters }
      default      { Throw "Unsupported VPN Provider: $Provider" }
    }
  }
} # }}}
