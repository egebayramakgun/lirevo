# CLAUDE.md

Bu dosya Claude Code'un bu depoda nasıl çalışacağını tanımlar. Her oturumda önce bunu, sonra ilgili `docs/` bölümünü oku.

## Proje

macOS menü çubuğu uygulaması: Spotify ve Apple Music'te çalan şarkının sözlerini kelime kelime yakan bir söz katmanı, müziğe tepki veren ekran kenarı ışığı ve cam oynatıcı kartı. Yalnızca Apple Silicon, macOS 14.2+. Swift 6, SwiftUI + AppKit, Metal.

Belgeler (`docs/`):
- `prd.md` — ne yapıyoruz, öncelikler
- `trd.md` — nasıl yapıyoruz, modüller, teknik kararlar
- `app_flow.md` — akışlar, durum makineleri, hata/düşük mod matrisi
- `ui_ux_brief.md` — görsel ve etkileşim spesifikasyonu
- `backend_schema.md` — SQLite şeması, JSON formatları, olaylar, dış API'ler
- `implementation_plan.md` — aşamalar (M0–M10) ve görev ID'leri

## Dokümanları geçersiz kılan kararlar

Belgelerle bu bölüm çelişirse **bu bölüm geçerlidir**.
Bu kararlar ve sonraki ürün kararları (görünürlük varsayılanı, palet rol eşlemesi, parça kimliği, kısayollar, adlandırma) 2026-11-08'de dokümanlara işlendi.

