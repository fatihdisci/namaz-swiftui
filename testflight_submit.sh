#!/bin/bash

# ============================================
# Vakit — TestFlight Build & Submit Script
# ============================================

set -e

PROJECT_DIR="/Users/fatih/Apps/namaz-swiftui"
SCHEME="Vakit"
ARCHIVE_PATH="$PROJECT_DIR/build/Vakit.xcarchive"
EXPORT_PATH="$PROJECT_DIR/build/export"
EXPORT_OPTIONS="$PROJECT_DIR/ExportOptions.plist"
APPLE_ID="av.fatihdisci@gmail.com"
PBXPROJ="$PROJECT_DIR/Vakit.xcodeproj/project.pbxproj"

cd "$PROJECT_DIR"

# ── 1. Build numarasını artır ──────────────────
CURRENT_BUILD=$(grep -m1 'CURRENT_PROJECT_VERSION' "$PBXPROJ" | grep -o '[0-9]*')
NEW_BUILD=$((CURRENT_BUILD + 1))

sed -i '' "s/CURRENT_PROJECT_VERSION = $CURRENT_BUILD/CURRENT_PROJECT_VERSION = $NEW_BUILD/g" "$PBXPROJ"

echo "✅ Build numarası: $CURRENT_BUILD → $NEW_BUILD"

# ── 2. Eski build klasörünü temizle ───────────
rm -rf "$PROJECT_DIR/build"
mkdir -p "$PROJECT_DIR/build"
echo "✅ Build klasörü temizlendi"

# ── 3. ExportOptions.plist oluştur ────────────
cat > "$EXPORT_OPTIONS" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>app-store-connect</string>
  <key>teamID</key>
  <string>8XPP7Z37GF</string>
  <key>uploadSymbols</key>
  <true/>
  <key>signingStyle</key>
  <string>automatic</string>
</dict>
</plist>
PLIST
echo "✅ ExportOptions.plist oluşturuldu"

# ── 4. Archive ────────────────────────────────
echo "⏳ Archive alınıyor... (3-5 dk sürebilir)"

xcodebuild \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath "$ARCHIVE_PATH" \
  archive \
  -quiet

echo "✅ Archive tamamlandı"

# ── 5. IPA Export ─────────────────────────────
echo "⏳ IPA export ediliyor..."

xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$EXPORT_OPTIONS" \
  -quiet

echo "✅ IPA hazır"

# ── 6. TestFlight Upload ──────────────────────
echo ""
echo "📧 Apple ID: $APPLE_ID"
echo "App-specific password girin"
echo "(appleid.apple.com → Security → App-Specific Passwords):"
read -s APP_PASSWORD
echo ""

xcrun altool \
  --upload-app \
  -f "$EXPORT_PATH/Vakit.ipa" \
  -t ios \
  -u "$APPLE_ID" \
  -p "$APP_PASSWORD"

echo ""
echo "✅ Upload tamamlandı!"
echo "Build $NEW_BUILD TestFlight'ta işlenmeyi bekliyor (~5-15 dk)"
echo "⚠️  'Missing Compliance' çıkarsa: None → Save"

# ── 7. Git commit ─────────────────────────────
git add Vakit.xcodeproj/project.pbxproj
git commit -m "build: TestFlight build $NEW_BUILD"
git push origin main

echo ""
echo "🚀 Tamamlandı!"
