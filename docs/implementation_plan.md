# Implementation Plan — Lirevo

> Tek geliştirici (veya geliştirici + AI kod asistanı) varsayımıyla aşamalı plan. Her aşama çalışan, demo edilebilir bir uygulama bırakır.
> Süreler kaba tahmindir (tam zamanlı iş günü).

---

## 0. Çalışma kuralları

- **Her aşama sonunda uygulama çalışır durumda** olmalı. Yarım özellik feature flag arkasında.
- Riskli bilinmeyenler en başta küçük deneylerle (spike) çözülür; spike kodu ana projeye kopyalanmaz, öğrenilen sonuç `docs/spikes/*.md`'ye yazılır.
- Her alt sistem önce **protokol + sahte (mock) uygulama** ile girer; gerçek uygulama sonra. Böylece UI ve SceneEngine erken geliştirilebilir.
- Her PR: birim testleri, `HealthReporting` uygulaması (servisse), Sistem Durumu'nda görünürlük.
- AI asistanla çalışırken görevleri bu dokümandaki görev ID'leriyle ver ("M2-T3'ü uygula, trd.md §4.2'ye uy") ve her seferinde ilgili doküman bölümünü bağlama ekle.

## 1. Depo yapısı

```
lirevo/
├─ Lirevo.xcodeproj            # Xcode 27 `project.xcproj` biçimi, klasörler senkronize
├─ Config/
│  ├─ App.xcconfig             # PRODUCT_NAME, PRODUCT_BUNDLE_IDENTIFIER, APP_WEBSITE, ortak ayarlar
│  ├─ Local.xcconfig.example   # DEVELOPMENT_TEAM şablonu
│  └─ Local.xcconfig           # git dışı (geliştiriciye özel)
├─ Lirevo/                     # App target (AppShell)
│  ├─ LirevoApp.swift
│  ├─ Assets.xcassets, Localizable.xcstrings, InfoPlist.xcstrings, Lirevo.entitlements
├─ LirevoTests/, LirevoUITests/
├─ LirevoKit/                  # Yerel Swift Package
│  ├─ Package.swift
│  ├─ Sources/
│  │  ├─ Core/ Persistence/ NowPlaying/ Lyrics/ Palette/ Analysis/
│  │  ├─ SceneEngine/ Rendering/ Presentation/ Platform/ Language/ Services/
│  │  ├─ CAtomics/ (C hedefi, stdatomic)
│  │  └─ Shaders/ (Metal: RimLight.metal, Lens.metal)
│  └─ Tests/ (her modül için)
├─ LockScreenBridge/           # Ayrı framework target, opsiyonel yüklenir
├─ Tools/
│  ├─ LirevoBench/             # söz isabet ve zamanlama ölçüm CLI'ı
│  └─ release.sh               # build → sign → notarize → dmg → appcast
├─ docs/ (bu 6 doküman + spikes/)
└─ Fixtures/ (örnek LRC/ELRC/TTML, test kapakları, sentetik ses)
```

Bağımlılıklar (SPM): GRDB, Sparkle. Başka üçüncü taraf bağımlılığı eklemeden önce gerekçe yazılır.

## 2. Aşamalar özeti

| Aşama | Ad | Süre | Çıktı |
|---|---|---|---|
| M0 | Spike'lar | 4–5 gün | Riskler için karar raporları |
| M1 | İskelet | 3 gün | Menü çubuğu uygulaması, modül yapısı, CI |
| M2 | Çalma izleyici + palet | 4 gün | Menüde canlı "şimdi çalıyor" + renkler |
| M3 | Ses analizi | 3 gün | Canlı FFT/beat, SyntheticPulse |
| M4 | Işık çerçevesi | 5 gün | Lumn-eşdeğeri ışık, notch, çoklu ekran |
| M5 | Sözler | 8 gün | Sağlayıcı zinciri, zamanlama, 4 stil |
| M6 | Sahne motoru + sahneler + görünürlük | 5 gün | Presetler, Stage Modu, otomatik gizleme |
| M7 | Cam kart, ayarlar, onboarding, kısayollar | 6 gün | Tam kullanıcı deneyimi |
| M8 | Sertleştirme + dağıtım | 5 gün | Notarize dmg, Sparkle, v1.0 |
| M9 | Deneysel kilit ekranı katmanı | 4 gün | Opt-in, korumalı |
| M10 | v1.5 | 8–10 gün | Çeviri, romanizasyon, klip |

