#!/usr/bin/env bash
# 环境自检：在你开始折腾 Xcode 之前，先确认这台 Mac 该有的都有。
set -uo pipefail

FAIL=0
ok()   { printf "  \033[32m✓\033[0m %s\n" "$*"; }
bad()  { printf "  \033[31m✗\033[0m %s\n" "$*"; FAIL=$((FAIL+1)); }
warn() { printf "  \033[33m!\033[0m %s\n" "$*"; }

echo "== 平台 =="
if [[ "$(uname -s)" == "Darwin" ]]; then
  ok "macOS $(sw_vers -productVersion)"
else
  bad "不是 macOS，无法构建 iOS 应用"
fi

echo
echo "== 开发者工具 =="
if xcode-select -p >/dev/null 2>&1; then
  ok "Xcode 路径：$(xcode-select -p)"
else
  bad "未安装 Xcode 命令行工具，运行：xcode-select --install"
fi

if command -v xcodebuild >/dev/null 2>&1; then
  VER=$(xcodebuild -version 2>/dev/null | head -1)
  ok "$VER"
else
  bad "找不到 xcodebuild，请从 App Store 安装 Xcode"
fi

# 检查 SDK 版本是否 >= 18.0（项目 deploymentTarget 是 iOS 18.0）
if command -v xcodebuild >/dev/null 2>&1; then
  SDS=$(xcodebuild -showsdks 2>/dev/null | grep -o 'iphoneos[0-9.]*' | head -1 | sed 's/iphoneos//')
  if [[ -n "${SDS:-}" ]]; then
    MAJOR="${SDS%%.*}"
    if [[ "$MAJOR" -ge 18 ]]; then
      ok "iOS SDK $SDS（满足 >= 18.0）"
    else
      bad "iOS SDK $SDS 太旧，项目需要 18.0+"
    fi
  else
    warn "读不到 iOS SDK 版本"
  fi
fi

echo
echo "== 工具 =="
if command -v xcodegen >/dev/null 2>&1; then
  ok "XcodeGen $(xcodegen --version 2>/dev/null | head -1)"
else
  bad "未安装 XcodeGen，运行：brew install xcodegen"
fi

if command -v brew >/dev/null 2>&1; then
  ok "Homebrew $((brew --version 2>/dev/null) | head -1 | cut -d' ' -f2)"
else
  warn "未安装 Homebrew（装 XcodeGen 会用到）"
fi

echo
echo "== 签名 =="
if security find-identity -v -p codesigning 2>/dev/null | grep -q "Apple Development\|Apple Distribution"; then
  ok "找到代码签名证书"
  security find-identity -v -p codesigning 2>/dev/null | grep "Apple Development\|Apple Distribution" | sed 's/^/      /'
else
  warn "未找到签名证书。首次构建请在 Xcode → Settings → Accounts 登录 Apple ID，"
  warn "然后为 EarTimer 与 EarTimerWidgets 两个 target 选择 Team（免费 Personal Team 也能真机调试）"
fi

echo
echo "== 结论 =="
if [[ "$FAIL" -eq 0 ]]; then
  printf "\033[32m环境就绪。运行 ./build.sh 开始。\033[0m\n"
else
  printf "\033[31m有 %d 项需要先解决（见上）。\033[0m\n" "$FAIL"
  exit 1
fi
