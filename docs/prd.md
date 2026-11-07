# PRD — Lirevo

> Müziği Mac ekranında görsel bir sahneye dönüştüren menü çubuğu uygulaması: kelime kelime yanan şarkı sözleri + müziğe tepki veren ekran çerçevesi ışığı + cam oynatıcı kartı.
> Yalnızca Apple Silicon, macOS 14.2+.

| Alan | Değer |
|---|---|
| Doküman sürümü | 1.0 |
| Durum | Taslak, geliştirmeye hazır |
| Lisans | Açık kaynak, GPL-3.0-or-later |
| İlgili dokümanlar | `trd.md`, `app_flow.md`, `ui_ux_brief.md`, `backend_schema.md`, `implementation_plan.md` |

---

## 1. Özet

Lirevo, iki ayrı fikri (kilit ekranında kelime kelime şarkı sözü ve müziğe tepki veren ortam ışığı) tek bir uygulamada birleştirir ve ikisini ortak bir **Sahne Motoru** altında senkronize eder. Spotify ve Apple Music ile çalışır, hesap gerektirmez, menü çubuğunda yaşar. Açık kaynaklıdır (GPL-3.0-or-later); lisans anahtarı veya ücretli sürüm yoktur.

Temel fark: Işık ve sözler aynı zaman çizgisini, aynı renk paletini ve aynı ses analizini paylaşır. Işık yalnızca ritme değil, söylenen kelimeye ve nakaratın enerjisine de tepki verir.

## 2. Problem ve fırsat

- Mac'te müzik dinlerken ekran ya boştur ya da kilitlidir; müzikle görsel bağ kurulmaz.
- Mevcut çözümler iki ayrı uygulama olarak satılıyor (ikisi ayrı izin, ayrı ayar, ayrı palet çıkarımı, ayrı CPU maliyeti).
- Kısa video platformlarında bu tür "masa üstü estetiği" içerikleri çok paylaşılıyor, ancak paylaşım için ekran kaydı almak zahmetli.

## 3. Hedefler

1. Tek uygulamada sözler + ışık + cam kart, tek palet, tek zaman çizgisi.
2. Hiçbir alt sistemin hatası uygulamanın geri kalanını bozmamalı (graceful degradation).
3. Özel (private) API'ler çekirdek akışta yer almamalı; yalnızca yalıtılmış, isteğe bağlı, uzaktan kapatılabilir modüllerde kullanılabilir.
4. Pil ve performans dostu: müzik çalarken toplam CPU ortalaması M1'de ≤ %5.
5. 1 dakikada kurulum, hesap yok.

## 4. Hedef dışı (Non-goals)