Toplam v1.0 (M0–M9): ~7–9 hafta.

---

## M0 — Spike'lar (önce riskleri öldür)

| ID | Spike | Başarı kriteri | Başarısızsa |
|---|---|---|---|
| M0-S1 | Core Audio process tap: global sistem sesi, izin akışı, macOS 14.2 / 15 / 26 | 48 kHz örnekler halka arabellekte, CPU < %1, izin metni görünüyor | ScreenCaptureKit ses yolu; o da yoksa yalnız SyntheticPulse |
| M0-S2 | Spotify + Müzik AppleScript: pozisyon doğruluğu, bildirimler, kapak, oynatıcı kapalıyken davranış | Pozisyon hatası < 50 ms interpolasyonla; oynatıcıyı istemeden açmıyor | Bildirim + daha seyrek yoklama |
| M0-S3 | LRCLIB isabet oranı: 200 parçalık korpusla (TR/EN/ES/JP/KR) | ≥ %80 senkron söz | Yerel dosya desteğini (M5-T4) öne çek, söz bulunamayan durum deneyimini güçlendir |
| M0-S4 | Onset hizalama prototipi: 20 parça üzerinde elle işaretlenmiş kelime zamanlarına karşı | Medyan hata ≤ 120 ms | `estimated` + dolgu animasyonuyla yetin |
| M0-S5 | Kilit ekranı üstü pencere (private SkyLight) | macOS 26 güncel build'de kilitliyken görünür, kilit açılınca temiz kapanır, çökme yok | Özellik v1'den çıkar, Sahne Modu birincil |
| M0-S6 | SwiftUI `distortionEffect` ile Fisheye performansı (5K ekran) | 60 fps, GPU < 2 ms | Metal'de offscreen doku + lens pass |

Çıktı: `docs/spikes/S1…S6.md` (ne denendi, ölçümler, karar). **M0-S5 başarısız olsa bile plan değişmez**; çekirdek zaten Sahne Modu ve masaüstü hedefi üzerine kurulu.

---

## M1 — İskelet

| ID | Görev | Kabul kriteri |
|---|---|---|
| M1-T1 | Xcode projesi, `LirevoKit` paketi, modül hedefleri, arm64-only, min 14.2 | `xcodebuild` arm64 dışı mimari üretmiyor |
| M1-T2 | `MenuBarExtra(.window)` + `LSUIElement` + boş panel | Dock ikonu yok, panel açılıyor |
| M1-T3 | Core: `EventBus`, `HealthReporting`, `FeatureFlags`, `Logger` kategorileri | Birim testleri |
| M1-T4 | Persistence: GRDB kurulumu, migration v1 (`backend_schema.md` §2), bakım işi | Migration testleri |
| M1-T5 | Sistem Durumu paneli iskeleti (sahte servislerle) | Sahte servislerin durumu listeleniyor |
| M1-T6 | CI: GitHub Actions macOS runner, build + test | Her PR'da yeşil |
| M1-T7 | Açık kaynak depo dosyaları: `LICENSE` (GPL-3.0), `README.md` (TR+EN), `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`, `TRADEMARKS.md`, `.github/` şablonları | CLAUDE.md "Açık kaynak depo hijyeni" listesi tamam |

---

## M2 — Çalma izleyici + palet

| ID | Görev | Kabul kriteri |
|---|---|---|
| M2-T1 | `NowPlayingSource` protokolü + `MockSource` | Sahte zaman çizgisiyle olay üretiyor |
| M2-T2 | `SpotifySource` (bildirim + AppleScript, 750 ms zaman aşımı, ayrı kuyruk, çalışmıyorsa script yok) | Parça değişimi ≤ 300 ms |
| M2-T3 | `MusicSource` (+ iTunes Search kapak yedeği) | Aynı |
| M2-T4 | `PlaybackClock` (interpolasyon, seek algılama, yumuşak düzeltme, offset) | Birim test: sentetik örneklerle sapma ≤ 50 ms |
| M2-T5 | `SourceArbiter` + "kaynağı sabitle" | İki oynatıcı senaryosu testi |
| M2-T6 | Otomasyon izni durum tespiti + Sistem Ayarları derin bağlantısı | İzin reddinde çökme yok, uyarı görünüyor |
| M2-T7 | `PaletteExtractor` (OKLab k-means, roller, kontrast koruyucu, monokrom tespiti) + önbellek | 20 test kapağı için deterministik sonuç, kontrast ≥ 4.5:1 |
| M2-T8 | Menü panelinde "Şimdi çalıyor" + palet önizleme + oynatma kontrolleri | Manuel test |

