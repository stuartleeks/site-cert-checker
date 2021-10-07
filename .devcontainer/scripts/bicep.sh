#!/bin/bash
set -e

get_latest_release() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" |
  grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/'
}

VERSION=${1:-"$(get_latest_release Azure/bicep)"}
INSTALL_DIR=${2:-"$HOME/.local/bin"}
CMD=bicep
NAME="Azure Bicep"

echo -e "\e[34m»»» 📦 \e[32mInstalling \e[33m$NAME \e[35mv$VERSION\e[0m ..."

mkdir -p $INSTALL_DIR
curl -sSL https://github.com/Azure/bicep/releases/download/v$VERSION/bicep-linux-x64 -o $INSTALL_DIR/bicep
chmod +x $INSTALL_DIR/bicep

echo -e "\n\e[34m»»» 💾 \e[32mInstalled to: \e[33m$(which $CMD)"
echo -e "\e[34m»»» 💡 \e[32mVersion details: \e[39m$($CMD --version)"