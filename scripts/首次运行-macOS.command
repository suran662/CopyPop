#!/bin/zsh
set -e

cd "${0:A:h}/.."

if ! command -v swiftc >/dev/null 2>&1; then
  echo "需要先安装 Xcode Command Line Tools。"
  echo "可以在终端运行：xcode-select --install"
  read -k 1 "?按任意键退出..."
  exit 1
fi

./scripts/构建-macOS.command
open "./build/macOS/CopyPop.app"
