# Backend & Data Schema — Lirevo

> Lirevo **local-first** bir uygulamadır; kendi sunucusu yoktur. "Backend" burada şunları kapsar:
> 1. Yerel veritabanı (SQLite/GRDB)
> 2. Dosya tabanlı veriler (sahneler, ayarlar)
> 3. Uygulama içi alan modelleri ve olaylar
> 4. Dış servis sözleşmeleri (LRCLIB, iTunes Search)
> 5. Statik olarak barındırılan dosyalar (appcast, capabilities)

---

## 1. Depolama yerleşimi

```
~/Library/Application Support/Lirevo/
├─ lirevo.sqlite              # önbellekler ve parça bazlı veriler
├─ scenes/                  # kullanıcı sahneleri (*.lirevoscene, JSON)
├─ symbols/seed.json        # paketle gelen tohum sözlüğün kullanıcı eklemeleri
└─ diagnostics/             # son teşhis paketleri (maks. 5)

~/Library/Caches/Lirevo/
└─ artwork/                 # küçültülmüş kapaklar (300×300 HEIC), LRU 200 MB

UserDefaults (app.lirevo)
└─ basit tercihler (bkz. §3)
```

- Klasör adları (`Lirevo`) ve UserDefaults alanı (bundle ID) kodda sabit yazılmaz; `AppInfo` üzerinden `PRODUCT_NAME` / `PRODUCT_BUNDLE_IDENTIFIER`'dan türetilir.
- Keychain v1'de kullanılmaz (lisans ve ticari sağlayıcı anahtarı yok).

Kural: Önbellekteki her şey silinebilir olmalı; silindiğinde uygulama yeniden üretir.

## 2. SQLite şeması (GRDB migration v1)