- Intel Mac desteği.
- iOS/iPadOS sürümü.
- Kendi müzik çaları olmak (oynatma Spotify/Music'te kalır; biz sadece okur ve kumanda ederiz).
- Kendi söz veritabanını barındırmak.
- Mac App Store dağıtımı (v1'de; bkz. Risk R1).
- Lisans anahtarı, deneme süresi veya ücretli sürüm.
- Ticari söz sağlayıcı entegrasyonu (yalnızca `LyricsProvider` protokolü genişletmeye açık kalır).

## 5. Kullanıcılar

| Persona | Tanım | Ne ister |
|---|---|---|
| Estetik dinleyici | Mac'i masada açık bırakıp müzik dinleyen, kurulumuna önem veren kullanıcı | Güzel görünen, kendiliğinden çalışan bir sahne |
| Şarkı söyleyen / öğrenen | Yabancı dilde şarkı dinleyip sözleri takip eden | Doğru zamanlı söz, çeviri, romanizasyon |
| İçerik üreticisi | Instagram/TikTok'ta paylaşım yapan | Tek tıkla 9:16 klip |
| Çalışan | Gün içinde müzik dinleyip toplantıya giren | Toplantıda/ekran paylaşımında otomatik gizlenme, düşük pil tüketimi |

## 6. Kapsam ve öncelikler

P0 = v1 için zorunlu · P1 = v1'de olması beklenen · P2 = v1.5 · P3 = v2

### 6.1 Çekirdek (iki uygulamadan birleştirilen)

| ID | Özellik | Öncelik | Kaynak |
|---|---|---|---|
| F-01 | Menü çubuğu uygulaması, Dock ikonu yok | P0 | İkisi |
| F-02 | Spotify ve Apple Music'te çalan parçayı, pozisyonu ve durumu okuma | P0 | İkisi |
| F-03 | Kelime kelime yanan şarkı sözü katmanı | P0 | Verci |
| F-04 | 4 söz stili: Ship, Fisheye, Fisheye Visual, Visual | P0 (Visual P1) | Verci |
| F-05 | Kelime → SF Symbol/emoji eşlemesi (kendi tablomuz) | P1 | Verci |
| F-06 | Albüm kapağından otomatik palet (3 renk) + elle renk | P0 | İkisi |
| F-07 | Ekran kenarı ışık çerçevesi (rim light) | P0 | Lumn |
| F-08 | Işık modu: müzik senkronu / söze duyarlı / sabit idle / nefes (söze duyarlı mod N-02'ye bağlıdır) | P0 | Lumn |
| F-09 | Gradient (2 renk, oran ayarı), kalınlık, glow | P0 | Lumn |
| F-10 | Notch uyumu | P0 | Lumn |
| F-11 | Ekran seçimi, çoklu ekran | P1 | Lumn |
| F-12 | Cam (liquid glass) oynatıcı kartı + kontroller | P1 | Lumn |
| F-13 | Müzik çalarken ve herhangi bir sunum hedefi görünürken ekranı uyanık tutma | P0 | Verci |
| F-14 | Görünürlük modu: her zaman (varsayılan) / sadece Sahne Modu'nda / sadece kilitliyken (yalnız deneysel kilit ekranı katmanı açıkken) | P0 | Verci |
| F-15 | Sistem sesi analizi (mikrofon değil) | P0 | Lumn |
| F-16 | Otomatik güncelleme (Sparkle) | P0 | Lumn |

### 6.2 Yeni özellikler

| ID | Özellik | Öncelik | Açıklama |
|---|---|---|---|
| N-01 | Sahne presetleri | P0 | Söz stili + ışık + renk + hareket tek pakette ("Sinema", "Kulüp", "Sessiz", "Odak"). İçe/dışa aktarılabilir JSON. |
| N-02 | Söze duyarlı ışık | P1 | Kelime başlangıçlarında hafif nabız, nakarat/enerji yükselişinde yoğunluk artışı. |
| N-03 | Parça bazlı senkron düzeltme | P0 | ±2 sn offset, parça başına hatırlanır. Kısayol ile ±100 ms. |
| N-04 | Güç yöneticisi | P0 | Pilde düşük fps, Düşük Güç Modu, termal durumda kısma. |
| N-05 | Otomatik gizleme | P1 | Tam ekran uygulama, sunum, video konferans uygulamaları ön plandayken gizle. |
| N-06 | Global kısayollar + Shortcuts (App Intents) | P1 | Stil değiştir, ışığı aç/kapat, Sahne Modu, offset. |
| N-07 | Sahne Modu (ortam modu) | P0 | Kilit ekranı katmanına bağımlı olmayan, tamamen public API ile çalışan tam ekran sahne. Kısayol, menü veya boşta kalma süresiyle açılır. |
| N-08 | Çeviri satırı | P2 | Cihaz üstü Apple Translation (macOS 15+), söz altına ikinci satır. |
| N-09 | Romanizasyon | P2 | Japonca, Korece, Kiril, Yunanca vb. için Latin harfli okunuş. |
| N-10 | 9:16 klip dışa aktarma | P2 | Son 15/30 sn'yi ekran kaydı izni istemeden, kendi render motorumuzla yeniden üretip MP4'e yazma. |
| N-11 | Yerel söz dosyası desteği | P1 | Kullanıcının `.lrc` / Enhanced LRC / `.ttml` dosyaları. |
| N-12 | Sistem durumu paneli | P0 | Her alt sistemin durumunu (izin, söz kaynağı, ses, kilit ekranı katmanı) gösteren teşhis ekranı. |
| N-13 | Fiziksel ışık senkronu (Hue/Govee LAN) | P3 | Araştırma gerektirir. |
| N-14 | Ek kaynaklar (Tidal, YouTube Music vb.) | P3 | Sistem sesi + genel "Now Playing" yedeği. |

## 7. Fonksiyonel gereksinimler

### F-02 Çalan parça okuma
- Parça değişimi ≤ 300 ms içinde algılanmalı.
- Pozisyon hatası (gerçek pozisyon ile tahmin arasındaki fark) kararlı durumda ≤ 50 ms olmalı.
- Seek algılanmalı (sapma > 300 ms → anında atlama, aksi halde yumuşak düzeltme).
- İki oynatıcı aynı anda çalıyorsa: en son durum değiştiren "aktif" sayılır; kullanıcı menüden sabitleyebilir.
- Automation izni reddedilirse: uygulama çökmez, Sistem Durumu panelinde uyarı + "İzni aç" butonu.

### F-03 Söz katmanı
- Kelime zamanı kaynağı üç kalitede olabilir: `exact` (kaynak kelime zamanı verdi), `aligned` (satır zamanı + ses başlangıçlarına hizalanmış tahmin), `estimated` (sadece satır zamanından tahmin).
- Kullanıcıya kalite gösterilmez; ancak `estimated` durumunda animasyon daha yumuşak (keskin "yanma" yerine dolma) olur ki hatalar göze batmasın.
- Sözü olmayan parça: söz katmanı gizlenir, ışık ve cam kart çalışmaya devam eder.
- Enstrümantal bölüm (> 5 sn boşluk): üç nokta "nefes" animasyonu.

### F-07 Işık çerçevesi
- Kalınlık 1–120 pt, glow 0–100, gradient oranı %0–100, renk albümden ya da elle.
- Notch'lu ekranlarda ışık notch kenarını takip eder (seçenek: notch etrafını sar / notch'u atla).
- Yanıp sönme güvenliği: parlaklık değişimi saniyede 3 flaştan fazla olamaz (WCAG 2.3.1). "Yumuşak" varsayılan.

### F-14 / N-07 Görünürlük ve sunum hedefleri
Uygulama üç sunum hedefi tanımlar:

1. **Masaüstü katmanı** (public API): Mac açıkken sözler ve ışık tıklanamaz şeffaf pencerelerde.
2. **Sahne Modu** (public API): Tam ekran, kullanıcı girdisiyle kapanan ortam ekranı. Kilit değildir; ayarlarda "Sahne Modu kapanınca Mac'i kilitle" seçeneği ile güvenlik sağlanır.
3. **Kilit ekranı katmanı** (deneysel, private API, isteğe bağlı): Gerçek macOS kilit ekranının üstünde görüntü. Yalnızca test edilmiş macOS sürümlerinde ve uzaktan kapatma anahtarı açıkken etkin olur. Başarısız olursa uygulama sessizce Sahne Modu önerisine düşer.

## 8. Fonksiyonel olmayan gereksinimler

| Konu | Hedef |
|---|---|
| Platform | Apple Silicon (arm64) only, macOS 14.2+ (Liquid Glass görünümü macOS 26+, altında material yedeği) |
| CPU | Müzik + ışık + söz aktifken M1'de ortalama ≤ %5, boşta ≤ %0.3 |
| Bellek | ≤ 150 MB |
| Enerji | Pilde 30 fps üst sınır, ekran kapalıyken render tamamen durur |
| Başlangıç | Soğuk açılış ≤ 1 sn, menü ilk açılış ≤ 100 ms |
| Gizlilik | Mikrofon yok, ekran kaydı izni yok, analytics varsayılan kapalı, ses diske yazılmaz (klip özelliği hariç, açıkça kullanıcı isteğiyle) |
| Dayanıklılık | Herhangi bir alt sistem hatası diğerlerini durdurmaz; çökme yerine düşük mod |
| Erişilebilirlik | Hareketi Azalt, Kontrastı Artır, VoiceOver ile menü ve ayarlar |
| Yerelleştirme | TR + EN (v1) |

## 9. Riskler ve çözüm kararları

| ID | Risk | Karar |
|---|---|---|
| R1 | Kilit ekranına çizim public API ile mümkün değil; private API macOS güncellemelerinde bozulabilir | Çekirdek deneyim **Masaüstü katmanı + Sahne Modu** üzerine kurulur (public API). Kilit ekranı katmanı ayrı modülde, opt-in, sürüm allowlist'i + uzaktan kapatma anahtarı (`capabilities.json`) + çalışma zamanı öz-testi ile korunur. App Store hedeflenmez. |
| R2 | Kelime zamanlı söz verisinin kaynağı ve lisansı | Sağlayıcı zinciri (protokol): Önbellek → Yerel dosya → LRCLIB (satır zamanlı, ücretsiz). Ticari sağlayıcı uygulanmaz; `LyricsProvider` protokolü genişletmeye açıktır. Satır zamanlı veri, ses başlangıçlarına hizalanarak kelime zamanına dönüştürülür. Gayriresmi/ToS ihlali içeren uç noktalar kullanılmaz. Uygulama söz barındırmaz ve dağıtmaz; yalnızca kullanıcının cihazında LRCLIB'den çeker ve önbelleğe alır. Söz gösteriminin hukuki boyutu kamuya açık sürümden önce ayrıca değerlendirilir. |
| R3 | MediaRemote özel API'si yeni macOS'larda kısıtlı | Kullanılmaz. Spotify/Music için dağıtık bildirimler + AppleScript (ScriptingBridge). |
| R4 | Sistem sesi izni reddedilebilir | Işık, sözlerin kelime zamanlarından ve parça temposundan türetilen sentetik nabızla çalışmaya devam eder. |
| R5 | Ekran paylaşımında/toplantıda istenmeyen görüntü | `sharingType = .none` + ön plandaki uygulamaya göre otomatik gizleme + tek kısayolla "panik gizle". |
| R6 | Yanıp sönen ışığın ışığa duyarlı kullanıcılar için tehlikesi | Flaş sınırlayıcı, Hareketi Azalt'ta otomatik "Sabit" mod. |
| R7 | Pil tüketimi | Güç yöneticisi; render yalnızca görünür hedef varken çalışır. |

## 10. Başarı ölçütleri

- Kurulumdan ilk görsele kadar medyan süre < 60 sn.
- Test listesindeki (200 parçalık TR/EN/karışık liste) parçaların ≥ %85'inde senkron söz bulunması.
- Kelime zamanlama hatası `aligned` modda medyan ≤ 120 ms.
- 30 günlük çökme oranı < %0.5 oturum.
- Müzik çalarken CPU hedefi (≤ %5) M1 MacBook Air'de sağlanıyor.

## 11. Sürüm kapsamı

- **v1.0**: F-01–F-16 (F-04 Visual ve F-11, F-12 P1), N-01, N-03, N-04, N-07, N-11, N-12; N-02, N-05, N-06 hedefli.
- **v1.5**: N-08, N-09, N-10, deneysel kilit ekranı katmanının genişletilmesi.
- **v2.0**: N-13, N-14.

## 12. Açık sorular

Kapatılanlar:
- ~~Ücretli / ücretsiz / açık kaynak?~~ → Açık kaynak, GPL-3.0-or-later; lisans anahtarı sistemi yok.
- ~~Nihai ürün adı ve bundle ID?~~ → `Lirevo`, `app.lirevo`, `https://lirevo.app`. Tek kaynak: `Config/App.xcconfig`.
- ~~Ticari söz sağlayıcı?~~ → Uygulanmaz; yalnız `LyricsProvider` protokolü genişletmeye açık.

Açık:
1. Klip özelliğinde şarkının sesi dahil edilsin mi? (Telif nedeniyle varsayılan kapalı önerilir.)
