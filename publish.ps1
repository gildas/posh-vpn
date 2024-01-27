$ModulePath = "$PSScriptRoot\posh-vpn"
Publish-Module -Path $ModulePath -NuGetApiKey $Env:NUGET_APIKEY