1. **Proje açık kaynak, lisansı GPL-3.0-or-later.** Kök dizinde `LICENSE` (GPL-3.0 tam metni, GitHub'ın lisans şablonundan), her Swift dosyasının başında SPDX satırı: `// SPDX-License-Identifier: GPL-3.0-or-later`.
2. **Lisans anahtarı sistemi yok.** `LicenseService`, `LicenseVendor`, Lisans sekmesi, onboarding lisans adımı ve M8-T4 uygulanmaz. Onboarding 4 adımdır.
3. **Ticari söz sağlayıcı uygulanmaz.** Yalnızca `LyricsProvider` protokolü genişletmeye açık kalır.
4. **Ürün adı:** `Lirevo`. Ad, bundle ID ve alan adı tek bir yerde tanımlanır (`Config/App.xcconfig`: `PRODUCT_NAME`, `PRODUCT_BUNDLE_IDENTIFIER`, `APP_WEBSITE`). Kodda ve metinlerde ürün adını sabit yazma; `Bundle.main` veya `AppInfo` üzerinden oku. `Localizable.xcstrings` içinde ad `%@` ile geçer.
5. **Gizli anahtarlar asla depoya girmez**: Sparkle EdDSA özel anahtarı, `capabilities.json` imzalama anahtarı, Developer ID sertifikaları, notarization kimlik bilgileri. Yalnızca GitHub Actions secrets ve yerel Keychain. `.gitignore` buna göre yazılır. Genel (public) anahtarlar depoda olabilir.
6. Verci ve Lumn yalnızca ilham kaynağıdır. Onlardan kod, görsel, metin, ikon veya kelime-simge eşleme tablosu kopyalanmaz.

## Çalışma biçimi

- İşi `implementation_plan.md`'deki görev ID'leriyle yürüt (ör. `M2-T4`). Bir seferde tek görev veya kullanıcının verdiği görev grubu.
- Bir göreve başlamadan önce: ilgili doküman bölümlerini oku, kısa bir uygulama planı yaz (dosyalar, tipler, testler), sonra kodla.
- Bir görev bitince: testleri çalıştır, Definition of Done listesini (`implementation_plan.md` §3) kontrol et, değişiklik özetini yaz, görev başına bir commit at (Conventional Commits: `feat(lyrics): M5-T6 word timing estimator`).
- Doküman ile gerçek arasında fark çıkarsa (API davranışı, imkânsız bir gereksinim) **dokümanı da güncelle** ve özette belirt.
- Belirsizlik veya iş kararı gerektiren durumda dur ve sor; tahminle büyük yapı kurma.
- Yeni üçüncü taraf bağımlılık ekleme. İzinli olanlar: GRDB, Sparkle. Başka bir şey gerekiyorsa önce gerekçesiyle sor.

## Senin test edemediğin şeyler

Bu uygulamanın birçok davranışı gerçek donanım ve kullanıcı etkileşimi gerektirir: izin pencereleri (Otomasyon, sistem sesi), kilit ekranı, ekran uyku/uyanma, notch geometrisi, çoklu ekran, Spotify/Müzik ile canlı senkron, görsel kalite ve kare hızı.

Bu tür görevlerde:
1. Kodu yaz ve derlenebildiğini doğrula.
2. Mümkün olan her şeyi sahte (mock) kaynaklarla birim/entegrasyon testine bağla.
3. Kullanıcı için **manuel test kontrol listesi** üret: adım adım ne yapacak, ne görmeli, hangi log kategorisine bakmalı (`log stream --predicate 'subsystem == "<bundle id>"'`).
4. Kullanıcının sonucu bildirmesini bekle; "çalışıyor" diye varsayma.

M0 spike'larında aynı kural geçerli: spike kodunu `Spikes/` altında ayrı küçük hedeflerde yaz, ölçüm adımlarını ver, kullanıcının sonuçlarıyla `docs/spikes/S<n>.md` raporunu birlikte doldur.

## Teknik kurallar

- Swift 6 strict concurrency; uyarısız derleme.
- Servisler `actor`, UI ve pencere yönetimi `@MainActor`. Gerçek zamanlı ses iş parçacığında bellek ayırma, kilit, Swift concurrency yok.
- Her servis `HealthReporting` uygular ve Sistem Durumu panelinde görünür.
- Her alt sistem bağımsız başarısız olabilir; hata asla uygulamayı düşürmez (`app_flow.md` §13).
- Private API yalnızca `LockScreenBridge` hedefinde, `dlsym` ile dinamik ve feature flag arkasında.
- Yalnız `arm64`. `MACOSX_DEPLOYMENT_TARGET = 14.2`. macOS 15/26 API'leri `if #available` ile.
- Kullanıcıya görünen her metin `Localizable.xcstrings` içinde, TR + EN.
- Ağda yalnızca HTTPS; kişisel veri URL'ye konmaz.

## Komutlar

```bash
# Paket testleri (hızlı, çoğu iş için yeterli)
swift test --package-path LirevoKit

# Uygulama derlemesi
xcodebuild -project Lirevo.xcodeproj -scheme Lirevo -configuration Debug -destination 'platform=macOS,arch=arm64' build

# Uygulama testleri
xcodebuild -project Lirevo.xcodeproj -scheme Lirevo -destination 'platform=macOS,arch=arm64' test

# Loglar
log stream --level debug --predicate 'subsystem BEGINSWITH "app.lirevo"'
```
Komutlar proje kuruldukça güncellenir; değişirse bu bölümü düzelt.

## Açık kaynak depo hijyeni

M1 sırasında oluştur, sonra güncel tut:
- `README.md` (TR + EN): demo GIF/video yeri, özellikler, kurulum (indir + kaynaktan derle), izinler ve neden gerektiği, gizlilik notu, katkı rehberine bağlantı.
- `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md` (Contributor Covenant), `SECURITY.md`.
- `.github/ISSUE_TEMPLATE/` (hata raporu: macOS sürümü, Mac modeli, oynatıcı, Sistem Durumu teşhis paketi; özellik isteği), `PULL_REQUEST_TEMPLATE.md`.
- `.github/workflows/ci.yml` (build + test, macOS arm64 runner), sonra `release.yml` (M8).
- `TRADEMARKS.md`: kod GPL ile serbest, ancak ürün adı ve logo izinsiz kullanılamaz; çatallar (fork) farklı ad kullanmalıdır.
