# Posh-VPN
Powershell Module to use various VPN Providers.

Installation
------------

If you have [PsGet](http://psget.net) installed just run:
```posh
Install-Module Posh-VPN
```

Copy the following line and paste it in a Powershell:

```posh
Start-BitsTransfer http://tinyurl.com/posh-vpn-0-1-3 $env:TEMP ; & $env:TEMP\Install.ps1
```

To install the latest development version, use one of the followings:

```posh
Install-Module -ModuleUrl https://github.com/gildas/posh-vpn/archive/dev.zip
```

```posh
Start-BitsTransfer http://tinyurl.com/posh-vpn-dev $env:TEMP ; & $env:TEMP\Install.ps1
```



The following options are accepted:
- -Path  
  Contains the *path* where Posh-VPN will be installed.  
  When this parameter is not present, the module will be installed in WindowsPowerShell\Modules\Posh-VPN under the user's documents.  
  In general, you will not need this parameter as the default folder gets automatically added in the list of folders where Powershell searches for modules and loads them.  
  Default: None
- -Verbose
  Acts verbosely
- -WhatIf
  Shows what would be done 

Note
----

As of today, only Cisco AnyConnect (tm) is supported.  
It also has to be installed and configured before you can use this module.

Usage
-----

To connect to a VPN:
```posh
PS> $vpn = Connect-VPN -Provider AnyConnect -ComputerName vpn.acme.com -User gildas -Password 's3cr3t'
```

It is also possible to use a PSCredential object:
```posh
PS> $creds = Get-Credential ACME\gildas
PS> $vpn = Connect-VPN -Provider AnyConnect -ComputerName vpn.acme.com -Credential $creds
```

In both cases, you can use the TAB completion for the ComputerName. The values come from the available profiles/servers/connections for the given provider.

To get the status of a VPN session:
```posh
PS> Get-VPNStatus $vpn
Connected
```

To disconnect a VPN session:
```posh
PS> Disconnect-VPN $vpn
```

To get the list of the available profiles/severs/connections for a given provider:
```posh
PS> Get-VPNProfile -Provider AnyConnect
vpn.acme.com
```

AUTHORS
=======
[![endorse](https://api.coderwall.com/gildas/endorsecount.png)](https://coderwall.com/gildas)
