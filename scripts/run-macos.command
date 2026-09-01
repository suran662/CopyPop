#!/bin/zsh
set -e

cd "${0:A:h}/.."

LANGUAGE="${1:-zh-CN}"

if ! command -v swiftc >/dev/null 2>&1; then
  echo "Xcode Command Line Tools are required."
  echo "Install them by running: xcode-select --install"
  read -k 1 "?Press any key to exit..."
  exit 1
fi

./scripts/build-macos.command "$LANGUAGE"
open "./build/macOS/$LANGUAGE/CopyPop.app"
