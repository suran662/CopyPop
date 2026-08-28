#!/bin/zsh
set -e

cd "${0:A:h}/.."

APP="./build/macOS/CopyPop.app"
BIN="$APP/Contents/MacOS/CopyPop"
MODULE_CACHE="$(mktemp -d "${TMPDIR:-/tmp}/copypop-module-cache.XXXXXX")"
trap 'rm -rf "$MODULE_CACHE"' EXIT

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "./macos/Info.plist" "$APP/Contents/Info.plist"

export CLANG_MODULE_CACHE_PATH="$MODULE_CACHE"
swiftc -O -framework AppKit "./macos/CopyPop.swift" -o "$BIN"
chmod +x "$BIN"
codesign --force --deep --sign - "$APP"

echo "已构建：$APP"
