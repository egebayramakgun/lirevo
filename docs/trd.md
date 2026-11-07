# TRD — Lirevo Teknik Gereksinimler

> PRD'deki özelliklerin nasıl inşa edileceği. Ana ilke: **her alt sistem bağımsız başarısız olabilir, uygulama asla bozulmaz.**

---

## 1. Teknoloji yığını

| Katman | Seçim | Not |
|---|---|---|
| Dil | Swift 6 (strict concurrency) | `actor` tabanlı servisler |
| UI | SwiftUI + AppKit | `MenuBarExtra(.window)`, ayar penceresi SwiftUI; overlay pencereleri AppKit `NSPanel` |
| Render | Metal (`CAMetalLayer`) + SwiftUI shader efektleri (`distortionEffect`, `layerEffect`, macOS 14+) | Işık çerçevesi saf Metal; söz katmanı SwiftUI + Metal shader. `.metal` dosyaları Xcode derlemesiyle derlenir (`swift build` derlemez); paket yerleşimi M4'te kararlaştırılır |
| Ses | Core Audio process tap (`CATapDescription`, macOS 14.2+) | Ekran kaydı izni gerektirmez |
| DSP | Accelerate / vDSP | FFT, spektral akı |
| Dil işleme | NaturalLanguage (`NLEmbedding`, `NLTokenizer`), `CFStringTokenizer` | Sembol eşleme, hece, romanizasyon |
| Çeviri | Translation framework (macOS 15+) | 14.x'te özellik gizlenir |
| Depolama | SQLite (GRDB) + JSON dosyaları + `UserDefaults` | Bkz. `backend_schema.md` |
| Ağ | `URLSession` async/await | Sadece LRCLIB, iTunes Search (kapak yedeği), capabilities, Sparkle appcast |
| Güncelleme | Sparkle 2 (EdDSA imzalı appcast) | |
| Kısayol | Carbon `RegisterEventHotKey` sarmalayıcı | İzin gerektirmez |
| Otomasyon | App Intents | Shortcuts entegrasyonu |
| Video | AVFoundation (`AVAssetWriter`) | Klip dışa aktarma (v1.5) |
| Test | Swift Testing + XCTest (UI), snapshot testleri | Snapshot için `ImageRenderer` tabanlı kendi küçük karşılaştırıcımız; üçüncü taraf kütüphane yok |
| Mimari | Yalnız `arm64` | `ARCHS = arm64`, `EXCLUDED_ARCHS = x86_64` |
| Min. OS | macOS 14.2 | Liquid Glass `if #available(macOS 26, *)` |

## 2. Dağıtım ve güvenlik modeli

