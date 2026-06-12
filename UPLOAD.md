# TestFlight Upload Kılavuzu

> Proje: Ufuk — Namaz Vakitleri
> Bundle ID: com.vakit.app
> Team: FATIH DISCI
> Team ID (distribution): 8XPP7Z37GF

---

## Ön Koşullar (bir kere yapılır)

1. Xcode → Settings → Accounts → Apple ID ekli olmalı
2. Xcode → Settings → Accounts → Manage Certificates → **Apple Distribution** sertifikası oluşturulmalı
3. https://appstoreconnect.apple.com → **Ufuk** uygulaması oluşturulmuş olmalı
4. App-specific password: https://appleid.apple.com → Sign-In and Security → App-Specific Passwords

---

## Adım Adım Upload

### 1. Proje dizinine git

```bash
cd ~/apps/namaz-swiftui
```

### 2. Build number'ı artır

Mevcut build number'ı gör:
```bash
grep "CURRENT_PROJECT_VERSION" Vakit.xcodeproj/project.pbxproj
```

Bir artır (örnek: 3 → 4):
```bash
sed -i '' 's/CURRENT_PROJECT_VERSION = 3;/CURRENT_PROJECT_VERSION = 4;/g' Vakit.xcodeproj/project.pbxproj
```

### 3. ExportOptions.plist oluştur

```bash
mkdir -p build
cat > build/ExportOptions.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store-connect</string>
    <key>teamID</key>
    <string>8XPP7Z37GF</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>manageAppVersionAndBuildNumber</key>
    <false/>
    <key>signingStyle</key>
    <string>automatic</string>
</dict>
</plist>
EOF
```

### 4. Release archive al

```bash
xcodebuild \
  -project Vakit.xcodeproj \
  -scheme Vakit \
  -configuration Release \
  -archivePath ./build/Vakit.xcarchive \
  -destination 'generic/platform=iOS' \
  clean archive
```

Başarılı çıktı: `** ARCHIVE SUCCEEDED **`

### 5. IPA export et

```bash
xcodebuild \
  -exportArchive \
  -archivePath ./build/Vakit.xcarchive \
  -exportPath ./build/Vakit.ipa \
  -exportOptionsPlist ./build/ExportOptions.plist \
  -allowProvisioningUpdates
```

Başarılı çıktı: `** EXPORT SUCCEEDED **`

IPA konumu: `build/Vakit.ipa/Vakit.ipa`

### 6. App Store Connect'e upload

```bash
xcrun altool --upload-app \
  -f ./build/Vakit.ipa/Vakit.ipa \
  -t ios \
  -u "av.fatihdisci@gmail.com" \
  -p "APP_SPECIFIC_PASSWORD"
```

> Şifreyi her seferinde yaz, dosyaya kaydetme.

Başarılı çıktı: `UPLOAD SUCCEEDED`

### 7. Commit

```bash
git add -A
git commit -m "chore: bump build number to X for TestFlight upload"
git push origin main
```

---

## App Store Connect Kontrol

1. https://appstoreconnect.apple.com → **Ufuk** → **TestFlight**
2. Build "Processing" durumunda (~5-15 dk)
3. İşlem bitince "Missing Compliance" çıkabilir:
   - Build'e tıkla → "Provide Export Compliance Information"
   - "None of the algorithms mentioned above" seç → Save
4. Build'i test grubuna ekle

---

## Hızlı Referans

| Komut | Amaç |
|---|---|
| `grep CURRENT_PROJECT_VERSION ...` | Mevcut build no |
| `sed -i '' 's/= 3;/= 4;/g' ...` | Build no artır |
| `xcodebuild ... clean archive` | Release build |
| `xcodebuild -exportArchive ...` | IPA çıkar |
| `xcrun altool --upload-app ...` | App Store Connect'e yükle |
