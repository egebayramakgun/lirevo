# UI/UX Brief — Lirevo

> Görsel ve etkileşim tasarımı. Uygulamanın kendisi neredeyse görünmez; asıl ürün müziğe eşlik eden sahnedir.

---

## 1. Tasarım ilkeleri

1. **Sahne önce gelir.** Arayüz yalnızca sahneyi ayarlamak içindir. Menüler küçük, hızlı ve sessizdir.
2. **Albüm yönetir.** Varsayılan olarak renk, ton ve enerji çalan müzikten gelir. Kullanıcı isterse kontrolü alır.
3. **Asla göz yormaz.** Yumuşak geçişler, flaş sınırı, okunabilir kontrast. Işık mekânı doldurur ama bağırmaz.
4. **Bozulduğunda bile güzel görünür.** Söz yoksa ışık; ses analizi yoksa yumuşak nabız; kapak yoksa sahnenin kendi renkleri. Kullanıcı hata ekranı görmez, daha sade bir sahne görür.
5. **macOS yerlisi.** SF Pro, SF Symbols, sistem materyalleri, macOS 26'da Liquid Glass. Özel kontrol yerine sistem kontrolü.

## 2. Marka ve ton

- Ad: Lirevo. Kodda ve metinlerde sabit yazılmaz; `PRODUCT_NAME`'den okunur (`Localizable.xcstrings` içinde `%@`). Menü ikonu: yarım halka içinde tek bir nota/ışık noktası (SF Symbol tabanlı özel şablon görsel, 18×18 pt, template rendering).
- Dil tonu: Kısa, sıcak, teknik terimsiz. "Sistem sesi analiz edilemiyor" değil, "Işık şimdilik sözlerin ritmini izliyor."
- Diller: Türkçe, İngilizce. Tüm metinler `Localizable.xcstrings`.

## 3. Bilgi mimarisi

```
Menü çubuğu paneli
├─ Şimdi çalıyor (kapak, başlık, sanatçı, ◀◀ ▶ ▶▶)
├─ Sahneler (yatay kaydırılan kartlar)
├─ Hızlı geçişler: Işık · Sözler · Kart · Sahne Modu
├─ Söz stili: Ship · Fisheye · Fisheye Visual · Visual
├─ Senkron: kaydırıcı ±2 sn
└─ Ayarlar… · Sistem Durumu · Çıkış

Ayarlar penceresi (tek pencere, kenar çubuklu)
├─ Sahneler
├─ Sözler
├─ Işık
├─ Kart
├─ Ekranlar
├─ Kısayollar
└─ Gelişmiş
```

## 4. Menü çubuğu paneli

- Boyut: 340 pt genişlik, içeriğe göre yükseklik (maks. 560 pt).
- Materyal: sistem menü materyali; macOS 26'da Liquid Glass.
- Üst bölüm (Şimdi çalıyor): 56×56 pt kapak (8 pt köşe), başlık (13 pt semibold), sanatçı (12 pt secondary), kaynak rozeti (Spotify/Müzik, 10 pt). Oynatma kontrolleri SF Symbols, 28 pt hedef alanı.
- Sahne kartları: 96×64 pt, canlı mini önizleme (statik görsel + aktif sahnede hafif animasyon), alt yazı 11 pt. Seçili kart 2 pt vurgu çerçevesi (palet primary rengi).
- Hızlı geçişler: 4 adet ikon+etiket düğmesi, 2×2 ızgara; açık durumda dolgu.
- Söz stili: segment kontrol.
- Senkron kaydırıcı: ortada sıfır işareti, değer etiketi "+0.3 sn", çift tıklama sıfırlar.
- Alt satır: metin düğmeleri.
- Uyarı durumu: Bir alt sistem `unavailable` ise panelin en üstünde tek satırlık sarı bilgi şeridi, tıklanınca Sistem Durumu açılır.

## 5. Onboarding

