#!/bin/bash
# 一键编译脚本：把 main.swift 打包成一个可以双击运行的 .app
# 用法：在终端里 cd 到这个目录，执行  bash build.sh

set -e
cd "$(dirname "$0")"

APP="Memory Butler.app"
BIN="GameMode"

echo "==> 检查编译环境"
if ! command -v swiftc >/dev/null 2>&1; then
  echo "没有找到 swiftc（系统编译工具）。请先执行：xcode-select --install"
  exit 1
fi

echo "==> 清理旧版本"
rm -rf "$APP" "$BIN"

echo "==> 编译（大约 20-60 秒）"
swiftc -swift-version 5 -O -o "$BIN" main.swift

echo "==> 组装 App"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
mv "$BIN" "$APP/Contents/MacOS/GameMode"
if [ -f AppIcon.icns ]; then
  cp AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
fi

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key><string>GameMode</string>
  <key>CFBundleIdentifier</key><string>com.bs0116.gamemode</string>
  <key>CFBundleName</key><string>Memory Butler</string>
  <key>CFBundleDisplayName</key><string>Memory Butler</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.2</string>
  <key>CFBundleVersion</key><string>3</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundleLocalizations</key><array><string>zh-Hans</string><string>en</string></array>
  <key>CFBundleDevelopmentRegion</key><string>zh_CN</string>
  <key>LSMinimumSystemVersion</key><string>12.0</string>
  <key>LSMultipleInstancesProhibited</key><true/>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSHumanReadableCopyright</key><string>Memory Butler · 内存管家</string>
</dict>
</plist>
PLIST

echo "==> 本地签名"
codesign --force --sign - "$APP" 2>/dev/null || echo "（签名跳过，不影响使用）"

echo ""
echo "完成！双击当前目录下的「$APP」即可运行。"
echo "菜单栏右上角会出现一个小图标，点它打开面板。"
