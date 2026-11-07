# App Flow — Lirevo

> Kullanıcı akışları, sistem akışları ve durum makineleri. Diyagramlar Mermaid formatındadır.

---

## 1. Genel bakış

```mermaid
flowchart TD
    A[Uygulama açılır] --> B{İlk açılış mı?}
    B -- Evet --> C[Onboarding]
    B -- Hayır --> D[Servisleri başlat]
    C --> D
    D --> E[Çalma izleyici]
    E -->|Parça değişti| F[Söz zinciri]
    E -->|Parça değişti| G[Kapak + palet]
    E -->|Çalıyor| H[Ses analizi]
    F --> I[Sahne motoru]
    G --> I
    H --> I
    I --> J[Çerçeve ışığı]
    I --> K[Söz katmanı]
    I --> L[Cam kart]
    J & K & L --> M{Görünürlük politikası}
    M --> N[Masaüstü hedefi]
    M --> O[Sahne Modu]
    M --> P[Kilit ekranı - deneysel]
```

## 2. İlk açılış (Onboarding)

Tek pencere, 4 adım. Her izin adımı atlanabilir; atlanan izin uygulamayı bozmaz, yalnız ilgili özellik düşük modda çalışır.

```mermaid
flowchart TD
    S1[1. Hoş geldin<br/>canlı önizleme] --> S2[2. Müzik uygulamaları<br/>Otomasyon izni]
    S2 -->|İzin verildi| S3
    S2 -->|Reddedildi/atlandı| S2b[Uyarı: Parça okunamaz<br/>Sonra Sistem Durumu'ndan açılabilir]
    S2b --> S3[3. Sistem sesi izni]
    S3 -->|İzin verildi| S4
    S3 -->|Reddedildi/atlandı| S3b[Bilgi: Işık sözlerden türetilen<br/>yumuşak nabızla çalışacak]
    S3b --> S4[4. Sahne seç<br/>Sinema / Kulüp / Sessiz / Odak<br/>+ Görünürlük: Her zaman / Sadece Sahne Modu'nda]
    S4 --> END[Menü çubuğuna küçül<br/>+ ipucu balonu: 'Bir şarkı aç']
```

**Otomasyon izni ayrıntısı**
- macOS bu izni ilk Apple Event gönderiminde sorar. Onboarding'de "İzin ver" düğmesi, çalışan oynatıcıya zararsız bir sorgu (`player state`) gönderir. Oynatıcı kapalıysa: "Spotify veya Müzik'i aç, sonra tekrar dene" mesajı; uygulamayı biz açmayız.
- Her oynatıcı için ayrı izin istenir (Spotify, Müzik).

**Sahne ve görünürlük adımı**
- Varsayılan seçim "Her zaman" (`visibility.mode = always`). "Sadece Sahne Modu'nda" seçilirse masaüstü katmanı gizli kalır, sahne yalnızca Sahne Modu'nda görünür (`stageOnly`).
- "Sadece kilitliyken" (`lockedOnly`) onboarding'de sunulmaz; yalnız Ayarlar > Gelişmiş'te, deneysel kilit ekranı katmanı açıkken seçilebilir.

**Sistem sesi izni ayrıntısı**
- Açıklama metni: "Lirevo yalnızca Mac'inden çıkan sesin ritmini analiz eder. Mikrofon kullanılmaz, ses kaydedilmez."

## 3. Parça değişimi hattı

```mermaid
sequenceDiagram
    participant NP as NowPlaying
    participant LY as LyricsService
    participant PA as PaletteService
    participant SE as SceneEngine
    participant UI as Renderer

    NP->>SE: trackChanged(track)
    SE->>UI: geçiş başlat (eski sözleri sönümle 300 ms)
    par
        NP->>LY: fetch(query)
        LY->>LY: Önbellek → Yerel → LRCLIB get → LRCLIB search
        LY-->>SE: lyricsReady(doc, quality)
    and
        NP->>PA: artwork(track)
        PA-->>SE: paletteReady(palette)
    end
    SE->>UI: yeni palet (800 ms geçiş) + yeni sözler
    Note over LY,SE: Söz 2 sn içinde gelmezse ışık + kart çalışır,<br/>söz geldiğinde bulunduğu satırdan başlar
```

