# Ufuk — Şehir Yönetimi + Modal Kapatma + Pro Bug Fix + Yasal Linkler

> **For Hermes:** Follow plan step-by-step. Commit after each task.

**Goal:** Kayıtlı şehirleri silme/düzenleme, modal kapatma butonu, Pro aktifken paywall açılmaması, ayarlara yasal linkler.

**Tech Stack:** SwiftUI, iOS 17+

---

## Task 1: Pro Gate flash bug fix

**Problem:** Pro aktifken Ayarlar → "Ufuk Pro"ya basınca paywall 1 saniye açılıp kapanıyor.

**Root cause:** `setupView`da `showProGate = true` önce sheet'i açıyor, sonra ProGateView'deki `.task` hasProAccess'i görüp dismiss ediyor.

**Fix:** Butonu sadece `!hasProAccess` iken aktif yap.

**File:** `Vakit/Views/Settings/SettingsView.swift` ~206

```swift
// Değiştir: proSection içindeki Button
Button {
    showProGate = true
} label: { ... }
.disabled(purchaseService.hasProAccess)
```

Commit: `fix: pro aktifken paywall açılmıyor`

---

## Task 2: Modal kapatma butonu (X / Geri)

**Problem:** CitySelectionView ve LocationSelectionView sheet'lerinde kapatma butonu yok.

**File 1:** `Vakit/Views/Onboarding/CitySelectionView.swift`
- Üste toolbar ekle: `ToolbarItem(placement: .topBarLeading)` → "Geri" veya X butonu
- Buton `dismiss()` veya bir callback çağırsın

**File 2:** `Vakit/Views/Onboarding/LocationSelectionView.swift`
- Aynı şekilde toolbar'a kapatma butonu ekle
- `@Environment(\.dismiss)` kullan

**File 3:** LocationPickerSheet (SettingsView.swift içinde)
- Zaten NavigationStack var → toolbar'a dismiss butonu ekle

**File 4:** NewLocationSheet (HomeView.swift içinde)  
- Aynı şekilde toolbar'a dismiss butonu ekle

Commit: `feat: modal sheet'lere kapatma butonu eklendi`

---

## Task 3: SettingsView'da yasal linkler

**Dosya:** `Vakit/Views/Settings/SettingsView.swift`

AboutSection'dan sonra ekle:

```swift
private var legalSection: some View {
    section(titleKey: "settings.legal") {
        Link(destination: lang.currentLanguage == "tr"
            ? URL(string: "https://namaz-swiftui.vercel.app/kullanim-kosullari.html")!
            : URL(string: "https://namaz-swiftui.vercel.app/terms-of-service.html")!
        ) {
            HStack {
                rowLabel(icon: "doc.text", titleKey: "settings.terms")
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.vakitTextDim)
            }
            .padding(.vertical, 10)
        }

        divider

        Link(destination: lang.currentLanguage == "tr"
            ? URL(string: "https://namaz-swiftui.vercel.app/gizlilik-politikasi.html")!
            : URL(string: "https://namaz-swiftui.vercel.app/privacy-policy.html")!
        ) {
            HStack {
                rowLabel(icon: "hand.raised", titleKey: "settings.privacy")
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.vakitTextDim)
            }
            .padding(.vertical, 10)
        }
    }
}
```

Body'de aboutSection'dan sonra `legalSection` ekle.

**Localization keys (Localizable.xcstrings):**
- `settings.legal`: TR="Yasal" / EN="Legal"
- `settings.terms`: TR="Kullanım Koşulları" / EN="Terms of Service"
- `settings.privacy`: TR="Gizlilik Politikası" / EN="Privacy Policy"

Commit: `feat: ayarlara dil duyarlı yasal linkler eklendi`

---

## Task 4: Kayıtlı şehirleri silme

**Backend:** StorageService'de zaten `removeSavedLocation(id:)` var. HomeViewModel'da `savedLocations` array'i var.

**UI:** HomeView'daki citySelector'da her şehre uzun basınca (context menu) veya sola kaydırınca (swipe to delete) silme seçeneği ekle.

**File 1:** `Vakit/Views/Home/HomeView.swift`

citySelector içindeki `ForEach` button'una `.contextMenu` ekle:

```swift
ForEach(viewModel.savedLocations) { location in
    Button { ... } label: { ... }
    .contextMenu {
        Button(role: .destructive) {
            StorageService.shared.removeSavedLocation(id: location.id)
            viewModel.savedLocations = StorageService.shared.savedPrayerLocations
        } label: {
            Label(lang.t("location.delete"), systemImage: "trash")
        }
        // En az 1 lokasyon kalmalı
    }
    .disabled(viewModel.savedLocations.count <= 1)
}
```

**Localization keys:**
- `location.delete`: TR="Sil" / EN="Delete"

Commit: `feat: kayıtlı şehri silme (context menu) eklendi`

---

## Task 5: Build + test

```bash
xcodebuild -project Vakit.xcodeproj -scheme Vakit \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -configuration Debug build
```

Commit: yok (build doğrulaması)

---

## Özet

| # | Task | Sorumluluk |
|---|------|-----------|
| 1 | Pro gate flash fix | 1 satır `.disabled()` |
| 2 | Modal kapatma butonu | 4 view'a toolbar ekle |
| 3 | Yasal linkler | Yeni section + 4 key |
| 4 | Şehir silme | Context menu + 1 key |
| 5 | Build test | xcodebuild |
