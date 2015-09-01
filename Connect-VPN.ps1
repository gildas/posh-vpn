function Connect-AnyConnect() # {{{
{
  [CmdletBinding()]
  Param(
    [Parameter(Position=1, Mandatory=$true)]
    [Alias("Server")]
    [string] $ComputerName,
    [Parameter(Position=2, Mandatory=$true)]
    [Alias("Username")]
    [string] $User,
    [Parameter(Position=3, Mandatory=$true)]
    [string] $Password
  )
  $AnyConnectPath = Join-Path ${env:ProgramFiles(x86)} (Join-Path 'Cisco' 'Cisco AnyConnect Secure Mobility Client')

  # Disconnect as needed
  if ((Get-AnyConnectStatus -Verbose:$Verbose) -ne 'Disconnected')
  {
    Disconnect-AnyConnect -Verbose:$Verbose
  }

  # First Stop any VPN cli and ui
  # There must be only one "client" running when connecting
  Get-Process | Where ProcessName -match 'vpn(ui|cli)' | ForEach {
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

  Write-Verbose "Starting the AnyConnect cli"
  $vpncli = New-Object System.Diagnostics.Process
  $vpncli.StartInfo = New-Object System.Diagnostics.ProcessStartInfo(Join-Path $AnyConnectPath 'vpncli.exe')
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
  $vpncli.StandardInput.WriteLine('connect ' + $ComputerName)

  Write-Verbose "Sending user"
  $vpncli.StandardInput.WriteLine($User)

  Write-Verbose "Sending password"
  $vpncli.StandardInput.WriteLine($Password)

  Write-Verbose "Reading its output stream"
  $found = $false
  for ($output = $vpncli.StandardOutput.ReadLine(); $output -ne $null; $output = $vpncli.StandardOutput.ReadLine())
  {
    Write-Debug $output
    if ($output -match '  >> note: (.*)')
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
  Start-Process -FilePath (Join-Path $AnyConnectPath 'vpnui.exe')
} #}}}

function Connect-VPN() # {{{
{
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('AnyConnect')]
    [string] $Type,
    [Parameter(Position=1, Mandatory=$true)]
    [Alias("Server")]
    [string] $ComputerName,
    [Parameter(Position=2, Mandatory=$true)]
    [Alias("Username")]
    [string] $User,
    [Parameter(Position=3, Mandatory=$true)]
    [string] $Password
  )
  $PSBoundParameters.Remove('Type')
  switch($Type)
  {
    'AnyConnect' { Connect-AnyConnect @PSBoundParameters }
    default      { Throw "Unsupported VPN Type: $Type" }
  }
} # }}}
