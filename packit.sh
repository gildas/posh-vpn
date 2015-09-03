#!/usr/bin/env bash

VERSION=$(cat VERSION)
if [[ -z $(grep $VERSION Install.ps1) ]]; then
  echo "Updating Install.ps1 to point to version $VERSION"
  sed -i.bak -e "s/^\(\$ModuleVersion = '\).*\('\)/\1${VERSION}\2/" Install.ps1
else
  echo "Install already points to version $VERSION"
fi
zip -9  ~/Downloads/posh-vpn-${VERSION}.zip Install.ps1 Posh-VPN.psd1 Posh-VPN.psm1