- Pencere 640×480 pt, ortada, kenarsız başlık çubuğu.
- Arka planda **canlı demo sahne**: gömülü telifsiz demo zaman çizgisi (sentetik sözler: "Işık / yavaşça / yükselir…") ile ışık ve Fisheye stilinde sözler. Kullanıcı daha hiçbir izin vermeden ürünün ne yaptığını görür.
- Adım göstergesi: 4 nokta (Hoş geldin · Otomasyon · Sistem sesi · Sahne).
- Her izin adımı: ne istediğimiz (tek cümle), neden (tek cümle), ne istemediğimiz (örn. "Mikrofon kullanılmaz"), "İzin ver" (birincil) ve "Şimdilik geç" (ikincil).
- Sahne seçimi adımı: 4 büyük kart, üzerine gelince demo sahne o presete geçer. Altında görünürlük seçimi (segment): **Her zaman** (varsayılan) / **Sadece Sahne Modu'nda**.

## 6. Ayarlar penceresi

Genel: 720×520 pt, `NavigationSplitView`, sağda form. Her değişiklik **canlı** uygulanır (Kaydet düğmesi yok). Sağ üstte "Önizle" düğmesi: 5 sn boyunca masaüstünde sahneyi gösterir (görünürlük modu "Her zaman" olmayan kullanıcılar için).

### 6.1 Sahneler
- Izgara: hazır sahneler (kilitli ikon, çoğaltılabilir) + kullanıcı sahneleri.
- İşlemler: Yeni, Çoğalt, Yeniden adlandır, Sil, İçe aktar (`.lirevoscene`), Dışa aktar.
- Hazır sahneler:

| Sahne | Söz stili | Işık | Renk | Hareket |
|---|---|---|---|---|
| Sinema | Fisheye | İnce (6 pt), glow 40 | Albüm | Yumuşak, söze duyarlı |
| Kulüp | Ship | Kalın (40 pt), glow 80 | Albüm, doygunluk +%15 | Ritim, yüksek |
| Sessiz | Visual | Çok ince (2 pt), glow 20 | Albüm, düşük doygunluk | Sabit nefes |
| Odak | Kapalı | İnce (4 pt), glow 30 | Albüm | Sabit idle |