---

## M3 — Ses analizi

| ID | Görev | Kabul kriteri |
|---|---|---|
| M3-T1 | `AudioTap` (process tap, kilitsiz halka arabellek, aç/kapa yaşam döngüsü) | Gerçek zamanlı iş parçacığında ayırma yok (Instruments ile doğrula) |
| M3-T2 | `FFTAnalyzer` (vDSP, 32 log bant, RMS, flux) | Sentetik sinüs testleri |
| M3-T3 | `BeatTracker` + tempo | Metronom kaydında ≥ %90 vuruş tespiti |
| M3-T4 | `EnergyEnvelope` (kısa/uzun oran) | Sentetik crescendo testi |
| M3-T5 | `SyntheticPulse` yedeği | İzin yokken `AnalysisFrame.isSynthetic = true` akıyor |
| M3-T6 | Sistem Durumu + debug overlay (bant çubukları, sadece DEBUG) | — |

---

## M4 — Işık çerçevesi

| ID | Görev | Kabul kriteri |
|---|---|---|
| M4-T1 | `OverlayWindowManager`: ekran başına `NSPanel`, tıklanamaz, tüm Space'ler, tam ekran yardımcı, `sharingType = .none` | Space değiştirince ve tam ekran uygulamada görünür |
| M4-T2 | `RimLight.metal`: kenar bandı mesh'i, yuvarlak dikdörtgen SDF, düşüş, gradient akışı | 5K ekranda GPU ≤ 1 ms |
| M4-T3 | Notch geometrisi (`safeAreaInsets`, `auxiliaryTop*Area`), sar/atla | 14"/16" MacBook Pro'da görsel doğrulama |
| M4-T4 | Animasyon modları: musicSync, idle, breathe (lyricReactive M6'da) | — |
| M4-T5 | Flaş sınırlayıcı | Birim test: 10 Hz kare dalga girişinde çıktı ≤ 3 büyük değişim/sn |
| M4-T6 | Ekran tak/çıkar, çözünürlük değişimi | Kesintisiz yeniden kurulum |
| M4-T7 | `PowerGovernor` + `FrameClock` (`NSScreen.displayLink`) entegrasyonu | Pilde 30 fps, ekran uyurken 0 render |

Bu aşama sonunda uygulama tek başına anlamlıdır (Lumn-eşdeğeri). **İç demo.**

---

## M5 — Sözler

| ID | Görev | Kabul kriteri |
|---|---|---|
| M5-T1 | Parser'lar: LRC, Enhanced LRC, TTML (+ fixture'lar) | Bozuk girdide throw, fixture testleri |
| M5-T2 | Normalizasyon (başlık/sanatçı temizleme regex listesi) | 100 vakalık tablo testi |
| M5-T3 | Sağlayıcı zinciri + `CacheProvider` (pozitif/negatif TTL, ağ yokken negatif yazmama) | Entegrasyon testi (mock HTTP) |
| M5-T4 | `LocalFileProvider` (güvenli klasör yer imi) | — |
| M5-T5 | `LRCLIBProvider` (get → search → puanlama, User-Agent, zaman aşımı, degraded) | LirevoBench ile isabet oranı raporu |
| M5-T6 | `WordTimingEstimator` (dil duyarlı hece) | TR/EN/ES hece testleri |
| M5-T7 | `OnsetAligner` (vokal bandı flux, monoton DP eşleme, satır satır önbelleğe yazma) | M0-S4 korpusunda medyan ≤ 120 ms |
| M5-T8 | `LyricsTimeline`: zamana göre aktif satır/kelime/ilerleme (ikili arama) | ≤ 20 µs/sorgu |
| M5-T9 | Stil: Visual (en basit, ilk) | Snapshot testleri |
| M5-T10 | Stil: Fisheye (`Lens.metal` + `distortionEffect`) | 60 fps |
| M5-T11 | Stil: Ship (3D duvar, sürüklenme) | — |
| M5-T12 | Stil: Fisheye Visual | — |
| M5-T13 | `SymbolMapper`: tohum sözlük (~300 kelime TR+EN, kendi hazırladığımız), `NLEmbedding` genişletme, SF Symbol doğrulama, önbellek | Eşleme kapsamı raporu |
| M5-T14 | Senkron düzeltme (menü kaydırıcısı + `track_offset`) | Parça değişince doğru offset |
| M5-T15 | Enstrümantal + "söz yok" + "senkronsuz söz" durumları | — |

