# Lirevo

**[Türkçe](#türkçe) · [English](#english)**

<!-- Demo GIF/video buraya gelecek / Demo GIF/video goes here:
     docs/media/demo.gif (dikey değil, 16:9; ~10 sn) -->

> ⚠️ Lirevo erken geliştirme aşamasındadır; henüz indirilebilir bir sürüm yoktur.
> Lirevo is in early development; there is no downloadable release yet.

---

## Türkçe

Lirevo, Mac'inde çalan müziği bir sahneye dönüştüren bir menü çubuğu uygulamasıdır. Spotify veya Apple Music'te çalan şarkının sözlerini kelime kelime yakar, ekranın kenarlarını müziğe tepki veren bir ışıkla çevreler ve cam görünümlü bir oynatıcı kartı gösterir. Üçü de aynı zaman çizgisini, albüm kapağından çıkarılan aynı renk paletini ve aynı ses analizini paylaşır.

### Özellikler

- **Kelime kelime şarkı sözleri**: dört stil (Ship, Fisheye, Fisheye Visual, Visual).
- **Ekran kenarı ışığı**: müzik senkronu, söze duyarlı, sabit ve nefes modları; notch uyumu; çoklu ekran.
- **Cam oynatıcı kartı**: kapak, başlık, ilerleme ve oynatma kontrolleri.
- **Albüm kapağından otomatik renkler**, istenirse elle renk seçimi.
- **Sahne presetleri**: Sinema, Kulüp, Sessiz, Odak; kendi sahnelerini içe/dışa aktarma.
- **Sahne Modu**: tam ekran ortam görünümü, yalnızca public API ile.
- **Parça bazlı senkron düzeltme** (±2 sn, kısayol ile ±100 ms).
- **Pil dostu**: pilde ve Düşük Güç Modu'nda kare hızı ve efektler kısılır.
- **Toplantıda otomatik gizleme** ve tek kısayolla "panik gizle".
- **Yerel söz dosyaları**: `.lrc`, Enhanced LRC, `.ttml`.
- **Hesap yok, analitik yok.**

### Gereksinimler

- Apple Silicon Mac (M1 veya sonrası). Intel desteklenmez.
- macOS 14.2 veya sonrası. Liquid Glass görünümü macOS 26 ve sonrasında.
- Spotify veya Müzik uygulaması.

### Kurulum

**İndirme**: İlk sürüm yayınlandığında [Releases](https://github.com/egebayramakgun/lirevo/releases) sayfasından imzalı ve notarize edilmiş `.dmg` olarak indirilebilecek. Güncellemeler uygulama içinden (Sparkle) gelir.

**Kaynaktan derleme**:

1. Xcode 27 veya sonrasını kur.
2. Depoyu klonla:
   ```bash
   git clone https://github.com/egebayramakgun/lirevo.git
   cd lirevo
   ```
3. Yerel ayar dosyasını oluştur ve istersen Apple geliştirici takım kimliğini yaz:
   ```bash
   cp Config/Local.xcconfig.example Config/Local.xcconfig
   ```
   Takım kimliği olmadan da derlenir; ancak bu durumda macOS, Otomasyon iznini her derlemeden sonra yeniden sorabilir.
4. `Lirevo.xcodeproj` dosyasını aç ve **Lirevo** şemasını çalıştır. Komut satırından:
   ```bash
   xcodebuild -project Lirevo.xcodeproj -scheme Lirevo -configuration Debug -destination 'platform=macOS,arch=arm64' build
   ```

Kendi derlediğin bir sürümü dağıtacaksan farklı bir ad kullanmalısın; bkz. [TRADEMARKS.md](TRADEMARKS.md).

### İzinler ve neden gerektikleri

| İzin | Neden | İzin vermezsen |
|---|---|---|
| **Otomasyon** (Spotify, Müzik) | Çalan şarkıyı, konumu ve kapağı okumak; oynat/duraklat/atla komutları. | Şarkı bilgisi okunamaz; ışık sabit modda çalışabilir. |
| **Sistem sesi yakalama** | Mac'inden çıkan sesin ritmini analiz edip ışığı müziğe uydurmak. **Mikrofon kullanılmaz, ses kaydedilmez.** | Işık, sözlerin zamanlamasından türetilen yumuşak bir nabızla çalışır. |

Lirevo **ekran kaydı izni istemez**. Her izin onboarding sırasında atlanabilir ve daha sonra Sistem Durumu panelinden açılabilir.

### Gizlilik

- Analitik veya kullanım verisi toplanmaz.
- Mikrofon kullanılmaz. Ses yalnızca bellekte, gerçek zamanlı olarak analiz edilir ve diske yazılmaz.
- Şarkı sözlerini bulmak için yalnızca **şarkı adı, sanatçı, albüm ve süre** [LRCLIB](https://lrclib.net)'e gönderilir. Müzik uygulamasından kapak alınamazsa aynı bilgiler kapak için Apple'ın iTunes Search API'sine gider.
- Güncelleme kontrolü (Sparkle) ve uzaktan özellik kapatma dosyası (`capabilities.json`) [lirevo.app](https://lirevo.app) üzerinden alınır; bu isteklerde kişisel veri yoktur.
- Teşhis paketi yalnızca sen kopyalarsan oluşur ve şarkı adları maskelenir.

**Deneysel kilit ekranı katmanı**: Gerçek macOS kilit ekranının üzerinde gösterim, Apple'ın belgelemediği (private) API'ler gerektirir. Bu özellik varsayılan olarak kapalıdır, ayrı bir modülde yalıtılmıştır ve yalnızca test edilmiş macOS sürümlerinde açılır. Asıl deneyim (masaüstü katmanı ve Sahne Modu) yalnızca public API kullanır.

### Katkı

Katkılara açığız. Başlamadan önce [CONTRIBUTING.md](CONTRIBUTING.md) ve [Davranış Kuralları](CODE_OF_CONDUCT.md)'nı oku. Güvenlik açıklarını herkese açık issue yerine [SECURITY.md](SECURITY.md)'de anlatıldığı gibi bildir.

### Lisans

Lirevo'nun kaynak kodu [GNU General Public License v3.0 or later](LICENSE) ile lisanslanmıştır. "Lirevo" adı ve logosu bu lisansın kapsamında değildir; bkz. [TRADEMARKS.md](TRADEMARKS.md).

Şarkı sözleri Lirevo tarafından barındırılmaz veya dağıtılmaz; LRCLIB'den veya senin yerel dosyalarından alınır. Sözlerin hakları sahiplerine aittir.

---

## English

Lirevo is a menu bar app that turns the music playing on your Mac into a scene. It lights up the lyrics of the song playing in Spotify or Apple Music word by word, surrounds the edges of your screen with light that reacts to the music, and shows a glass-style player card. All three share the same timeline, the same color palette taken from the album artwork, and the same audio analysis.

### Features

- **Word-by-word lyrics** in four styles (Ship, Fisheye, Fisheye Visual, Visual).
- **Screen edge light**: music sync, lyric-reactive, static and breathing modes; notch-aware; multiple displays.
- **Glass player card** with artwork, title, progress and playback controls.
- **Automatic colors from album artwork**, or pick your own.
- **Scene presets**: Cinema, Club, Quiet, Focus; import and export your own scenes.
- **Stage Mode**: a full-screen ambient view, built only on public APIs.
- **Per-track sync adjustment** (±2 s, ±100 ms via shortcut).
- **Battery-friendly**: frame rate and effects are reduced on battery and in Low Power Mode.
- **Auto-hide during meetings** and a one-shortcut "panic hide".
- **Local lyrics files**: `.lrc`, Enhanced LRC, `.ttml`.
- **No account, no analytics.**

### Requirements

- Apple Silicon Mac (M1 or later). Intel is not supported.
- macOS 14.2 or later. The Liquid Glass look requires macOS 26 or later.
- Spotify or the Music app.

### Installation

**Download**: Once the first version is released, a signed and notarized `.dmg` will be available on the [Releases](https://github.com/egebayramakgun/lirevo/releases) page. Updates are delivered in-app (Sparkle).

**Build from source**:

1. Install Xcode 27 or later.
2. Clone the repository:
   ```bash
   git clone https://github.com/egebayramakgun/lirevo.git
   cd lirevo
   ```
3. Create your local settings file and, optionally, add your Apple developer team ID:
   ```bash
   cp Config/Local.xcconfig.example Config/Local.xcconfig
   ```
   The app builds without a team ID, but macOS may then ask for Automation permission again after every build.
4. Open `Lirevo.xcodeproj` and run the **Lirevo** scheme. From the command line:
   ```bash
   xcodebuild -project Lirevo.xcodeproj -scheme Lirevo -configuration Debug -destination 'platform=macOS,arch=arm64' build
   ```

If you distribute your own build, you must use a different name; see [TRADEMARKS.md](TRADEMARKS.md).

### Permissions and why they are needed

| Permission | Why | If you decline |
|---|---|---|
| **Automation** (Spotify, Music) | Read the current track, position and artwork; play/pause/skip commands. | Track info can't be read; the light can still run in static mode. |
| **System audio capture** | Analyze the rhythm of the sound coming out of your Mac so the light follows the music. **The microphone is not used and audio is not recorded.** | The light uses a gentle pulse derived from the lyric timing. |

Lirevo **does not ask for screen recording permission**. Every permission can be skipped during onboarding and enabled later from the System Status panel.

### Privacy

- No analytics or usage data is collected.
- The microphone is not used. Audio is analyzed in memory, in real time, and never written to disk.
- To find lyrics, only the **track title, artist, album and duration** are sent to [LRCLIB](https://lrclib.net). If artwork can't be read from the Music app, the same details are sent to Apple's iTunes Search API to find it.
- Update checks (Sparkle) and the remote feature kill switch (`capabilities.json`) are fetched from [lirevo.app](https://lirevo.app); these requests contain no personal data.
- A diagnostics bundle is created only when you copy it, and track names are masked.

**Experimental lock screen layer**: Drawing over the real macOS lock screen requires undocumented (private) Apple APIs. This feature is off by default, isolated in a separate module and only enabled on tested macOS versions. The core experience (desktop layer and Stage Mode) uses public APIs only.

### Contributing

Contributions are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) and the [Code of Conduct](CODE_OF_CONDUCT.md) first. Report security issues as described in [SECURITY.md](SECURITY.md), not in public issues.

### License

Lirevo's source code is licensed under the [GNU General Public License v3.0 or later](LICENSE). The "Lirevo" name and logo are not covered by this license; see [TRADEMARKS.md](TRADEMARKS.md).

Lyrics are not hosted or distributed by Lirevo; they come from LRCLIB or your own local files. Lyrics belong to their respective rights holders.
