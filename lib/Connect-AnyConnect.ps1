
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

  # Get the current AnyConnec status
  #$process = Start-Process -FilePath (Join-Path $AnyConnectPath 'vpncli.exe') -ArgumentList "state" -WindowStyle Minimized -PassThru
  # Must be " >> stazte: Disconnected"
  # If not disconnect
  Disconnect-AnyConnect

  # First Stop any VPN cli and ui
  # There must be only one "client" running when connecting
  Get-Process | Where ProcessName -match 'vpn(ui|cli)' | ForEach { Stop-Process $_.Id }

  Write-Verbose "Starting the VPN cli"
  $vpncli = New-Object System.Diagnostics.Process
  $vpncli.StartInfo = New-Object System.Diagnostics.ProcessStartInfo(Join-Path $AnyConnectPath 'vpncli.exe')
  $vpncli.StartInfo.Arguments = "connect ${ComputerName}"
  $vpncli.StartInfo.CreateNoWindow  = $false
  $vpncli.StartInfo.UseShellExecute = $false
  $vpncli.StartInfo.RedirectStandardInput  = $true
  $vpncli.StartInfo.RedirectStandardOutput = $true
  $vpncli.StartInfo.RedirectStandardError  = $true
  $vpncli.Start()

  Write-Verbose "Waiting for process to be ready"
  Start-Sleep 2

  Write-Verbose "Reading its output"
  for ($output = $vpncli.StandardOutput.ReadLine(); $output -ne $null; $output = $vpncli.StandardOutput.ReadLine())
  {
      Write-Verbose $output
  }
  for ($output = $vpncli.StandardError.ReadLine(); $output -ne $null; $output = $vpncli.StandardError.ReadLine())
  {
      Write-Verbose $output
  }
  #Write-Verbose "Sending connect command"
  #$vpncli.StandardInput.WriteLine("connect ${ComputerName}")
  #Write-Verbose "Reading its output"
  #for ($output = $vpncli.StandardOutput.ReadLine(); $output -notmatch "^VPN>.*"; $output = $vpncli.StandardOutput.ReadLine())
  #{
  #  Write-Verbose $output
  #}
  Start-Sleep 2
  Write-Verbose "Sending user"
  $vpncli.StandardInput.WriteLine($User)
  Write-Verbose "Reading its output"
  for ($output = $vpncli.StandardOutput.ReadLine(); $output -ne $null; $output = $vpncli.StandardOutput.ReadLine())
  {
    Write-Verbose $output
  }
  Write-Verbose "Sending password"
  $vpncli.StandardInput.WriteLine($Password)
  Write-Verbose "Reading its output"
  for ($output = $vpncli.StandardOutput.ReadLine(); $output -ne $null; $output = $vpncli.StandardOutput.ReadLine())
  {
    Write-Verbose $output
  }
  # Read StandardOutput.ReadLine()
  # until:
  #VPN>
  #  >> registered with local VPN subsystem.
  #
  #
  #VPN>
  # until ReadLine() is $null

  Start-Process -FilePath (Join-Path $AnyConnectPath 'vpnui.exe')
  return $vpncli
} #}}}

#VPN> connect indvpn.inin.com
#  >> contacting host (indvpn.inin.com) for login information...
#  >> notice: Contacting indvpn.inin.com.
#
#  >> Please enter your username and password.
#
#Username: [apac\gildas.cherruel]
#Password: **********
#  >> notice: Establishing VPN session...
#  >> notice: Checking for profile updates...
#  >> notice: Checking for product updates...
#  >> notice: Checking for customization updates...
#  >> notice: Performing any required updates...
#  >> notice: Establishing VPN - Examining system...
#  >> notice: Establishing VPN - Activating VPN adapter...
#  >> state: Connecting
#  >> notice: Establishing VPN session...
#  >> notice: Establishing VPN - Configuring system...
#  >> notice: Establishing VPN...
#  >> state: Connected
#  >> notice: Connected to indvpn.inin.com.