### 6.2 Sözler
- Stil (4 kart, canlı küçük önizleme).
- Yazı tipi: SF Pro Display / SF Pro Rounded / New York (serif) / SF Mono. Ağırlık: Regular–Heavy.
- Boyut: S / M / L / XL (Sahne Modu'nda otomatik büyür).
- Konum (masaüstü hedefi için): Orta / Alt / Sol alt köşe / Sağ alt köşe.
- Renkler: Söz · Vurgu · İkincil (renk kuyuları) + "Albümden otomatik" anahtarı. Elle modda beş rolün (bu üçü + Işık sekmesindeki iki ışık rengi) her biri ayrı ayarlanır; albüm modundaki eşleme `backend_schema.md` §5.1.
- Simgeler (Visual stilleri için): Açık/Kapalı, "Emoji tercih et" anahtarı.
- Çeviri satırı (v1.5): Kapalı / hedef dil seçimi. Romanizasyon: Kapalı / Açık.
- Söz kaynakları: sıralanabilir liste (Yerel dosya, LRCLIB), yerel klasör seçici, "Söz önbelleğini temizle".

### 6.3 Işık
- Canlı mini ekran önizlemesi (notch'lu MacBook silüeti).
- Animasyon: Müzik senkronu / Söze duyarlı / Sabit idle / Nefes.
- Gradient: 1 renk / 2 renk; oran kaydırıcısı (Primary %60 / Secondary %40).
- Kalınlık (1–120 pt), Glow (0–100), Yoğunluk (0–100).
- Notch: Etrafını sar / Atla.
- "Albüm rengini geçersiz kıl" + iki renk kuyusu.
- Güvenlik: "Yumuşak flaş koruması" (varsayılan açık, kapatılırsa onay iletişim kutusu).

### 6.4 Kart
- Göster: Hiçbir zaman / Kilitliyken ve Sahne Modu'nda / Her zaman.
- Konum: Alt orta / Sol alt / Sağ alt.
- Boyut: Kompakt / Geniş. Kontrolleri göster (yalnız masaüstü ve Stage'de etkileşimli).

### 6.5 Ekranlar
- Algılanan ekranlar listesi, her biri için: Işık açık/kapalı, Sözler açık/kapalı, "Sözlerin ana ekranı".

### 6.6 Kısayollar
| Eylem | Varsayılan |
|---|---|
| Sahne Modu | ⌃⌥⌘S |
| Panik gizle | ⌃⌥⌘H |
| Sonraki söz stili | ⌃⌥⌘L |
| Işığı aç/kapat | ⌃⌥⌘I |
| Senkron −/+ 100 ms | ⌃⌥⌘← / ⌃⌥⌘→ |
| Sonraki sahne | ⌃⌥⌘N |

### 6.7 Gelişmiş
- Görünürlük modu: Her zaman (varsayılan) / Sadece Sahne Modu'nda / Sadece kilitliyken (yalnız deneysel kilit ekranı katmanı açıkken listelenir).
- Ekranı uyanık tut (müzik çalarken).
- Boşta kalınca Sahne Modu: Kapalı / 1–30 dk.
- Otomatik gizle: Tam ekran uygulamalarda, video görüşme uygulamalarında, sunumlarda (her biri anahtar) + özel uygulama listesi.
- Güç: Pilde kare hızını sınırla, Düşük Güç Modu'nda sadeleştir.
- **Deneysel**: Kilit ekranında göster (açıklamalı, ayrı kutuda, turuncu "Deneysel" rozeti).
- Girişte başlat.
- Teşhis: Sistem Durumu'nu aç, Teşhis paketini kopyala.

## 7. Sahne bileşenlerinin görsel spesifikasyonu

### 7.1 Çerçeve ışığı
- Ekranın fiziksel köşe yarıçapını takip eder (dahili ekran yarıçapı yaklaşık değer tablosu; harici ekranlarda 0).
- Düşüş eğrisi: `I(d) = exp(-d / (glow × 0.6 + 4))`, kalınlık bandı içinde tam yoğunluk.
- Gradient kenar boyunca akar (saat yönünde, döngü 12 sn); ritim vuruşunda akış hızı anlık 1.6×.
- Nabız: atak 40 ms, sönüm 280 ms (ease-out). Yumuşak modda atak 90 ms, sönüm 450 ms, genlik ×0.6.
- Notch "sar" modunda ışık notch'un alt kenarını ve yanlarını 3 pt boşlukla takip eder.

### 7.2 Söz stilleri

| Stil | Düzen | Aktif kelime | Geçmiş kelimeler | Gelecek kelimeler |
|---|---|---|---|---|
| Ship | Satırlar dikey duvar, 3D eğim 18°, yavaş sürüklenme (Y ekseni ±6°, 20 sn) | Vurgu rengi, ölçek 1.06, hafif glow | Söz rengi %90 opak | İkincil renk %45 |
| Fisheye | Dikey yığın, merkez satır büyük, dışbükey lens (güç 0.35) | Merkezde, en büyük, vurgu rengi | Yukarı kayar, lens dışında küçülür | Aşağıda, küçük |
| Fisheye Visual | Fisheye + simgeler satır sonunda | + simge 1.2× pop | Simge %40 opak | Simge gizli |
| Visual | Düz 2–3 satır, ortalı | Vurgu rengi + yanında simge pop (yay, 220 ms) | Söz rengi | İkincil |

- Kelime "yanma" animasyonu: `exact/aligned` → 60 ms renk geçişi + soldan sağa maske. `estimated` → kelime süresi boyunca soldan sağa dolma (karaoke dolgusu), keskin geçiş yok.
- Satır geçişi: 320 ms, spring (response 0.45, damping 0.85).
- Enstrümantal: üç nokta, her biri 1.2 sn döngüde sırayla parlar.
- Tipografi: masaüstünde L = 44 pt, Sahne Modu'nda ekran yüksekliğinin %7'si. Satır aralığı 1.15. Maks. satır genişliği ekranın %70'i, uzun satırlar dengeli bölünür.
- Çeviri satırı: ana satırın %55 boyutu, ikincil renk, italik değil.

### 7.3 Cam kart
- 360×96 pt (kompakt), 420×132 pt (geniş). Köşe 22 pt.
- macOS 26: Liquid Glass, palet primary ile %12 renklendirme. 14–15: `hudWindow` materyali + 0.5 pt beyaz %20 kenar.
- İçerik: kapak (köşe 12 pt), başlık 15 pt semibold, sanatçı 13 pt, ince ilerleme çubuğu (vurgu rengi), kontroller.
- Kilit ekranında kontroller gösterilir ama etkileşim yalnızca kilit host'u destekliyorsa açılır; aksi halde salt bilgi.

### 7.4 Sahne Modu
- Arka plan: kapaktan türetilmiş, ağır bulanık (radius 80) ve karartılmış (%70) tam ekran zemin; 30 sn'de bir çok yavaş yakınlaşma (Ken Burns, ölçek 1.0→1.04).
- Işık çerçevesi + büyük sözler (Fisheye veya sahnenin stili) + alt orta kart.
- Kapanış ipucu: açılıştan 2 sn sonra 3 sn süreyle alt köşede "Çıkmak için herhangi bir tuşa bas" (11 pt, %50 opak).

## 8. Hareket (motion) sistemi

| Token | Değer |
|---|---|
| `motion.fast` | 120 ms ease-out |
| `motion.base` | 240 ms ease-in-out |
| `motion.slow` | 480 ms ease-in-out |
| `motion.palette` | 800 ms OKLab interpolasyon |
| `motion.spring.line` | response 0.45, damping 0.85 |
| `motion.spring.pop` | response 0.3, damping 0.6 |

**Hareketi Azalt**: 3D, lens, sürüklenme, Ken Burns, nabız kapalı; yalnız opaklık ve renk geçişleri (240 ms). Işık "Sabit idle".

## 9. Renk ve kontrast

- Paletten üç rol: `lyric` (ana metin), `highlight` (aktif kelime, ilerleme), `secondary` (gelecek/ikincil metin).
- Metin her zaman koyu sahne zemini üzerinde (masaüstü hedefinde metin arkasında %35 karartılmış yumuşak gölge "scrim", yarıçap 40) — açık duvar kâğıtlarında okunabilirlik için.
- Kontrast: `lyric` ve `highlight` ≥ 4.5:1, `secondary` ≥ 3:1 (scrim üzerinde hesaplanır).
- Kontrastı Artır açıkken: scrim %60, ikincil metin `lyric` rengine yaklaşır, glow azalır.
- Siyah-beyaz kapaklar: palet monokrom gelirse sahnenin "nötr aksan" rengi (sıcak beyaz) kullanılır.

## 10. Erişilebilirlik ve güvenlik

- Işığa duyarlılık: saniyede en fazla 3 büyük parlaklık değişimi; kırmızı doygun flaş sınırı (kırmızı kanal ağırlıklı değişimler ayrıca sınırlanır).
- VoiceOver: tüm menü ve ayar kontrolleri etiketli; overlay pencereleri erişilebilirlik ağacından gizli (`accessibilityHidden`).
- Klavye: Ayarlar tamamen klavyeyle gezilebilir.
- Dinamik tür: Ayarlar ve menü sistem metin boyutunu izler.

## 11. Boş ve hata durumları (kullanıcı metni)

| Durum | Metin |
|---|---|
| Hiçbir şey çalmıyor | "Spotify veya Müzik'te bir şarkı aç." |
| Söz bulunamadı | "Bu şarkının sözlerini bulamadık. Işık seninle." + "Söz dosyası ekle" |
| Ses izni yok | "Işık şimdilik sözlerin ritmini izliyor." + "Sistem sesini aç" |
| Otomasyon izni yok | "Çalan şarkıyı görebilmem için izin gerekiyor." + "İzni aç" |
| Kilit katmanı desteklenmiyor | "Bu macOS sürümünde kilit ekranında gösteremiyoruz. Sahne Modu tam ekran aynı deneyimi sunar." |

## 12. Teslim edilecek tasarım dosyaları

1. Menü paneli (normal, çalıyor, uyarı).
2. Onboarding 4 ekran.
3. Ayarlar 7 sekme.
4. 4 söz stili × (masaüstü, Sahne Modu) mockup + hareket prototipi.
5. Işık çerçevesi: notch'lu MacBook, harici ekran, ince/kalın/glow varyasyonları.
6. Cam kart: macOS 26 ve 14–15 varyantı.
7. Uygulama ikonu (1024 pt) ve menü ikonu şablonu.
