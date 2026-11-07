## Özet / Summary

<!-- Bu değişiklik ne yapıyor ve neden? Görev kimliği varsa ekle (ör. M2-T4). İlgili issue: #... -->
<!-- What does this change do and why? Add the task ID if any (e.g. M2-T4). Related issue: #... -->

## Manuel test / Manual testing

<!-- Gerçek donanımda doğrulanması gerekenler için adımlar: ne yaptın, ne gördün, hangi log kategorisi. -->
<!-- Steps for things that need real hardware: what you did, what you saw, which log category. -->

## Kontrol listesi / Checklist

- [ ] Derleme uyarısız (Swift 6 strict concurrency) / Builds without warnings
- [ ] Birim testleri yazıldı ve geçiyor / Unit tests added and passing
- [ ] Servisse `HealthReporting` uygulandı / `HealthReporting` implemented for services
- [ ] Hata yolu düşünüldü (`docs/app_flow.md` §13) / Failure path considered
- [ ] Kullanıcıya görünen metinler TR + EN / User-facing strings in TR + EN
- [ ] Görsel değişikliklerde Hareketi Azalt / Kontrastı Artır kontrol edildi / Reduce Motion / Increase Contrast checked
- [ ] Performans bütçesi aşılmadı (render değişikliklerinde) / Performance budget respected
- [ ] Yeni Swift dosyalarında SPDX başlığı var / SPDX header in new Swift files
- [ ] Yeni üçüncü taraf bağımlılık yok / No new third-party dependencies
- [ ] Gerekirse `docs/` güncellendi / `docs/` updated if needed
