#!/usr/bin/env bash
# EarTimer 一键构建脚本（在 macOS 上运行）
#
# 用法：
#   ./build.sh              # 生成工程并打开 Xcode
#   ./build.sh gen          # 只生成 .xcodeproj
#   ./build.sh archive      # 编译并导出 .ipa（需要已配置签名）
#   ./build.sh clean        # 清理生成物

set -euo pipefail

PROJECT_NAME="EarTimer"
SCHEME="EarTimer"
BUILD_DIR="build"
EXPORT_DIR="build/export"

red()   { printf "\033[31m%s\033[0m\n" "$*"; }
green() { printf "\033[32m%s\033[0m\n" "$*"; }
info()  { printf "\033[36m%s\033[0m\n" "$*"; }

require_macos() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    red "错误：iOS 应用只能在 macOS 上构建（当前：$(uname -s)）"
    exit 1
  fi
}

require_xcodegen() {
  if ! command -v xcodegen >/dev/null 2>&1; then
    red "未安装 XcodeGen。请先运行："
    echo "    brew install xcodegen"
    exit 1
  fi
}

generate() {
  require_xcodegen
  info "生成 $PROJECT_NAME.xcodeproj ..."
  xcodegen generate
  green "完成。现在可以：open $PROJECT_NAME.xcodeproj"
}

open_xcode() {
  generate
  open "$PROJECT_NAME.xcodeproj"
}

cmd="${1:-open}"

require_macos

case "$cmd" in
  gen)
    generate
    ;;

  open)
    open_xcode
    ;;

  archive)
    generate
    info "编译 Release ..."
    xcodebuild \
      -project "$PROJECT_NAME.xcodeproj" \
      -scheme "$SCHEME" \
      -configuration Release \
      -sdk iphoneos \
      -derivedDataPath "$BUILD_DIR/DerivedData" \
      -archivePath "$BUILD_DIR/$PROJECT_NAME.xcarchive" \
      archive \
      CODE_SIGN_STYLE=Automatic \
      | tail -30

    info "导出 .ipa ..."
    mkdir -p "$EXPORT_DIR"

    # 最简单的导出方式：Development 描述文件
    cat > "$BUILD_DIR/ExportOptions.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
</dict>
</plist>
PLIST

    xcodebuild -exportArchive \
      -archivePath "$BUILD_DIR/$PROJECT_NAME.xcarchive" \
      -exportPath "$EXPORT_DIR" \
      -exportOptionsPlist "$BUILD_DIR/ExportOptions.plist"

    green "导出完成：$EXPORT_DIR"
    ls -la "$EXPORT_DIR"
    ;;

  clean)
    info "清理 ..."
    rm -rf "$BUILD_DIR" "$PROJECT_NAME.xcodeproj"
    green "已清理"
    ;;

  *)
    red "未知命令：$cmd"
    echo "可用：gen | open | archive | clean"
    exit 1
    ;;
esac