- Ürün adı, bundle ID ve web sitesi tek yerde: `Config/App.xcconfig` (`PRODUCT_NAME = Lirevo`, `PRODUCT_BUNDLE_IDENTIFIER = app.lirevo`, `APP_WEBSITE = https://lirevo.app`). Geliştiriciye özel `DEVELOPMENT_TEAM` git dışındaki `Config/Local.xcconfig` içinde (örnek: `Config/Local.xcconfig.example`). Kod ve metinler adı `Bundle.main`/`AppInfo` üzerinden okur.
- Developer ID imzası, Hardened Runtime, `notarytool` ile notarization, dmg.
- **Sandbox kapalı** (Apple Events ve deneysel kilit katmanı nedeniyle). App Store hedefi yok.
- Entitlements: `com.apple.security.automation.apple-events`.
- Info.plist:
  - `LSUIElement = YES` (Dock ikonu yok)
  - `NSAppleEventsUsageDescription`
  - `NSAudioCaptureUsageDescription` (sistem sesi yakalama açıklaması; Xcode'daki güncel anahtar adını doğrula)
  - `LSMinimumSystemVersion = 14.2`
  - İzin açıklamalarında ürün adı geçmez (lokalize `InfoPlist.xcstrings` build değişkeni çözmez); metinler "Bu uygulama…" diye başlar.
- Ağ trafiği yalnızca HTTPS; kullanıcı verisi URL parametresine konmaz (parça adı/sanatçı istisnadır: bunlar LRCLIB sorgusu için zorunludur ve kişisel veri değildir).

## 3. Modül mimarisi

Xcode projesi + yerel Swift Package (`LirevoKit`) içinde modüller. Bağımlılık yönü yukarıdan aşağıya; alt modüller üsttekileri bilmez.

Yerelleştirme: Kullanıcıya görünen metin içeren her `LirevoKit` modülü kendi `Localizable.xcstrings` dosyasını taşır ve `Bundle.module` ile okur (TR + EN).

```
App (Lirevo.app)
 ├─ AppShell          MenuBarExtra, ayar penceresi, onboarding, AppCoordinator
 ├─ Presentation      OverlayWindowManager, PresentationHost'lar, VisibilityPolicy
 │   └─ LockScreenBridge   (ayrı target, private API, opsiyonel yüklenir)
 ├─ Rendering         RimLightRenderer, LyricsRenderer (4 stil), GlassCard
 ├─ SceneEngine       Scene, SceneState, FrameClock, Parametre karıştırıcı
 ├─ Analysis          AudioTap, FFTAnalyzer, BeatTracker, OnsetDetector, SyntheticPulse
 ├─ Lyrics            LyricsProvider zinciri, Parser'lar, WordTimingEstimator, OnsetAligner
 ├─ Palette           ArtworkLoader, PaletteExtractor
 ├─ NowPlaying        SpotifySource, MusicSource, PlaybackClock, SourceArbiter
 ├─ Language          SymbolMapper, Translator, Romanizer
 ├─ Platform          PowerGovernor, LockStateMonitor, DisplayAwake, ForegroundAppMonitor, Hotkeys
 ├─ Services          CapabilitiesService, UpdateService
 ├─ Persistence       Database (GRDB), PresetStore, SettingsStore
 ├─ Core              Modeller, EventBus, Logger, FeatureFlags, Health, AppInfo
 └─ CAtomics          C hedefi: stdatomic sarmalayıcıları (kilitsiz halka arabellek indeksleri)
```

### 3.1 Olay omurgası (EventBus)
- `AsyncStream` tabanlı, tipli olaylar. Her servis yalnız kendi olaylarını yayınlar.
- Olaylar ve yükleri `backend_schema.md` §5'te.
- Kural: Bir tüketici hata verirse yalnızca kendisi `degraded` olur, akış devam eder.

### 3.2 Sağlık (Health) modeli
Her servis bir `HealthReporting` protokolü uygular:

```swift
enum HealthState: Sendable { case ok, degraded(reason: String), unavailable(reason: String), disabled }
protocol HealthReporting: Sendable {
    var id: SubsystemID { get }
    var health: HealthState { get async }
}
```
Sistem Durumu paneli bunları listeler. `unavailable` bir alt sistem, sahne motoruna "bu girdi yok" bilgisini verir; motor yedek davranışa geçer.

### 3.3 Feature flags
- Yerel varsayılanlar (`FeatureFlags.default`) + uzaktan `capabilities.json` (yalnızca kapatabilir, açamaz; fail-open değil fail-safe: uzak dosya alınamazsa yerel varsayılan geçerli).
- Kritik bayraklar: `lockScreenBridge`, `lrclibProvider`, `translation`, `clipExport`, `symbolMapperML`.

## 4. Alt sistem tasarımları

### 4.1 NowPlaying

**Kaynaklar**
- `SpotifySource`: `DistributedNotificationCenter` → `com.spotify.client.PlaybackStateChanged`. Pozisyon ve kapak URL'si AppleScript ile (`player position`, `artwork url of current track`, `id of current track`, `duration` ms cinsinden).
- `MusicSource`: `com.apple.Music.playerInfo` bildirimi. Pozisyon `player position`, kapak `raw data of artwork 1 of current track`; boşsa iTunes Search API yedeği.
- AppleScript çağrıları ScriptingBridge veya `NSAppleScript` ile, **ayrı bir seri kuyrukta**, 750 ms zaman aşımıyla. Uygulama kapalıysa asla script gönderilmez (önce `NSRunningApplication` kontrolü; aksi halde script oynatıcıyı açar).

**PlaybackClock**
- Pozisyon örneği: `(position, machTime)`. Tahmin: `pos = sample.pos + (now - sample.machTime) * rate`.
- Çalarken 1 sn'de bir, olay geldiğinde anında yeniden örnekle.
- Sapma `|tahmin - örnek| > 300 ms` → seek kabul et, sert atla. Aksi halde 250 ms'de lineer kayma ile düzelt (görsel sıçrama olmasın).
- Parça başına kullanıcı offset'i eklenir (`track_offsets`).

**SourceArbiter**
- İki kaynak da çalıyorsa son durum değişikliği yapan aktif olur. Kullanıcı "Kaynağı sabitle" diyebilir.

**Hata/yedek**
- Automation izni yok → `unavailable`, Sistem Durumu'nda "İzin ver" (Sistem Ayarları > Gizlilik > Otomasyon derin bağlantısı).
- Script zaman aşımı 3 kez üst üste → kaynak 10 sn `degraded`, üstel geri çekilme.

### 4.2 Lyrics

**Sağlayıcı protokolü**
```swift
protocol LyricsProvider: Sendable {
    var id: ProviderID { get }
    var priority: Int { get }
    func fetch(_ query: TrackQuery) async throws -> LyricsDocument?
}
```

**Zincir (sırayla, ilk başarılı kazanır)**
1. `CacheProvider` (SQLite, pozitif sonuç 90 gün, negatif sonuç 3 gün TTL)
2. `LocalFileProvider` — `~/Music/Lyrics` ve kullanıcının seçtiği klasör; `.lrc`, Enhanced LRC (`<mm:ss.xx>` kelime etiketleri), `.ttml` (kelime `span` zamanları)
3. `LRCLIBProvider` — `GET /api/get` (sanatçı, parça, albüm, süre) → yoksa `GET /api/search` + puanlama
4. Sonuç yok → `.none` (söz katmanı gizlenir)

Ticari sağlayıcı uygulanmaz. `LyricsProvider` protokolü, ileride eklenecek sağlayıcılar için genişletmeye açık tutulur.

**Eşleştirme normalizasyonu**
- Başlıktan temizle: `- Remastered 2011`, `(feat. …)`, `[Live]`, `- Radio Edit` vb. (regex listesi testli).
- Sanatçı: ilk sanatçı, `&`/`,`/`feat` ayrımı.
- Parça kimliği süreden bağımsızdır: `sha1(norm_artist|norm_title)` (bkz. `backend_schema.md` §2). Süre ayrı alan olarak tutulur.
- Süre toleransı ±2 sn (önbellek ve sağlayıcı eşleştirmesinde); arama sonuçları için puan = başlık benzerliği (0.5) + sanatçı (0.3) + süre yakınlığı (0.2), eşik 0.75.

**Kelime zamanlaması**
- `exact`: Kaynak kelime zamanı verdiyse olduğu gibi.
- `estimated` (WordTimingEstimator):
  - Satır penceresi `[t_i, t_{i+1})`; son satırda `t_i + min(8 sn, 0.45 sn × hece)`.
  - Satır sonunda %12 nefes payı.
  - Kelime ağırlığı = hece sayısı (dil duyarlı; Türkçe/İspanyolca için sesli harf sayımı, İngilizce için sesli grup + sessiz-e kuralı, CJK için karakter sayısı) + noktalama sonrası duraklama ağırlığı 0.5.
- `aligned` (OnsetAligner): Ses analizi mevcutsa, vokal bandında (300–3400 Hz) spektral akı ile bulunan başlangıçlar satır penceresinde toplanır; tahmini kelime başlangıçları ±120 ms içindeki en yakın başlangıca, sıra (monoton artış) korunarak dinamik programlama ile eşlenir. Eşleşme oranı < %40 ise `estimated` olarak kalır.
- Hizalama canlı yapılır (şarkı çalarken), sonuçlar satır satır önbelleğe yazılır; şarkı ikinci kez çalındığında hizalanmış zamanlar hazırdır.

**Parser'lar**: LRC, Enhanced LRC, TTML. Her biri bağımsız birim testli; bozuk girdide `throw`, zincir bir sonrakine geçer.

### 4.3 Palette
- Kapak: Spotify URL → indir (önbellek, 300×300 küçült). Music → raw data. Yedek: iTunes Search API `entity=song`.
- Çıkarım: 64×64'e küçült → OKLab'da k-means (k=5, 8 iterasyon, deterministik tohum) → küme ağırlığı × kroma ile puanla.
  - `primary`: en yüksek puan
  - `highlight`: primary'den ΔE ≥ 25 olan en canlı
  - `secondary`: düşük kroma, söz ikincil metni için
- Çıkarılan 3 rolün sahnedeki 5 renk rolüne eşlenmesi: `backend_schema.md` §5.1.
- Kontrast koruyucu: söz metni koyu zemin üzerinde ≥ 4.5:1; sağlanmazsa L kanalını yükselt.
- Renk geçişi: parça değişiminde 800 ms OKLab interpolasyon.

### 4.4 Analysis (ses)
- `AudioTap`: Global (tüm süreçler) process tap, stereo → mono, 48 kHz. Yalnızca bir sunum hedefi görünürken ve müzik çalarken açık; aksi halde tap yok edilir.
- `FFTAnalyzer`: 2048 örnek, hop 512, Hann pencere, vDSP. Çıktı: 32 log-ölçekli bant, RMS, spektral akı.
- `BeatTracker`: Spektral akı tepe noktaları + uyarlanabilir eşik, tempo tahmini (otokorelasyon, 70–180 BPM).
- `EnergyEnvelope`: 2 sn ve 8 sn hareketli ortalama → "nakarat/yükseliş" algısı (kısa/uzun oranı > 1.3).
- `SyntheticPulse` (yedek): Ses izni yoksa; kelime başlangıçları + sabit 0.5 Hz nefes dalgası ile nabız üretir.
- İş parçacığı: Ses geri çağrısı gerçek zamanlı iş parçacığında yalnızca halka arabelleğe yazar; FFT ayrı bir yüksek öncelikli kuyrukta. Gerçek zamanlı iş parçacığında bellek ayırma/kilit yok.

### 4.5 SceneEngine
- `Scene` (preset) = statik parametreler. `SceneState` = her karede hesaplanan dinamik değerler.
- Girdiler: `PlaybackClock`, `LyricsTimeline`, `Palette`, `AnalysisFrame`, `PowerBudget`, `VisibilityState`.
- Çıktı (`SceneFrame`, her kare):
```swift
struct SceneFrame: Sendable {
    var time: TimeInterval
    var colors: ResolvedPalette
    var rim: RimParams         // intensity, thickness, glow, hueShift, pulse
    var lyrics: LyricsFrame    // aktif satır, aktif kelime, kelime ilerlemesi 0..1, sonraki satırlar
    var card: CardParams
}
```
- Söze duyarlı ışık (N-02): `rim.pulse = max(beatPulse × beatWeight, wordOnsetPulse × wordWeight)`; enerji yükselişinde `intensity` +%20.
- Flaş sınırlayıcı: `intensity` için saniyedeki büyük (> %20 parlaklık) değişim sayısı 3'ü aşamaz; aşarsa düşük geçiren filtre.
- `FrameClock`: `NSScreen.displayLink(target:selector:)` (macOS 14+), ekran başına. Hedef fps PowerGovernor'dan.

### 4.6 Rendering

**RimLightRenderer (Metal)**
- Ekran başına bir `CAMetalLayer`. Sadece kenar bandı çizilir: dış dikdörtgenden `thickness + glow` içeri giren bir şerit mesh'i (pikselin ~%5–10'u).
- Fragment shader: yuvarlatılmış dikdörtgen SDF (ekran köşe yarıçapı), notch kesiti SDF ile birleşim, mesafeye göre üstel düşüş, gradient açısı + zaman ile hue kayması.
- Notch alanı: `NSScreen.safeAreaInsets` + `auxiliaryTopLeftArea`/`auxiliaryTopRightArea` ile notch dikdörtgeni hesaplanır.
- Parametre değişmiyorsa ve mod `Sabit` ise render durur (tek kare, `presentsWithTransaction`).

