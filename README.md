# Ruh Huzur - İslami Günlük Yardımcı 🕌

Modern, soft pastel tasarımlı İslami günlük uygulaması. Namaz vakitleri, zikir sayacı, dualar ve Kur'an okuma özellikleri içerir.

## ✨ Özellikler

- **📍 Namaz Vakitleri**: GPS ile otomatik konum belirleme, tüm vakitler
- **🕌 Zikirmatik**: Tesbihat sayacı (Subhanallah, Elhamdülillah, Allahu Ekber, La İlhe İllallah)
- **📖 Günlük Dualar**: Arama ve kategori filtreleme özellikli dua koleksiyonu
- **📚 Kur'an-ı Kerim**: Tüm sureler ve Türkçe meal
- **🕐 Sonraki Namaz**: Geri sayım ve bildirimler
- **📅 Hicri Takvim**: Otomatik Hicri tarih gösterimi
- **🎨 Soft Pastel Tasarım**: Huzurlu, modern arayüz

## 🛠️ Kurulum

### Gereksinimler

- Flutter SDK 3.0+
- Android Studio (Android geliştirme için)
- Xcode (iOS geliştirme için, macOS gerekli)

### Kurulum Adımları

1. **Flutter SDK'yı kurun:**
```bash
# Windows için
https://docs.flutter.dev/get-started/install/windows

# macOS için
brew install flutter

# Linux için
sudo snap install flutter --classic
```

2. **Projeyi klonlayın:**
```bash
cd Documents
git clone <repo-url> RuhHuzur
cd RuhHuzur
```

3. **Bağımlılıkları yükleyin:**
```bash
flutter pub get
```

4. **Uygulamayı çalıştırın:**
```bash
# Android için
flutter run

# iOS için (macOS)
flutter run -d ios
```

## 📁 Proje Yapısı

```
lib/
├── main.dart                 # Uygulama giriş noktası
├── core/
│   ├── constants/           # Renkler, boyutlar, stringler
│   └── theme/              # Uygulama teması
├── data/
│   ├── models/             # Veri modelleri
│   ├── repositories/       # API çağrıları
│   └── services/           # Konum, depolama servisleri
└── presentation/
    ├── providers/          # Riverpod state management
    ├── screens/            # Uygulama ekranları
    └── widgets/            # Yeniden kullanılabilir widgetlar
```

## 🔌 API'ler

- **Namaz Vakitleri**: [Aladhan API](https://aladhan.com/prayer-times-api)
- **Kur'an**: [Quran.com API](https://quran.com/api)

## 📱 Platformlar

- ✅ Android (API 21+)
- ✅ iOS (12.0+)

## 🎨 Tasarım

- Soft pastel renk paleti
- Material Design 3
- Google Fonts (Amiri, Noto Sans)

## 📋 Todo

- [ ] Widget desteği (Ana ekran widget'ları)
- [ ] Bildirim sistemi
- [ ] Kur'an sesli okuma
- [ ] Favoriler ve son okunan takibi
- [ ] Dark mode
- [ ] Çoklu dil desteği

## 🤝 Katkıda Bulunma

1. Fork edin
2. Feature branch oluşturun (`git checkout -b feature/yeni-ozellik`)
3. Commit edin (`git commit -m 'Yeni özellik eklendi'`)
4. Push edin (`git push origin feature/yeni-ozellik`)
5. Pull Request açın

## 📄 Lisans

Bu proje MIT Lisansı altında lisanslanmıştır.

## 👨‍💻 Geliştirici

Ruh Huzur - İslami Günlük Yardımcın

---

*Bu uygulama Müslümanların günlük ibadetlerine yardımcı olmak amacıyla geliştirilmiştir.*
