# Manevi Rehber App Store Hazırlık Notları

## Proje Bilgileri

- App adı: Manevi Rehber
- Bundle ID: `com.eseru.manevirehber`
- Version: `1.0.0`
- Build: `1`
- Platform: iOS, iPhone
- Minimum iOS: 13.0

## Bu repoda hazırlananlar

- `ios/` Flutter iOS projesi oluşturuldu.
- `ios/Runner/Info.plist` uygulama adı, izin metinleri ve export compliance için düzenlendi.
- `ios/Runner/PrivacyInfo.xcprivacy` eklendi ve Xcode resource build phase'e bağlandı.
- iOS AppIcon seti `Manevi Rehber` için yeniden üretildi.
- App Store açıklama, anahtar kelime, privacy ve review notları `app_store/` altında hazırlandı.

## Mac üzerinde yapılacaklar

1. Projeyi macOS cihaza taşı.
2. Flutter ve Xcode kurulu olduğundan emin ol.
3. Terminalde proje kökünde çalıştır:

```bash
flutter clean
flutter pub get
flutter build ios --release --no-codesign
open ios/Runner.xcworkspace
```

4. Xcode içinde `Runner` target > Signing & Capabilities:
- Team: Apple Developer hesabını seç.
- Bundle Identifier: `com.eseru.manevirehber` uygun değilse Apple hesabında benzersiz bir bundle id ile değiştir.
- Signing: Automatically manage signing açık olabilir.

5. Xcode > Product > Archive ile arşiv oluştur.
6. Organizer üzerinden Validate ve Distribute App > App Store Connect yoluyla yükle.

## App Store Connect'te doldurulacaklar

- App Name: `Manevi Rehber`
- Subtitle: `Namaz, Kur'an, dua ve zikir rehberi`
- Category: Lifestyle veya Reference
- Age Rating: 4+
- Privacy Policy URL: gerçek URL ile değiştir.
- Support URL: gerçek URL ile değiştir.
- Review Notes: `app_store/review/review_notes.txt`
- Açıklama/anahtar kelimeler: `app_store/metadata/tr-TR/`

## Dikkat

- Windows üzerinde iOS `.ipa` üretilemez ve App Store'a yükleme yapılamaz. Bunun için macOS + Xcode + Apple Developer Program hesabı gerekir.
- App Store Connect'te bundle id daha önce alınmışsa `com.eseru.manevirehber` değiştirilmeli.
- Gizlilik URL'leri `example.com` bırakılmamalı; yayın öncesi gerçek sayfalara çevrilmeli.