**LyricsRenderer (SwiftUI + Metal shader)**
- Ortak görünüm modeli: `LyricsFrame`. Her stil ayrı `View`.
- `Ship`: Kelimeler satır satır duvar olarak yığılır; `rotation3DEffect` + derinliğe göre opaklık; aktif kelime highlight rengiyle dolar (maske genişliği = kelime ilerlemesi).
- `Fisheye`: Dikey yığın, `distortionEffect` ile dışbükey lens (`[[stitchable]]` shader, yarıçap ve güç parametreli); aktif kelime merkezde ve en büyük.
- `Fisheye Visual`: Fisheye + SymbolMapper simgeleri.
- `Visual`: Düz satırlar, eşleşen kelimenin yanında SF Symbol/emoji "pop" (yay animasyonu, 220 ms).
- `estimated` kalitede kelime geçişi yumuşak dolma; `exact/aligned` kalitede keskin yanma.
- Hareketi Azalt açıksa: 3D ve lens kapalı, yalnız renk geçişi.

**GlassCard**
- macOS 26+: SwiftUI `glassEffect`. 14–15: `NSVisualEffectView` (`.hudWindow`, `.behindWindow`).
- İçerik: kapak, başlık, sanatçı, ilerleme, önceki/oynat/sonraki (AppleScript komutları).

