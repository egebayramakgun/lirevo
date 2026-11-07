# Güvenlik politikası / Security Policy

**[Türkçe](#türkçe) · [English](#english)**

---

## Türkçe

### Desteklenen sürümler

Güvenlik düzeltmeleri yalnızca **en son yayınlanan sürüm** için yapılır. Güncellemeler uygulama içinden (Sparkle) dağıtılır.

### Güvenlik açığı bildirme

Güvenlik açıklarını **herkese açık issue olarak bildirme**. Bunun yerine GitHub'ın özel bildirim özelliğini kullan:

**[Güvenlik açığı bildir](https://github.com/egebayramakgun/lirevo/security/advisories/new)**

Bildiriminde şunlar olsun:
- Etkilenen sürüm, macOS sürümü ve Mac modeli,
- Sorunun açıklaması ve olası etkisi,
- Yeniden üretme adımları veya kavram kanıtı.

Bildirimi birkaç gün içinde yanıtlamayı, durumu düzenli olarak paylaşmayı ve düzeltme yayınlandıktan sonra (istersen) seni anmayı hedefliyoruz. Lütfen düzeltme yayınlanana kadar ayrıntıları açıklama.

### Kapsam

Özellikle şunlarla ilgili bildirimler önemlidir:
- Güncelleme hattı (Sparkle appcast, EdDSA imzaları),
- Uzaktan özellik kapatma dosyası (`capabilities.json`) ve imza doğrulaması,
- Ağ istekleri ve kişisel verinin sızması,
- Uygulamanın AppleScript ile Spotify/Müzik'e gönderdiği komutlar,
- Deneysel kilit ekranı katmanı (`LockScreenBridge`).

Üçüncü taraf hizmetlerdeki (LRCLIB, Spotify, Apple) açıkları ilgili sağlayıcıya bildir.

---

## English

### Supported versions

Security fixes are made only for the **latest released version**. Updates are delivered in-app (Sparkle).

### Reporting a vulnerability

Please **do not report security vulnerabilities in public issues**. Use GitHub's private reporting instead:

**[Report a vulnerability](https://github.com/egebayramakgun/lirevo/security/advisories/new)**

Please include:
- Affected version, macOS version and Mac model,
- A description of the issue and its potential impact,
- Steps to reproduce or a proof of concept.

We aim to respond within a few days, keep you updated, and credit you (if you wish) once a fix is released. Please don't disclose details until a fix is available.

### Scope

Reports about the following are especially valuable:
- The update pipeline (Sparkle appcast, EdDSA signatures),
- The remote feature kill switch (`capabilities.json`) and its signature verification,
- Network requests and personal data leaks,
- AppleScript commands the app sends to Spotify/Music,
- The experimental lock screen layer (`LockScreenBridge`).

Please report vulnerabilities in third-party services (LRCLIB, Spotify, Apple) to the respective provider.