---

## M6 — Sahne motoru, sahneler, görünürlük

| ID | Görev | Kabul kriteri |
|---|---|---|
| M6-T1 | `SceneEngine` (girdileri birleştir, `SceneFrame` üret, ≤ 0.5 ms) | Benchmark testi |
| M6-T2 | Söze duyarlı ışık (beat + kelime nabzı + enerji yükselişi) | Görsel inceleme |
| M6-T3 | `Scene` modeli, `.lirevoscene` JSON, doğrulama, içe/dışa aktarma, 4 hazır sahne | Şema testleri (eksik/bilinmeyen alan, yüksek sürüm) |
| M6-T4 | `LockStateMonitor`, ekran uyku, `DisplayAwake` | 50× kilit/aç döngüsünde sızıntı yok |
| M6-T5 | `VisibilityPolicy` durum makinesi (`app_flow.md` §6) | Tüm geçişler için tablo testi |
| M6-T6 | `ForegroundAppMonitor` + otomatik gizleme kuralları + panik gizle | Zoom/Keynote senaryoları |
| M6-T7 | `StageHost` (Sahne Modu): tam ekran, bulanık kapak zemin, girişle kapanma, boşta tetikleme | — |

---

## M7 — Cam kart, ayarlar, onboarding, kısayollar

| ID | Görev | Kabul kriteri |
|---|---|---|
| M7-T1 | `GlassCard` (macOS 26 `glassEffect`, 14–15 materyal yedeği), kontroller | Her iki OS'ta görsel doğrulama |
| M7-T2 | Menü paneli tamamı (`ui_ux_brief.md` §4) | — |
| M7-T3 | Ayarlar penceresi 7 sekme, canlı uygulama, Önizle | — |
| M7-T4 | Onboarding 4 adım (sahne adımında görünürlük seçimi) + canlı demo sahne (telifsiz sentetik söz zaman çizgisi) | İzin reddi yolları test edildi |
| M7-T5 | Global kısayollar (Carbon) + çakışma uyarısı | — |
| M7-T6 | App Intents (Sahne seç, Sahne Modu, Işık aç/kapa, Stil değiştir) | Shortcuts'ta görünüyor |
| M7-T7 | Erişilebilirlik: Hareketi Azalt, Kontrastı Artır, VoiceOver etiketleri | Kontrol listesi |
| M7-T8 | Yerelleştirme TR/EN | Eksik anahtar yok |
| M7-T9 | Girişte başlat (`SMAppService`) | — |

---

## M8 — Sertleştirme ve dağıtım

| ID | Görev | Kabul kriteri |
|---|---|---|
| M8-T1 | Performans geçişi: Instruments, `os_signpost`; bütçeler (`trd.md` §6) | M1 Air'de toplam CPU ≤ %5 |
| M8-T2 | Hata enjeksiyonu testleri: her alt sistemi tek tek kapat (`app_flow.md` §13) | Hiçbirinde çökme yok, beklenen düşük mod |
| M8-T3 | `CapabilitiesService` (imzalı JSON, son geçerli kopya) | İmza bozuk dosya reddediliyor |
| ~~M8-T4~~ | Kaldırıldı: lisans sistemi yok (açık kaynak) | — |
| M8-T5 | Sparkle (EdDSA, appcast, kilitliyken ertele) | Eski sürümden güncelleme testi |
| M8-T6 | `release.sh`: arşiv → Developer ID imza → notarize → staple → dmg → appcast | Temiz bir Mac'te Gatekeeper uyarısız açılış |
| M8-T7 | Teşhis paketi (maskeli) | — |
| M8-T8 | Beta (10–20 kişi), geri bildirim döngüsü | Çökme oranı < %0.5 oturum |