### 4.7 Presentation

**OverlayWindowManager**
- Ekran başına iki `NSPanel`: `rim` ve `content` (sözler + kart).
- Ortak ayarlar: `styleMask = [.borderless, .nonactivatingPanel]`, `isOpaque = false`, `backgroundColor = .clear`, `hasShadow = false`, `ignoresMouseEvents = true` (kart etkileşimli olduğunda kart bölgesi için ayrı küçük panel), `collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]`, `sharingType = .none` (ekran paylaşımı dışı bırakma girişimi; tüm yakalama yöntemlerinde garanti değildir).
- Ekran değişimi: `NSApplication.didChangeScreenParametersNotification` → pencereleri yeniden kur.

**PresentationHost protokolü**
```swift
protocol PresentationHost: AnyObject {
    var kind: HostKind { get }          // .desktop, .stage, .lockScreen
    func isSupported() async -> Bool
    func activate(screens: [NSScreen]) async throws
    func deactivate() async
}
```
- `DesktopHost`: yukarıdaki paneller, seviye `.statusBar` (sözler), `.screenSaver - 1` (ışık).
- `StageHost`: Tam ekran opak pencere, seviye `.screenSaver`; herhangi bir tuş veya 8 pt üzeri fare hareketi ile kapanır. Stage bir kilit değildir. Mac'i programla kilitlemenin bilinen yolları private API olduğu için kullanılmaz; bunun yerine Stage ilk açıldığında kullanıcıya bilgi kartı gösterilir ("Uzaklaşacaksan ⌃⌘Q ile kilitle; Deneysel kilit ekranı katmanı açıksa sahne kilit ekranında da devam eder"). Bkz. Açık konu T-3.
- `LockScreenHost` (ayrı target `LockScreenBridge`): Private SkyLight alanı yaklaşımı. Kurallar:
  1. Varsayılan kapalı, ayarlarda "Deneysel" etiketiyle.
  2. `isSupported()`: macOS build numarası yerel allowlist'te **ve** `capabilities.json` bunu kapatmamış **ve** sembol çözümleme (`dlsym`) başarılı.
  3. Tüm private çağrılar tek dosyada, `dlsym` ile dinamik; sembol yoksa `unsupported` döner, çökme yok.
  4. Öz-test: etkinleştirmede test penceresi oluşturulur, pencere numarası ve alan ataması doğrulanır; başarısızsa kalıcı olarak (o OS build için) devre dışı + kullanıcıya Sahne Modu önerisi.
  5. Kilit sırasında çökme koruması: bridge ayrı bir yardımcı süreçte (XPC servis) çalıştırılabilir → v1'de aynı süreçte, v1.5'te XPC'ye taşınması değerlendirilecek (bkz. Plan M9).

