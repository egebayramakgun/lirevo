# Marka politikası / Trademark Policy

**[Türkçe](#türkçe) · [English](#english)**

---

## Türkçe

Lirevo'nun **kaynak kodu** [GNU General Public License v3.0 or later](LICENSE) ile özgürce kullanılabilir, değiştirilebilir ve dağıtılabilir. Bu politika kodu kısıtlamaz.

Ancak **"Lirevo" adı, logosu, uygulama ikonu ve `lirevo.app` alan adı** GPL lisansının kapsamında değildir ve egebayramakgun'a aittir. GPL-3.0'ın 7. bölümü uyarınca bu adlar ve işaretler üzerinde hak verilmemektedir.

### İzin verilenler

- Lirevo'yu adıyla anmak, hakkında yazmak, incelemek ve tanıtmak.
- Resmi sürümleri değiştirmeden yeniden dağıtmak (ör. bir paket yöneticisi aracılığıyla).
- Bir çatalın Lirevo'dan türetildiğini belirtmek: "Lirevo'ya dayanır" veya "Lirevo'nun bir çatalı".

### İzin verilmeyenler (yazılı izin olmadan)

- Değiştirilmiş bir sürümü veya çatalı **Lirevo adıyla ya da logosuyla** dağıtmak.
- Lirevo'ya kolayca karıştırılabilecek bir ad, logo veya ikon kullanmak.
- Bir ürünün veya hizmetin Lirevo projesi tarafından onaylandığı izlenimini vermek.

### Çatalını yeniden adlandırma

Ad, bundle ID ve web sitesi tek bir dosyada tanımlıdır: `Config/App.xcconfig`. Bir çatalı dağıtmadan önce:

1. `APP_PRODUCT_NAME`, `PRODUCT_BUNDLE_IDENTIFIER` ve `APP_WEBSITE` değerlerini kendininkilerle değiştir.
2. `Lirevo/Assets.xcassets` içindeki uygulama ikonunu ve logoyu kendi tasarımınla değiştir.
3. Kendi Sparkle anahtarlarını, appcast adresini ve `capabilities.json` imzalama anahtarını kullan.

İzin almak veya soru sormak için bir issue aç.

---

## English

Lirevo's **source code** is free to use, modify and distribute under the [GNU General Public License v3.0 or later](LICENSE). This policy does not restrict the code.

However, the **"Lirevo" name, logo, app icon and the `lirevo.app` domain** are not covered by the GPL and belong to egebayramakgun. As permitted by section 7 of the GPL-3.0, no rights are granted to these names and marks.

### Allowed

- Referring to Lirevo by name, writing about it, reviewing and promoting it.
- Redistributing unmodified official releases (e.g. through a package manager).
- Stating that a fork is derived from Lirevo: "based on Lirevo" or "a fork of Lirevo".

### Not allowed (without written permission)

- Distributing a modified version or fork **under the Lirevo name or logo**.
- Using a name, logo or icon that could easily be confused with Lirevo.
- Implying that a product or service is endorsed by the Lirevo project.

### Renaming your fork

The name, bundle ID and website are defined in a single file: `Config/App.xcconfig`. Before distributing a fork:

1. Replace `APP_PRODUCT_NAME`, `PRODUCT_BUNDLE_IDENTIFIER` and `APP_WEBSITE` with your own values.
2. Replace the app icon and logo in `Lirevo/Assets.xcassets` with your own artwork.
3. Use your own Sparkle keys, appcast URL and `capabilities.json` signing key.

To request permission or ask questions, open an issue.
