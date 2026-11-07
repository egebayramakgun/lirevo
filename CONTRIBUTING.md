# Katkı rehberi / Contributing

**[Türkçe](#türkçe) · [English](#english)**

---

## Türkçe

Lirevo'ya katkıda bulunmak istediğin için teşekkürler. Bu belge, değişikliğinin hızlıca incelenip birleştirilebilmesi için gereken her şeyi anlatır. Katılımın [Davranış Kuralları](CODE_OF_CONDUCT.md)'na tabidir.

### Başlamadan önce

- Küçük düzeltmeler (yazım, belgeler, açık hatalar) için doğrudan pull request açabilirsin.
- Yeni bir özellik veya büyük bir değişiklik için önce bir **issue** aç; kapsam ve yaklaşım üzerinde anlaşalım.
- Ürünün kapsamı ve teknik kararlar `docs/` altındadır. Özellikle `docs/prd.md`, `docs/trd.md` ve `docs/implementation_plan.md`'ye göz at.

### Geliştirme ortamı

- Apple Silicon Mac, macOS 14.2+ (geliştirme için güncel macOS önerilir).
- Xcode 27 veya sonrası.

```bash
git clone https://github.com/egebayramakgun/lirevo.git
cd lirevo
cp Config/Local.xcconfig.example Config/Local.xcconfig   # isteğe bağlı: DEVELOPMENT_TEAM
```

Komutlar:

```bash
# Paket testleri (hızlı)
swift test --package-path LirevoKit

# Uygulama derlemesi
xcodebuild -project Lirevo.xcodeproj -scheme Lirevo -configuration Debug -destination 'platform=macOS,arch=arm64' build

# Uygulama testleri (birim + arayüz)
xcodebuild -project Lirevo.xcodeproj -scheme Lirevo -destination 'platform=macOS,arch=arm64' test

# Loglar
log stream --level debug --predicate 'subsystem BEGINSWITH "app.lirevo"'
```

### Proje yapısı

- `Lirevo/`: uygulama hedefi (menü çubuğu, pencereler, uygulama kabuğu).
- `LirevoKit/`: modüllerin yaşadığı yerel Swift paketi (`Core`, `NowPlaying`, `Lyrics`, `Analysis`, `Rendering` …). Bağımlılık yönü `docs/trd.md` §3'te.
- `Config/App.xcconfig`: ürün adı, bundle ID ve web sitesi için **tek kaynak**.

### Kurallar

- **Lisans başlığı**: Her Swift (ve C) dosyası `// SPDX-License-Identifier: GPL-3.0-or-later` satırıyla başlar.
- **Swift 6 strict concurrency**, uyarısız derleme. Servisler `actor`, UI `@MainActor`. Gerçek zamanlı ses iş parçacığında bellek ayırma, kilit ve Swift concurrency yok.
- **Ürün adını kodda sabit yazma**; `AppInfo` üzerinden oku. Metinlerde ad `%@` ile geçer.
- **Metinler**: Kullanıcıya görünen her metin `Localizable.xcstrings` içinde, **Türkçe ve İngilizce**. Paket modülleri kendi kataloglarını `Bundle.module` ile kullanır.
- **Bağımlılıklar**: Yeni üçüncü taraf bağımlılık ekleme. İzinli olanlar GRDB ve Sparkle. Başka bir şey gerekiyorsa önce issue'da gerekçesiyle tartışalım.
- **Dayanıklılık**: Her alt sistem tek başına başarısız olabilir; hata uygulamayı düşürmemeli (`docs/app_flow.md` §13). Servisler `HealthReporting` uygular.
- **Private API** yalnızca `LockScreenBridge` hedefinde, `dlsym` ile ve feature flag arkasında.
- **Gizlilik**: Ağda yalnızca HTTPS; kişisel veri URL'ye konmaz. Mikrofon ve ekran kaydı kullanılmaz.
- **Gizli anahtarlar** (imzalama anahtarları, sertifikalar, notarization bilgileri) asla depoya girmez.
- **Erişilebilirlik**: Görsel değişikliklerde Hareketi Azalt ve Kontrastı Artır davranışını kontrol et.

### Testler

- Yeni mantık için birim testi yaz (Swift Testing). Donanım veya izin gerektiren davranışlar için mock kaynaklar kullan.
- Gerçek donanımda doğrulanması gereken değişikliklerde (izin pencereleri, kilit ekranı, çoklu ekran, görsel kalite) pull request açıklamasına **manuel test adımlarını** ekle.

### Commit ve pull request

- [Conventional Commits](https://www.conventionalcommits.org/) kullan; varsa görev kimliğini ekle: `feat(lyrics): M5-T6 word timing estimator`.
- Her pull request tek bir konuya odaklansın. Şablondaki kontrol listesini doldur.
- Belgelerle kod arasında fark çıkarsa ilgili `docs/` bölümünü de güncelle.

### Lisans

Katkı göndererek, katkının projenin lisansı olan **GPL-3.0-or-later** altında dağıtılmasını kabul etmiş olursun. "Lirevo" adı ve logosu bu lisansın kapsamında değildir; bkz. [TRADEMARKS.md](TRADEMARKS.md).

---

## English

Thank you for your interest in contributing to Lirevo. This document covers everything needed for your change to be reviewed and merged quickly. Participation is governed by the [Code of Conduct](CODE_OF_CONDUCT.md).

### Before you start

- For small fixes (typos, docs, obvious bugs) feel free to open a pull request directly.
- For a new feature or a larger change, open an **issue** first so we can agree on scope and approach.
- Product scope and technical decisions live in `docs/` (currently in Turkish). See especially `docs/prd.md`, `docs/trd.md` and `docs/implementation_plan.md`.

### Development setup

- Apple Silicon Mac, macOS 14.2+ (a current macOS is recommended for development).
- Xcode 27 or later.

```bash
git clone https://github.com/egebayramakgun/lirevo.git
cd lirevo
cp Config/Local.xcconfig.example Config/Local.xcconfig   # optional: DEVELOPMENT_TEAM
```

Commands:

```bash
# Package tests (fast)
swift test --package-path LirevoKit

# Build the app
xcodebuild -project Lirevo.xcodeproj -scheme Lirevo -configuration Debug -destination 'platform=macOS,arch=arm64' build

# App tests (unit + UI)
xcodebuild -project Lirevo.xcodeproj -scheme Lirevo -destination 'platform=macOS,arch=arm64' test

# Logs
log stream --level debug --predicate 'subsystem BEGINSWITH "app.lirevo"'
```

### Project layout

- `Lirevo/`: the app target (menu bar, windows, app shell).
- `LirevoKit/`: local Swift package holding the modules (`Core`, `NowPlaying`, `Lyrics`, `Analysis`, `Rendering` …). Dependency direction is described in `docs/trd.md` §3.
- `Config/App.xcconfig`: the **single source** for product name, bundle ID and website.

### Rules

- **License header**: Every Swift (and C) file starts with `// SPDX-License-Identifier: GPL-3.0-or-later`.
- **Swift 6 strict concurrency**, warning-free builds. Services are `actor`s, UI is `@MainActor`. No allocation, locks or Swift concurrency on the real-time audio thread.
- **Don't hard-code the product name**; read it through `AppInfo`. In strings the name is passed as `%@`.
- **Strings**: Every user-facing string lives in `Localizable.xcstrings`, in **Turkish and English**. Package modules use their own catalogs via `Bundle.module`.
- **Dependencies**: Don't add new third-party dependencies. GRDB and Sparkle are allowed. If you need something else, discuss it in an issue first, with a rationale.
- **Resilience**: Any subsystem may fail on its own; a failure must never crash the app (`docs/app_flow.md` §13). Services implement `HealthReporting`.
- **Private API** only in the `LockScreenBridge` target, loaded via `dlsym` and behind a feature flag.
- **Privacy**: HTTPS only; no personal data in URLs. No microphone, no screen recording.
- **Secrets** (signing keys, certificates, notarization credentials) never enter the repository.
- **Accessibility**: For visual changes, check Reduce Motion and Increase Contrast behavior.

### Tests

- Write unit tests for new logic (Swift Testing). Use mock sources for behavior that needs hardware or permissions.
- For changes that must be verified on real hardware (permission prompts, lock screen, multiple displays, visual quality), include **manual test steps** in the pull request description.

### Commits and pull requests

- Use [Conventional Commits](https://www.conventionalcommits.org/) and include the task ID when there is one: `feat(lyrics): M5-T6 word timing estimator`.
- Keep each pull request focused on one topic and fill in the checklist in the template.
- If code and docs disagree, update the relevant `docs/` section as well.

### License

By submitting a contribution, you agree that it will be distributed under the project's license, **GPL-3.0-or-later**. The "Lirevo" name and logo are not covered by this license; see [TRADEMARKS.md](TRADEMARKS.md).