**VisibilityPolicy** (durum makinesi, ayrıntı `app_flow.md` §6)
- Girdiler: kilit durumu, ekran uyku, çalma durumu, kullanıcı modu (kilitliyken/her zaman), ön plan uygulama kuralları, panik gizle, Stage aktif mi.
- Çıktı: her hedef için `visible | hidden`, render bütçesi.

### 4.8 Platform

| Servis | Uygulama |
|---|---|
| `LockStateMonitor` | `DistributedNotificationCenter`: `com.apple.screenIsLocked` / `com.apple.screenIsUnlocked`; başlangıçta `CGSessionCopyCurrentDictionary()` → `CGSSessionScreenIsLocked` |
| Ekran uyku | `NSWorkspace.screensDidSleepNotification` / `screensDidWakeNotification` |
| `DisplayAwake` | `IOPMAssertionCreateWithName(kIOPMAssertPreventUserIdleDisplaySleep)`; yalnızca (çalıyor ∧ görünür hedef var); duraklatmadan 30 sn sonra bırak |
| `PowerGovernor` | `ProcessInfo.isLowPowerModeEnabled`, `thermalState`, güç kaynağı (IOKit `IOPSCopyPowerSourcesInfo`). Bütçe: AC 60/120 fps, pil 30 fps, Düşük Güç 24 fps + glow kısıtlı, termal `.serious` → ışık sabit moda |
| `ForegroundAppMonitor` | `NSWorkspace.didActivateApplicationNotification`; kural listesi (Zoom, Teams, Meet tarayıcı sekmesi ayırt edilemez → tarayıcı için kural yok; Keynote sunum, FaceTime). Tam ekran tespiti: ön plan uygulamasının penceresi ekranı kaplıyor mu (`CGWindowListCopyWindowInfo` sınırları; pencere adı okunmaz, ekran kaydı izni gerekmez) |
| `Hotkeys` | Carbon `RegisterEventHotKey`; çakışmada kullanıcıya uyarı |
| Odak | `INFocusStatusCenter` yetkisi istenirse "Odak açıkken sessiz sahne" |