Kurallar:
- Hızlı atlamalarda (parçalar arası < 1.5 sn) önceki istek iptal edilir (`Task.cancel`).
- Söz `none` dönerse söz katmanı gizlenir; menüde "Bu şarkı için söz bulunamadı → Dosya ekle" seçeneği.
- `plainLyrics` var ama senkron yoksa: söz katmanı gösterilmez (yanlış senkron göstermektense hiç göstermemek), cam kartta "senkronsuz söz var" küçük ikonu → kullanıcı isterse yavaş kayan mod.

## 4. Çalma saati ve senkron düzeltme

```mermaid
flowchart LR
    A[Olay veya 1 sn tick] --> B[AppleScript: position]
    B --> C{Sapma > 300 ms?}
    C -- Evet --> D[Sert atla - seek]
    C -- Hayır --> E[250 ms yumuşak düzeltme]
    D & E --> F[+ Parça offset'i]
    F --> G[PlaybackClock.now]
```

**Kullanıcı senkron düzeltme**
1. Menü > "Senkron" kaydırıcısı (±2 sn) veya kısayol `⌃⌥⌘←/→` (±100 ms).
2. Değişiklik anında uygulanır, parça ID'sine kaydedilir.
3. "Sıfırla" düğmesi.

## 5. Söz sağlayıcı zinciri ve kelime zamanlaması

```mermaid
flowchart TD
    Q[TrackQuery] --> C1{Önbellekte?}
    C1 -- Pozitif --> R[LyricsDocument]
    C1 -- Negatif, TTL geçerli --> NONE[none]
    C1 -- Yok --> C2{Yerel dosya?}
    C2 -- Var --> R
    C2 -- Yok --> C3{LRCLIB get}
    C3 -- Bulundu --> R
    C3 -- Yok --> C4{LRCLIB search<br/>puan ≥ 0.75}
    C4 -- Bulundu --> R
    C4 -- Yok --> NONE
    R --> T{Kelime zamanı var mı?}
    T -- Evet --> EX[quality = exact]
    T -- Hayır --> ES[WordTimingEstimator<br/>quality = estimated]
    ES --> AL{Ses analizi var ve<br/>eşleşme ≥ %40?}
    AL -- Evet --> AG[OnsetAligner<br/>quality = aligned<br/>satır satır önbelleğe yaz]
    AL -- Hayır --> ES2[estimated kalır]
```

Ağ hatası: zincir bir sonraki sağlayıcıya geçer; ağ yoksa negatif önbelleğe **yazılmaz** (bağlantı gelince tekrar denenir).

## 6. Görünürlük durum makinesi

```mermaid
stateDiagram-v2
    [*] --> Idle
    Idle --> Playing: çalma başladı
    Playing --> Idle: duraklatıldı + 30 sn

    state Playing {
        [*] --> Evaluate
        Evaluate --> DesktopVisible: kilitli değil ∧ mod=Her zaman ∧ gizleme kuralı yok
        Evaluate --> DesktopHidden: kilitli değil ∧ (mod≠Her zaman ∨ gizleme kuralı)
        Evaluate --> Stage: Stage aktif
        Evaluate --> LockVisible: kilitli ∧ LockScreenHost destekli ∧ açık
        Evaluate --> LockFallback: kilitli ∧ LockScreenHost yok/kapalı
        DesktopVisible --> Evaluate: olay
        DesktopHidden --> Evaluate: olay
        Stage --> Evaluate: kullanıcı girdisi
        LockVisible --> Evaluate: kilit açıldı
        LockFallback --> Evaluate: kilit açıldı
    }

    Playing --> Sleeping: ekran uyudu
    Sleeping --> Playing: ekran uyandı
```

