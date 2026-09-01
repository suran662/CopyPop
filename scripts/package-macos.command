#!/bin/zsh
set -e

cd "${0:A:h}/.."

ARCH="$(uname -m)"
for LANGUAGE in zh-CN en; do
  ./scripts/build-macos.command "$LANGUAGE"
  APP="./build/macOS/$LANGUAGE/CopyPop.app"
  ZIP="./build/CopyPop-macOS-$ARCH-$LANGUAGE.zip"
  rm -f "$ZIP"
  ditto -c -k --sequesterRsrc --keepParent "$APP" "$ZIP"
  echo "Packaged: $ZIP"
done