```sql
-- Parça kimliği: kaynaktan bağımsız normalize anahtar
CREATE TABLE track (
    id               TEXT PRIMARY KEY,          -- sha1(norm_artist|norm_title); süre kimliğe girmez
    source           TEXT NOT NULL,             -- 'spotify' | 'music'
    source_track_id  TEXT,                      -- spotify:track:… veya Music persistent ID
    title            TEXT NOT NULL,
    artist           TEXT NOT NULL,
    album            TEXT,
    duration_ms      INTEGER NOT NULL,          -- eşleştirmede ±2 sn tolerans
    norm_title       TEXT NOT NULL,
    norm_artist      TEXT NOT NULL,
    first_seen_at    INTEGER NOT NULL,          -- unix sn
    last_played_at   INTEGER NOT NULL
);
CREATE INDEX idx_track_source ON track(source, source_track_id);

-- Söz belgesi (önbellek)
CREATE TABLE lyrics_document (
    track_id         TEXT PRIMARY KEY REFERENCES track(id) ON DELETE CASCADE,
    status           TEXT NOT NULL,             -- 'found' | 'not_found' | 'unsynced_only'
    provider         TEXT,                      -- 'local' | 'lrclib' (protokol genişletmeye açık)
    provider_ref     TEXT,                      -- örn. LRCLIB id
    language         TEXT,                      -- BCP-47, NLLanguageRecognizer ile
    timing_quality   TEXT,                      -- 'exact' | 'aligned' | 'estimated'
    is_instrumental  INTEGER NOT NULL DEFAULT 0,
    raw_format       TEXT,                      -- 'lrc' | 'elrc' | 'ttml' | 'plain'
    raw_payload      BLOB,                      -- zlib sıkıştırılmış ham metin
    fetched_at       INTEGER NOT NULL,
    expires_at       INTEGER NOT NULL           -- found: +90 gün, not_found: +3 gün
);

-- Ayrıştırılmış satırlar
CREATE TABLE lyric_line (
    track_id         TEXT NOT NULL REFERENCES lyrics_document(track_id) ON DELETE CASCADE,
    idx              INTEGER NOT NULL,
    start_ms         INTEGER NOT NULL,
    end_ms           INTEGER NOT NULL,
    text             TEXT NOT NULL,
    translation      TEXT,                      -- v1.5
    translation_lang TEXT,
    romanized        TEXT,                      -- v1.5
    PRIMARY KEY (track_id, idx)
);

-- Kelime zamanları (exact veya hizalanmış/ tahmini)
CREATE TABLE lyric_word (
    track_id         TEXT NOT NULL,
    line_idx         INTEGER NOT NULL,
    idx              INTEGER NOT NULL,
    start_ms         INTEGER NOT NULL,
    end_ms           INTEGER NOT NULL,
    text             TEXT NOT NULL,
    quality          TEXT NOT NULL,             -- 'exact' | 'aligned' | 'estimated'
    PRIMARY KEY (track_id, line_idx, idx),
    FOREIGN KEY (track_id, line_idx) REFERENCES lyric_line(track_id, idx) ON DELETE CASCADE
);

-- Kullanıcının parça bazlı senkron düzeltmesi
CREATE TABLE track_offset (
    track_id         TEXT PRIMARY KEY REFERENCES track(id) ON DELETE CASCADE,
    offset_ms        INTEGER NOT NULL CHECK (offset_ms BETWEEN -2000 AND 2000),
    updated_at       INTEGER NOT NULL
);

-- Palet önbelleği
CREATE TABLE palette_cache (
    artwork_key      TEXT PRIMARY KEY,          -- sha1(kapak baytları) veya kapak URL'si
    primary_oklab    TEXT NOT NULL,             -- "L,a,b"
    highlight_oklab  TEXT NOT NULL,
    secondary_oklab  TEXT NOT NULL,
    is_monochrome    INTEGER NOT NULL,
    created_at       INTEGER NOT NULL
);

-- Kelime → simge eşleme önbelleği
CREATE TABLE symbol_cache (
    lang             TEXT NOT NULL,
    word             TEXT NOT NULL,             -- küçük harf, lemma
    symbol           TEXT,                      -- SF Symbol adı; NULL = eşleşme yok
    emoji            TEXT,
    source           TEXT NOT NULL,             -- 'seed' | 'embedding' | 'user'
    score            REAL,
    PRIMARY KEY (lang, word)
);

-- Kilit ekranı katmanı öz-test sonuçları (OS build başına)
CREATE TABLE lockscreen_probe (
    os_build         TEXT PRIMARY KEY,          -- örn. '25B78'
    result           TEXT NOT NULL,             -- 'ok' | 'failed' | 'disabled_remote'
    detail           TEXT,
    probed_at        INTEGER NOT NULL
);

-- Klip özelliği için dışa aktarma geçmişi (v1.5)
CREATE TABLE clip_export (
    id               TEXT PRIMARY KEY,          -- UUID
    track_id         TEXT REFERENCES track(id) ON DELETE SET NULL,
    file_path        TEXT NOT NULL,
    duration_s       INTEGER NOT NULL,
    layout           TEXT NOT NULL,             -- 'portrait_9_16' | 'square'
    include_audio    INTEGER NOT NULL,
    created_at       INTEGER NOT NULL
);
```

**Parça kimliği ve süre**: Kimlik yalnızca normalize sanatçı + başlıktan üretilir; böylece Spotify ve Müzik arasındaki ±1 sn süre farkları aynı parçayı ayrı kayıtlara bölmez ve `track_offset` korunur. Süre (`duration_ms`) ayrı tutulur; önbellekten söz kullanılırken ve sağlayıcı sonuçları eşleştirilirken ±2 sn tolerans uygulanır. Tolerans dışındaki önbellek kaydı (ör. aynı adlı farklı sürüm) isabet sayılmaz ve zincir devam eder.