### 4.9 Language
- `SymbolMapper`:
  1. El ile seçilmiş tohum sözlük (~300 kelime, TR+EN) → SF Symbol adı veya emoji.
  2. Genişletme: `NLEmbedding.wordEmbedding(for:)` ile kelimenin tohum kelimelere kosinüs benzerliği > 0.62 ise eşle.
  3. Her SF Symbol `NSImage(systemSymbolName:)` ile doğrulanır; yoksa emoji.
  4. Sonuçlar `symbol_cache` tablosunda.
  - Not: Rakip ürünün eşleme tablosu kopyalanmaz.
- `Translator`: Translation framework, satır bazlı toplu çeviri, sonuç önbellekte. Dil paketi yoksa sistem indirme istemi.
- `Romanizer`: Japonca için `CFStringTokenizer` (`kCFStringTokenizerAttributeLatinTranscription`), Korece/Kiril/Yunanca için `applyingTransform(.toLatin)`.

### 4.10 Klip dışa aktarma (v1.5)
- Ekran kaydı **yapılmaz**. Bunun yerine çalma sırasında hafif bir "sahne kaydı" halka arabelleği tutulur: son 30 sn'nin `AnalysisFrame` özeti (30 Hz), pozisyon, palet. İsteğe bağlı: tap'ten gelen PCM (30 sn ≈ 5.6 MB, yalnız bellekte).
- Dışa aktarmada sahne 1080×1920 boyutunda offscreen yeniden render edilir (SwiftUI `ImageRenderer` + Metal doku → `CVPixelBuffer` → `AVAssetWriter` H.264/HEVC).
- Deterministik: aynı girdiler aynı videoyu üretir. Gerçek zamanlıdan hızlı çalışır.

