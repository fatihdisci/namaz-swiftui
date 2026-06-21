# Ufuk - Namaz Vakitleri - App Store Connect Metadata

## Uygulama Bilgileri

- Uygulama adı: Ufuk - Namaz Vakitleri
- Bundle ID: `com.vakit.app`
- Sürüm: `1.1.0`
- Build: `27`
- Birincil kategori: Utilities
- İkincil kategori: Reference
- Kısa açıklama: Namaz vakitleri, kıble ve seferi hesaplama.

## Gizlilik Özeti

- Konum, namaz vakitlerini hesaplamak, seçili şehri belirlemek, kıble yönünü göstermek ve seferi mesafesini hesaplamak için kullanılır.
- Konum reklam veya kullanıcı takibi amacıyla kullanılmaz.
- Bildirimler yalnızca kullanıcının seçtiği namaz vakti hatırlatmalarını cihazda planlamak için kullanılır.
- Kaza sayaçları ve uygulama ayarları cihazda saklanır.

## App Review Notu

Uygulama yerel bildirimler kullanır. Kullanıcı bildirim iznini onboarding sırasında veya bildirim ayarları ekranında verir. Namaz vakti hatırlatmaları cihaz üzerinde planlanır.

Ufuk Pro satın alımları RevenueCat ve Apple In-App Purchase üzerinden yönetilir. Kullanıcılar kayıt olmadan veya Apple ile Giriş yapmadan tüm ürünleri satın alabilir ve satın alımlarını geri yükleyebilir. RevenueCat anonim kullanıcı kimliği uygulama tarafından otomatik oluşturulur; kişisel bilgi istenmez. İsteğe bağlı uygulama hesabı satın alma veya Pro içeriğe erişim için gerekli değildir.

Guideline 5.1.1(v) için önceki ret sonrasında satın alma akışı güncellendi. Paywall üzerindeki zorunlu Apple ile Giriş adımı kaldırıldı; "Satın Al" ve "Satın Alımları Geri Yükle" eylemleri misafir kullanıcılar için doğrudan kullanılabilir.

## App Store Connect Kontrol Listesi

- App Privacy formunu privacy manifest ile tutarlı doldur.
- Privacy Policy URL ekle.
- Support URL ekle.
- iPhone ekran görüntülerini yükle.
- Yaş derecelendirmesi anketini tamamla.
- `vakit_pro_monthly`, `vakit_pro_yearly`, `vakit_pro_lifetime` ürünlerini incelemeye gönder.