**Bakım işi** (açılışta + 24 saatte bir, arka planda):
- `expires_at < now` olan `lyrics_document` kayıtlarını sil (cascade).
- 180 gündür çalınmamış `track` kayıtlarını sil (offset'i olanlar hariç).
- `PRAGMA optimize`.

**Migration kuralı**: Her şema değişikliği yeni bir GRDB migration'ı; önbellek tablolarında uyumsuzlukta tabloyu düşürüp yeniden oluşturmak kabul edilir, `track_offset` asla düşürülmez.

## 3. UserDefaults anahtarları

| Anahtar | Tip | Varsayılan |
|---|---|---|
| `onboarding.completed` | Bool | false |
| `scene.activeId` | String | `builtin.cinema` |
| `visibility.mode` | String (`always` \| `stageOnly` \| `lockedOnly`) | `always` |
| `display.keepAwake` | Bool | true (çalarken ve bir hedef görünürken; `app_flow.md` §6) |
| `stage.idleMinutes` | Int (0 = kapalı) | 0 |
| `autoHide.fullscreen` / `.videoCall` / `.presentation` | Bool | true |
| `autoHide.customBundleIds` | [String] | [] |
| `power.limitOnBattery` | Bool | true |
| `lyrics.providerOrder` | [String] | `["local","lrclib"]` |
| `lyrics.localFolder` | Bookmark Data | ~/Music/Lyrics |
| `experimental.lockScreen` | Bool | false |
| `source.pinned` | String? | nil |
| `launchAtLogin` | Bool | false (SMAppService) |
| `screens.config` | Data (JSON, ekran UUID → ayar) | {} |

## 4. Sahne (preset) dosya formatı

Dosya uzantısı `.lirevoscene`, UTF-8 JSON. Şema sürümlüdür.

```json
{
  "schema": 1,
  "id": "user.7f3c2a",
  "name": "Gece sürüşü",
  "builtin": false,
  "lyrics": {
    "enabled": true,
    "style": "fisheye",
    "font": "sfProRounded",
    "weight": "semibold",
    "size": "L",
    "position": "center",
    "icons": { "enabled": true, "preferEmoji": false },
    "translation": { "enabled": false, "targetLang": "tr" },
    "romanize": false
  },
  "rim": {
    "enabled": true,
    "animation": "lyricReactive",
    "gradient": { "stops": 2, "ratio": 0.6 },
    "thickness": 12,
    "glow": 55,
    "intensity": 80,
    "notch": "wrap",
    "softFlash": true
  },
  "card": {
    "show": "lockedAndStage",
    "position": "bottomCenter",
    "size": "compact",
    "controls": true
  },
  "color": {
    "mode": "album",
    "saturationBoost": 0.0,
    "manual": {
      "lyric": "#F5F5F7",
      "highlight": "#FF6B9A",
      "secondary": "#8E8E93",
      "rimPrimary": "#FF6B9A",
      "rimSecondary": "#6B8BFF"
    }
  },
  "motion": {
    "beatWeight": 0.7,
    "wordWeight": 0.4,
    "drift": true
  }
}
```

Doğrulama kuralları:
- `style` ∈ `ship | fisheye | fisheyeVisual | visual`
- `rim.animation` ∈ `musicSync | lyricReactive | idle | breathe`
- `thickness` 1–120, `glow`/`intensity` 0–100, `ratio` 0–1, `beatWeight`/`wordWeight` 0–1
- Bilinmeyen alanlar yok sayılır (ileri uyumluluk); eksik alanlar varsayılanla doldurulur.
- `schema` > desteklenen sürüm ise içe aktarma reddedilir, kullanıcıya "uygulamayı güncelle" denir.

## 5. Alan modelleri (Swift)

```swift
enum PlayerSource: String, Codable, Sendable { case spotify, music }

struct Track: Hashable, Sendable {
    let id: String               // normalize anahtar
    let source: PlayerSource
    let sourceTrackID: String?
    let title: String
    let artist: String
    let album: String?
    let duration: TimeInterval
    let artwork: ArtworkRef?
}

enum ArtworkRef: Hashable, Sendable { case url(URL), data(Data) }

enum PlaybackState: Sendable { case playing, paused, stopped }

struct PlaybackSample: Sendable {
    let position: TimeInterval
    let machTime: UInt64
    let state: PlaybackState
}

enum TimingQuality: String, Codable, Sendable { case exact, aligned, estimated }

struct LyricWord: Sendable { let text: String; let start: TimeInterval; let end: TimeInterval; var quality: TimingQuality }
struct LyricLine: Sendable { let index: Int; let start: TimeInterval; let end: TimeInterval; let text: String; var words: [LyricWord]; var translation: String?; var romanized: String? }

struct LyricsDocument: Sendable {
    let trackID: String
    let provider: ProviderID
    let language: String?
    let isInstrumental: Bool
    var lines: [LyricLine]
    var quality: TimingQuality   // belgenin en düşük kalitesi
}

struct ResolvedPalette: Sendable, Equatable {
    var lyric: OKLab; var highlight: OKLab; var secondary: OKLab
    var rimPrimary: OKLab; var rimSecondary: OKLab
}

struct AnalysisFrame: Sendable {
    let time: TimeInterval
    let rms: Float
    let bands: [Float]        // 32 log bant, 0..1
    let flux: Float
    let beat: Bool
    let beatConfidence: Float
    let tempoBPM: Float?
    let energyRatio: Float    // kısa/uzun pencere
    let isSynthetic: Bool     // SyntheticPulse üretimi mi
}
```

### 5.1 Palet rol eşlemesi

`PaletteExtractor` kapaktan 3 rol çıkarır (`primary`, `highlight`, `secondary`; bkz. `trd.md` §4.3). Sahnenin kullandığı 5 rol (`ResolvedPalette`) bunlardan şöyle türetilir:

| Sahne rolü | Albüm modunda kaynak | Not |
|---|---|---|
| `lyric` | `primary`'nin tonu (hue), OKLab L ≈ 0.95, kroma ≤ 0.03 | Çok açık, neredeyse beyaz; albüm tonunu hafifçe taşır |
| `highlight` | `highlight` | Aktif kelime, ilerleme çubuğu |
| `secondary` | `secondary` | Gelecek/ikincil metin |
| `rimPrimary` | `primary` | Işık gradient'inin 1. rengi |
| `rimSecondary` | `highlight` | Işık gradient'inin 2. rengi |

- Kontrast koruyucu (`trd.md` §4.3, `ui_ux_brief.md` §9) eşlemeden **sonra** uygulanır.
- Monokrom kapakta (`is_monochrome = 1`) `highlight` ve `rimSecondary` sahnenin nötr aksan rengine (sıcak beyaz) düşer.
- Elle renk modunda (`color.mode = "manual"`) beş rolün her biri bağımsız ayarlanır (`color.manual.*`, §4); eşleme uygulanmaz.
- `saturationBoost` albüm modunda yalnız `highlight`, `rimPrimary` ve `rimSecondary` kromasına uygulanır; `lyric` etkilenmez.

## 6. Olay kataloğu (EventBus)

| Olay | Yayınlayan | Yük | Tüketenler |
|---|---|---|---|
| `playbackChanged` | NowPlaying | `PlaybackSample`, `Track?` | SceneEngine, VisibilityPolicy, DisplayAwake, AudioTap |
| `trackChanged` | NowPlaying | `Track` | Lyrics, Palette, SceneEngine, ClipBuffer |
| `seekDetected` | PlaybackClock | `from`, `to` | SceneEngine |
| `lyricsReady` | Lyrics | `LyricsDocument` | SceneEngine, Translator |
| `lyricsUnavailable` | Lyrics | `trackID`, `reason` | SceneEngine, Menü |
| `wordTimingsImproved` | OnsetAligner | `trackID`, `lineIndex` | SceneEngine |
| `paletteReady` | Palette | `ResolvedPalette` | SceneEngine |
| `analysisFrame` | Analysis | `AnalysisFrame` (≈ 94 Hz) | SceneEngine, OnsetAligner, ClipBuffer |
| `lockStateChanged` | LockStateMonitor | `isLocked` | VisibilityPolicy, Presentation |
| `screensChanged` | Platform | `[ScreenDescriptor]` | Presentation |
| `screenSleepChanged` | Platform | `isAsleep` | VisibilityPolicy |
| `foregroundAppChanged` | Platform | `bundleID`, `isFullscreen` | VisibilityPolicy |
| `powerBudgetChanged` | PowerGovernor | `PowerBudget` | SceneEngine, Renderer'lar |
| `sceneChanged` | SceneStore | `Scene` | SceneEngine |
| `healthChanged` | Herhangi bir servis | `SubsystemID`, `HealthState` | Sistem Durumu, Menü ikonu |
| `capabilitiesUpdated` | CapabilitiesService | `Capabilities` | FeatureFlags |

## 7. Dış servis sözleşmeleri

### 7.1 LRCLIB
Ücretsiz, anahtarsız, topluluk tabanlı söz veritabanı. `User-Agent` başlığında uygulama adı, sürüm ve iletişim URL'si (`APP_WEBSITE`; hepsi `AppInfo`'dan) gönderilir. Kullanıcının e-postası veya başka kişisel veri gönderilmez.