---

## M9 — Deneysel kilit ekranı katmanı

M0-S5 başarılıysa yapılır; değilse v1.5'e veya iptale kayar.

| ID | Görev | Kabul kriteri |
|---|---|---|
| M9-T1 | `LockScreenBridge` framework: tüm private çağrılar tek dosyada, `dlsym` ile dinamik | Sembol yoksa `unsupported`, çökme yok |
| M9-T2 | OS build allowlist + `capabilities.json` engel listesi + `lockscreen_probe` tablosu | — |
| M9-T3 | Öz-test akışı (`app_flow.md` §7) | Başarısızlıkta kalıcı devre dışı + Stage önerisi |
| M9-T4 | Kilitliyken etkileşim yok (kart salt bilgi), kilit açılışında temiz kapanma | 100× kilit döngüsü |
| M9-T5 | Ayarlarda "Deneysel" bölümü + uyarı metinleri | — |
| M9-T6 | (Değerlendirme) Bridge'i XPC yardımcı sürece taşıma | Karar notu |

---

## M10 — v1.5

| ID | Görev |
|---|---|
| M10-T1 | `Translator` (Translation framework, macOS 15+; 14'te gizli), satır önbelleği, çeviri satırı UI |
| M10-T2 | `Romanizer` (Japonca `CFStringTokenizer`, diğerleri `.toLatin`) |
| M10-T3 | `ClipBuffer` (30 sn sahne kaydı + opsiyonel PCM, yalnız bellekte) |
| M10-T4 | Offscreen render + `AVAssetWriter` (9:16, 1:1), ilerleme UI, paylaşım menüsü |
| ~~M10-T5~~ | Kaldırıldı: ticari söz sağlayıcı uygulanmaz |

---

## 3. Definition of Done (her görev)

- [ ] Kod derleniyor, Swift 6 strict concurrency uyarısı yok
- [ ] Birim testleri yazıldı ve geçiyor
- [ ] Servisse: `HealthReporting` uygulandı, Sistem Durumu'nda görünüyor
- [ ] Hata yolu düşünüldü: alt sistem başarısız olursa ne olur? (`app_flow.md` §13 güncellendi)
- [ ] Kullanıcıya görünen metinler `Localizable.xcstrings` içinde (TR + EN)
- [ ] Hareketi Azalt / Kontrastı Artır etkisi kontrol edildi (görsel değişikliklerde)
- [ ] Performans bütçesi aşılmadı (render değişikliklerinde)

## 4. Karar bekleyen konular (geliştirmeyi durdurmaz)

| Konu | Ne zamana kadar | Varsayılan |
|---|---|---|
| Klipte şarkı sesi | M10 | Varsayılan kapalı |
| Çökme raporlama | M8 | Yok (yalnız teşhis paketi) |
| Söz gösterimi için hukuki görüş | Kamuya açık v1.0 sürümünden önce | — |

Kapatılan kararlar:
- Dağıtım modeli: açık kaynak, GPL-3.0-or-later; lisans anahtarı yok (M8-T4 kaldırıldı).
- Ürün adı / bundle ID / alan adı: `Lirevo`, `app.lirevo`, `https://lirevo.app` (`Config/App.xcconfig`).
- Ticari söz sağlayıcı: uygulanmaz (M10-T5 kaldırıldı); `LyricsProvider` genişletmeye açık.

## 5. İlk hafta için önerilen sıra

1. Gün 1: M1-T1, M1-T2 (iskelet çalışsın, menü ikonu görünsün).
2. Gün 2: M0-S2 (AppleScript) + M0-S1 (ses tap).
3. Gün 3: M0-S3 (LRCLIB korpus) + M0-S6 (Fisheye performansı).
4. Gün 4: M0-S5 (kilit ekranı) + M0-S4 (hizalama prototipi başlangıcı).
5. Gün 5: Spike raporlarını yaz, gerekirse bu planı güncelle, M1'in kalanına geç.