### 4.11 Services
- `CapabilitiesService`: Günde bir `capabilities.json`; ETag ile; imza doğrulama (Ed25519, Sparkle anahtarından ayrı).
- `UpdateService`: Sparkle `SPUStandardUpdaterController`.

## 5. Eşzamanlılık modeli
- `@MainActor`: UI, pencere yönetimi, SceneEngine'in kare çıktısını tüketen renderer'lar.
- `actor`: `NowPlayingService`, `LyricsService`, `PaletteService`, `Database`.
- Gerçek zamanlı ses: C-uyumlu, kilitsiz halka arabellek. İndeksler `CAtomics` C hedefindeki `stdatomic` sarmalayıcılarıyla tutulur (`swift-atomics` üçüncü taraf bağımlılık; `Synchronization.Atomic` macOS 15+ gerektirir, alt sınır 14.2).
- Kare hesaplama: `SceneEngine` kare başına saf fonksiyon, `MainActor` üzerinde ≤ 0.5 ms bütçe.

## 6. Performans bütçeleri

| Bileşen | Bütçe (M1, 60 fps) |
|---|---|
| Ses tap + FFT | ≤ %1 CPU |
| SceneEngine | ≤ 0.5 ms/kare |
| Işık render | GPU ≤ 1 ms/kare/ekran |
| Söz render | GPU ≤ 2 ms/kare |
| Toplam CPU | ≤ %5 ortalama |
| Ağ | Parça başına ≤ 2 istek (söz + kapak), önbellek isabetinde 0 |

Ölçüm: Instruments (Time Profiler, Metal System Trace, Energy Log) + uygulama içi `os_signpost` aralıkları.

## 7. Gözlemlenebilirlik
- `os.Logger`: subsystem = bundle ID (`app.lirevo`, `Bundle.main`'den okunur), alt sistem başına kategori.
- Sistem Durumu panelinde "Teşhis paketini kopyala": sürüm, OS, sağlık durumları, son 200 log satırı (kişisel veri yok; parça adları maskelenir).
- Analytics yok. Çökme raporu: opt-in, Sparkle ile aynı sitede basit uç nokta veya üçüncü taraf (karar: açık).

## 8. Test stratejisi

| Seviye | Kapsam |
|---|---|
| Birim | Parser'lar (LRC/ELRC/TTML), normalizasyon, WordTimingEstimator, OnsetAligner (sentetik sinyal), PaletteExtractor (sabit görseller), VisibilityPolicy (tüm geçişler), flaş sınırlayıcı |
| Entegrasyon | Sahte `NowPlayingSource` ile uçtan uca SceneFrame üretimi; LRCLIB mock sunucu |
| Snapshot | 4 söz stili × 3 palet × açık/koyu, Hareketi Azalt |
| Performans | 10 dk çalma senaryosu, CPU/GPU eşik testi (CI'da değil, sürüm öncesi) |
| Manuel | İzin reddi akışları, çoklu ekran tak/çıkar, kilit/aç döngüsü 50×, uyku/uyanma |

Test korpusu: 200 parçalık liste (TR/EN/ES/JP/KR) — kaynak isabet oranı ve zamanlama hatası raporu üreten komut satırı aracı (`LirevoBench`).

## 9. Açık teknik konular

| ID | Konu | Not |
|---|---|---|
| T-1 | Kilit ekranı katmanının hangi macOS build'lerinde çalıştığı | M0 spike'ı ile belirlenecek |
| T-2 | `NSAudioCaptureUsageDescription` ve tap izni akışının macOS 14.2/15/26'daki davranış farkları | M0 spike'ı |
| T-3 | Stage Modu'ndan çıkışta Mac'i public API ile kilitleme yolu | Yoksa ayar önerisiyle yetinilecek |
| T-4 | `sharingType = .none`'ın güncel yakalama API'lerinde etkisi | Otomatik gizleme asıl korumadır |