**Tam eşleşme**
```
GET https://lrclib.net/api/get?artist_name={a}&track_name={t}&album_name={al}&duration={sn}
```
**Arama**
```
GET https://lrclib.net/api/search?track_name={t}&artist_name={a}
```
Beklenen yanıt alanları (kullandıklarımız):
```json
{
  "id": 3396226,
  "trackName": "…",
  "artistName": "…",
  "albumName": "…",
  "duration": 233,
  "instrumental": false,
  "plainLyrics": "…",
  "syncedLyrics": "[00:17.12] …"
}
```
- 404 → bulunamadı.
- Zaman aşımı 4 sn, en fazla 1 yeniden deneme.
- Rate limit veya 5xx → sağlayıcı 10 dk `degraded`.
- Not: Uç noktaların ve alanların güncel hâli geliştirme başında LRCLIB dokümantasyonundan doğrulanmalı.

### 7.2 iTunes Search API (kapak yedeği)
```
GET https://itunes.apple.com/search?term={artist}+{title}&entity=song&limit=5
```
Kullanılan alan: `artworkUrl100` (URL'deki `100x100` → `600x600` ile büyütülür). Yalnızca Müzik kapak verisi boş geldiğinde.

### 7.3 Ek söz sağlayıcıları
Depoda ticari veya anahtarlı söz sağlayıcı yoktur. `LyricsProvider` protokolü genişletmeye açıktır; eklenecek bir sağlayıcı yalnız bu protokolü uygular ve ToS'a aykırı uç nokta kullanmaz.

## 8. Statik barındırılan dosyalar

`APP_WEBSITE` alan adında (`https://lirevo.app/`):

### 8.1 `appcast.xml` (Sparkle)
Standart Sparkle 2 appcast; her öğe `sparkle:edSignature`, `sparkle:minimumSystemVersion="14.2"`. Yalnız arm64 derlemesi.

### 8.2 `capabilities.json` (uzaktan kapatma anahtarı)
Ed25519 ile imzalı; imza `capabilities.json.sig` dosyasında. Uygulama yalnızca **kapatma** yönünde uygular.

```json
{
  "schema": 1,
  "issuedAt": "2026-11-07T00:00:00Z",
  "minAppVersion": "1.0.0",
  "features": {
    "lockScreenBridge": {
      "enabled": true,
      "blockedOSBuilds": ["25C5048a"],
      "blockedAppVersions": []
    },
    "lrclibProvider": { "enabled": true },
    "translation": { "enabled": true },
    "clipExport": { "enabled": true }
  },
  "message": null
}
```
- Alınamaz veya imza geçersizse: yerel varsayılanlar + son geçerli kopya.
- `message` doluysa (örn. kritik hata bilgisi) menüde tek seferlik gösterilir.

## 9. Gizlilik envanteri

| Veri | Nerede | Dışarı gider mi? |
|---|---|---|
| Parça adı, sanatçı, albüm, süre | SQLite | Evet, yalnız LRCLIB/iTunes sorgusunda |
| Söz metni | SQLite | Hayır |
| Ses | Bellek (gerçek zamanlı) | Hayır. Klipte isteğe bağlı, yerel dosyaya |
| Kullanım analitiği | — | Toplanmaz |
| Teşhis paketi | Yalnız kullanıcı kopyalarsa | Kullanıcı kendisi paylaşır; parça adları maskeli |