| Durum | Işık | Sözler | Kart | Ekran uyanık tut | Ses tap |
|---|---|---|---|---|---|
| Idle | Kapalı (veya "Sabit idle" ayarı açıksa sabit) | Kapalı | Kapalı | Hayır | Kapalı |
| DesktopVisible | Açık | Açık | Ayara göre | Evet | Açık |
| DesktopHidden | Ayara göre ("sadece ışık" mümkün) | Kapalı | Kapalı | Yalnız ışık görünürse evet | Işık açıksa açık |
| Stage | Açık | Açık (büyük) | Açık | Evet | Açık |
| LockVisible | Açık | Açık | Açık | Evet | Açık |
| LockFallback | Kapalı | Kapalı | Kapalı | Hayır | Kapalı |
| Sleeping | Render durur | Render durur | — | Hayır | Kapalı |

**Görünürlük modları** (`visibility.mode`): `always` (varsayılan; masaüstü katmanı açık), `stageOnly` (masaüstü gizli, yalnız Sahne Modu), `lockedOnly` (masaüstü gizli; kilit ekranında gösterim; yalnız deneysel kilit ekranı katmanı açıkken seçilebilir, katman kapatılırsa `always`'e döner).

**Ekranı uyanık tutma kuralı**: `display.keepAwake` açıksa, assertion yalnızca *müzik çalıyor* ∧ *en az bir sunum hedefi (ışık, sözler veya kart) görünür* olduğunda tutulur; duraklatmadan 30 sn sonra veya hiçbir hedef görünmez olunca bırakılır. Tablodaki "Ekran uyanık tut" sütunu bu kuralın sonucudur.

**Olaylar**: kilit/kilit açma, ekran uyku/uyanma, çalma/duraklatma, ön plan uygulama değişimi, ekran yapılandırma değişimi, panik gizle kısayolu, Stage aç/kapa, ayar değişimi, güç durumu değişimi.

**Panik gizle** (`⌃⌥⌘H`): Tüm hedefleri 0 ms'de gizler, tekrar basılana kadar `Evaluate` atlanır.

## 7. Kilit ekranı (deneysel) etkinleştirme akışı

```mermaid
flowchart TD
    U[Ayarlar > Gelişmiş > Kilit ekranında göster - Deneysel] --> W[Uyarı kartı:<br/>macOS güncellemelerinde çalışmayabilir]
    W --> K1{OS build allowlist'te mi?}
    K1 -- Hayır --> X[Desteklenmiyor mesajı<br/>Sahne Modu öner]
    K1 -- Evet --> K2{capabilities.json kapatmış mı?}
    K2 -- Evet --> X
    K2 -- Hayır --> K3{Semboller çözüldü mü?}
    K3 -- Hayır --> X
    K3 -- Evet --> K4[Öz-test penceresi]
    K4 -- Başarısız --> X2[Bu OS build için kalıcı devre dışı<br/>+ teşhis kaydı] --> X
    K4 -- Başarılı --> OK[Etkin.<br/>'Şimdi dene: ⌃⌘Q ile kilitle']
```

Çalışma zamanı: Her kilitlenmede host etkinleştirilir; hata fırlatırsa o oturum için `LockFallback` durumuna geçilir, bir sonraki kilit açılışta kullanıcıya tek seferlik bildirim gösterilir.

## 8. Sahne Modu akışı

1. Tetikleyiciler: menü "Sahne Modu", kısayol `⌃⌥⌘S`, veya "X dk boşta kalınca Sahne Modu" (varsayılan kapalı; 1–30 dk).
2. Açılış: 400 ms karartma → tam ekran sahne (ışık + büyük sözler + kart).
3. Kapanış: herhangi bir tuş, tıklama veya 8 pt üzeri fare hareketi → 250 ms açılma.
4. Çoklu ekran: ana ekranda sözler, diğer ekranlarda yalnız ışık + bulanık kapak (ayar).
5. İlk kullanımda tek seferlik bilgi: "Sahne Modu kilit değildir; uzaklaşacaksan ⌃⌘Q."

## 9. Menü çubuğu etkileşimi

```mermaid
flowchart TD
    M[Menü ikonu tıklandı] --> P[Panel]
    P --> P1[Şimdi çalıyor özeti + mini oynatıcı]
    P --> P2[Sahne seçici - yatay kartlar]
    P --> P3[Hızlı geçişler:<br/>Işık / Sözler / Kart / Sahne Modu]
    P --> P4[Söz stili seçici]
    P --> P5[Senkron kaydırıcı]
    P --> P6[Ayarlar… / Sistem Durumu / Çıkış]
    P2 -->|Sahne seç| A1[Anında uygula, şarkı devam eder]
    P2 -->|Uzun bas/sağ tık| A2[Düzenle / Çoğalt / Dışa aktar]
```

Menü ikonu durumları: normal, çalıyor (hafif nabız; Hareketi Azalt'ta sabit), uyarı (sarı nokta: bir alt sistem `unavailable`).

## 10. Ayarlar akışı

Ayar penceresi sekmeleri (7): **Sahneler · Sözler · Işık · Kart · Ekranlar · Kısayollar · Gelişmiş**. Ayrıntılar `ui_ux_brief.md` §6.

Sahne düzenleme kuralı: Bir sahne seçiliyken Işık/Sözler sekmesindeki değişiklik o sahneyi "değiştirilmiş" olarak işaretler; "Sahneyi güncelle" veya "Yeni sahne olarak kaydet".

## 11. Sistem Durumu (teşhis) akışı

| Alt sistem | Durum örnekleri | Kullanıcı aksiyonu |
|---|---|---|
| Spotify bağlantısı | Bağlı / İzin yok / Uygulama kapalı | İzni aç (Sistem Ayarları derin bağlantısı) |
| Müzik bağlantısı | Aynı | Aynı |
| Sistem sesi | Analiz ediliyor / İzin yok (yumuşak nabız) | İzni aç |
| Söz kaynağı | Bu şarkı: LRCLIB, aligned / Bulunamadı | Dosya ekle |
| Kilit ekranı katmanı | Kapalı / Etkin / Bu macOS'ta desteklenmiyor | Sahne Modu'nu dene |
| Güç | AC 60 fps / Pil 30 fps / Termal kısıtlama | — |
| Güncelleme | Güncel / Yeni sürüm var | Güncelle |

"Teşhis paketini kopyala" düğmesi.

## 12. Klip dışa aktarma akışı (v1.5)

```mermaid
flowchart TD
    A[Menü > Klip oluştur] --> B[Süre: 15 / 30 sn - son kısım]
    B --> C[Şablon: Dikey 9:16 / Kare 1:1]
    C --> D{Şarkı sesi dahil edilsin mi?<br/>varsayılan Hayır + telif notu}
    D --> E[Offscreen render ilerleme çubuğu]
    E --> F[Kaydet: ~/Movies/Lirevo/…mp4<br/>Finder'da göster / Paylaş menüsü]
```

## 13. Hata ve düşük mod matrisi

| Hata | Etki | Davranış |
|---|---|---|
| Otomasyon izni yok | Parça bilgisi yok | Sahne motoru boşta; ışık "Sabit idle" modda ses tap'e göre çalışabilir; menüde uyarı |
| Sistem sesi izni yok | Ritim yok | SyntheticPulse |
| Söz bulunamadı | Söz katmanı yok | Işık + kart devam |
| Kapak yok | Palet yok | Son palet veya sahnenin varsayılan renkleri |
| Ağ yok | Yeni söz/kapak yok | Önbellek; negatif önbelleğe yazma |
| Metal cihaz hatası | Işık render edilemez | Işık `unavailable`, sözler SwiftUI yedek (shader'sız) |
| Kilit host hatası | Kilit ekranında görüntü yok | LockFallback + tek seferlik bildirim |
| Ekran tak/çıkar | Pencereler geçersiz | Yeniden kurulum, sahne kesintisiz |
| AppleScript zaman aşımı | Pozisyon güncel değil | Tahmin devam eder, geri çekilme |

## 14. Güncelleme akışı

- Sparkle günlük kontrol → bildirim → "Yükle ve yeniden başlat". Kilitliyken veya Stage'de güncelleme penceresi gösterilmez, sonraya ertelenir.
- Lisans akışı yoktur (açık kaynak, GPL-3.0-or-later).
