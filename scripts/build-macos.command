#!/bin/zsh
set -e

cd "${0:A:h}/.."

LANGUAGE="${1:-zh-CN}"
SWIFT_FLAGS=()

case "$LANGUAGE" in
  zh-CN)
    BUNDLE_SUFFIX="zhcn"
    DEVELOPMENT_REGION="zh_CN"
    ;;
  en)
    BUNDLE_SUFFIX="en"
    DEVELOPMENT_REGION="en"
    SWIFT_FLAGS=(-D COPYPOP_ENGLISH)
    ;;
  *)
    echo "Usage: $0 [zh-CN|en]"
    exit 2
    ;;
esac

APP="./build/macOS/$LANGUAGE/CopyPop.app"
BIN="$APP/Contents/MacOS/CopyPop"
MODULE_CACHE="$(mktemp -d "${TMPDIR:-/tmp}/copypop-module-cache.XXXXXX")"
trap 'rm -rf "$MODULE_CACHE"' EXIT

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "./macos/Info.plist" "$APP/Contents/Info.plist"
plutil -replace CFBundleDevelopmentRegion -string "$DEVELOPMENT_REGION" "$APP/Contents/Info.plist"
plutil -replace CFBundleIdentifier -string "com.copypop.native.$BUNDLE_SUFFIX" "$APP/Contents/Info.plist"

export CLANG_MODULE_CACHE_PATH="$MODULE_CACHE"
swiftc -O "${SWIFT_FLAGS[@]}" -framework AppKit "./macos/CopyPop.swift" -o "$BIN"
chmod +x "$BIN"
codesign --force --deep --sign - "$APP"

echo "Built $LANGUAGE: $APP"
