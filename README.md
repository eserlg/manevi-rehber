# Manevi Rehber 🕌

Modern, soft pastel tasarımlı İslami günlük asistan. **Flutter** ile geliştirilencross-platform (Android · iOS · Web/PWA) uygulama. Namaz vakitleri, zikir, dua, Kur'an, Yasin, kıble, vefat hatırası bağış takibi ve daha fazlasını içerir.

🌐 **Canlı demo**: <https://manevi-rehber.vercel.app>

## ✨ Özellikler

### 🕌 Namaz & İbadet
- **Namaz Vakitleri**: Diyanet kaynaklı vakitler (Aladhan API fallback), GPS ile otomatik konum, manuel şehir seçimi, sonraki namaz için geri sayım
- **Namaz Takibi**: Günlük 5 vakit takibi, haftalık tamamlanan gün sayısı, kaza namazı borcu takibi
- **Kıble Bulucu**: Manyometre + ivmeölçer ile gerçek zamanlı pusula, Ka'be'ye uzaklık (Haversine), hizalanma bildirimi (web ve native)
- **Hicri Takvim**: Otomatik Hicri tarih gösterimi, dini günler takvimi

### 📿 Zikir & Dua
- **Zikirmatik**: 8 varsayılan zikir (Subhanallah, Elhamdülillah, Allahu Ekber, La İlahe İllallah, Salavat, Estağfirullah, La Havle, Subhanallahi ve Bihamdihi) + **kullanıcının kendi eklediği zikirler**
- **Zikir Ekleme**: İsim, Arapça, anlam, hedef sayı ile yeni zikir tanımlama; düzenleme/silme
- **Günlük Dualar**: Arapça + Türkçe çeviri, kategori filtreleme, arama, favoriler, paylaşma
- **Özel Gün Mesajları**: Bayram, kandil, cuma mesajları koleksiyonu

### 📖 Kur'an & Yasin
- **Kur'an-ı Kerim**: 114 sure, Arapça + Türkçe meal (Diyanet), ayet ayet navigation, sesli kıraat ve Türkçe meal (Quran.com API + archive.org)
- **Yasin-i Şerif**: Özel okuma sayfası, ayet ayet sesli okuma, **okuma bitince otomatik "bağışla?" sorgusu**
- **Okuma Takibi**: "Kaldığın yerden devam et" özelliği, son okunan ayet kaydı
- **Hatim/Tesbih Bağışı**: Sure tamamlandığında **otomatik bağış sorgusu** → vefat hatırasına tesbih/Yasin/hatim sevabı bağışlama

### 💚 Vefat Hatırası & Bağışlama
- Çoklu kişi kaydı (isim + vefat tarihi)
- Kişi başına: tesbih sayacı, Yasin sayacı, hatim sayacı
- **Manuel miktar girme** ile özelleştirilmiş bağışlanacak miktar
- Vefatın üzerinden geçen gün sayısı
- Bağış animasyonlu şerit ile canlı onay

### 🎨 Tasarım & Platform
- **Soft Pastel Tasarım**: Sage (`#A8D5BA`), krem (`#FDF8F5`), accent rose (`#E8B4B8`), soft blue
- **Material Design 3** + Google Fonts (Amiri, Noto Sans)
- **PWA**: Tam PWA desteği, Service Worker bildirimleri, Web Speech API ile TTS, DeviceOrientation API ile pusula
- **Logo**: Yeni pastel cami + altın hilal ikon (signature work, iOS/Android/Web boyutları otomatik üretildi)

### 📺 Ek Özellikler
- **Canlı Yayın**: Mekke/Medine canlı stream, kıraat videoları (YouTube embed)
- **Siyer**: Efendimiz'in (s.a.v) hayatı bölümleri
- **Namaz Rehberi**: Adım adım namaz kılınışı kategoriler halinde
- **Ana Ekran Widget'ları**: Özelleştirilmiş widget önizleme ekranı
- **Çoklu Kullanıcı**: Cihazda birden fazla kullanıcı profili, per-user scoped veri
- **Geri Bildirim & Puanlama**: Uygulama içi değerlendirme ve mesaj gönderme

## 🛠️ Kurulum

### Gereksinimler

- Flutter SDK 3.0+ (Dart 3.0+)
- Android Studio (Android için)
- Xcode (iOS için, macOS gerekli)
- Vercel CLI (Web/PWA deploy için, opsiyonel)

### Kurulum Adımları

1. **Flutter SDK'yı kurun:**
```bash
# macOS
brew install flutter

# Windows
# https://docs.flutter.dev/get-started/install/windows

# Linux
sudo snap install flutter --classic
```

2. **Projeyi klonlayın:**
```bash
git clone https://github.com/eserlg/manevi-rehber.git
cd manevi-rehber
```

3. **Bağımlılıkları yükleyin:**
```bash
flutter pub get
```

4. **Uygulamayı çalıştırın:**
```bash
# Android
flutter run

# iOS (macOS)
flutter run -d ios
```

5. **Web/PWA (lokal):**
```bash
flutter run -d chrome
```

## 🌐 Web Deploy (Vercel)

```bash
# Flutter web build
flutter build web

# Vercel CLI ile (önerilen)
npm i -g vercel
vercel login
vercel --prod
```

veya repo'yu Vercel'e bağlayıp main branch otomatik deploy edebilirsiniz.

## 📁 Proje Yapısı

```
lib/
├── main.dart                         # App entry, login gate, bottom nav
├── core/
│   ├── constants/                     # Colors, dimensions, strings, city_coordinates
│   └── theme/                         # app_theme.dart
├── data/
│   ├── models/                         # Zikr, Surah, Prayer, Qibla vb.
│   │   ├── zikr.dart                  # Zikr modeli (custom + default)
│   │   ├── quran.dart                  # Surah & Verse modelleri
│   │   ├── prayer_tracking.dart        # Namaz takibi state
│   │   └── ...
│   ├── repositories/
│   │   └── prayer_repository.dart     # Diyanet + Aladhan + Quran.com API
│   └── services/                       # Tüm servisler (web/native stub pattern)
│       ├── local_storage_service.dart  # Per-user scoped storage + custom zikr
│       ├── quran_audio_service.dart    # Sesli kıraat + meal
│       ├── browser_compass_web.dart    # PWA compass
│       └── ...
└── presentation/
    ├── providers/providers.dart       # Riverpod state management
    ├── screens/
    │   ├── home_screen.dart            # Dashboard, quick actions
    │   ├── prayer_times_screen.dart    # Namaz vakitleri
    │   ├── zikr_screen.dart            # Zikirmatik (+ custom zikr CRUD)
    │   ├── yasin_screen.dart            # Yasin-i Şerif özel sayfa
    │   ├── quran_screen.dart           # Kur'an (sure + ayet + auto-donate)
    │   ├── qibla_screen.dart            # Kıble bulucu
    │   ├── prayers_screen.dart         # Günlük dualar
    │   ├── sirah_screen.dart           # Siyer
    │   ├── prayer_guide_screen.dart    # Namaz rehberi
    │   ├── live_stream_screen.dart     # Canlı yayın
    │   └── settings_screen.dart        # Ayarlar
    └── widgets/                        # Reusable widgets
        ├── memorial_donation_sheet.dart # Bağışlama sheet (manuel mlktar)
        ├── zikr_counter.dart           # Dairesel sayaç
        └── ...

assets/
├── data/                              # JSON veriler (dualar, Kur'an, dini günler)
└── brand/                             # Logo kaynakları (SVG + PNG master)

tools/
└── generate_icons.py                   # Tüm platformlar için ikon üreteci (Pillow)
```

## 🔌 API'ler

| Servis | Amaç | Endpoint |
|--------|------|----------|
| **Diyanet (imsakiyem.com)** | Namaz vakitleri (1. öncelik) | `https://ezanvakti.imsakiyem.com/api/prayer-times/{id}/monthly` |
| **Aladhan API** | Namaz vakitleri (fallback) | `https://api.aladhan.com/v1/timings` |
| **Quran.com API** | Sureler ve ayetler (fallback) | `https://api.quran.com/api/v4/` |
| **Archive.org** | Türkçe meal sesli okuma | `https://archive.org/download/...` |
| **Wikimedia Commons** | Ezan sesi (CC0) | `https://upload.wikimedia.org/...` |

**Offline-first**: Tüm Kur'an ve dualar `assets/data/` altında JSON olarak önbelleklenir; API'ler sadece gerekli güncellemeleri yapar.

## 📱 Platformlar

- ✅ **Android** (API 21+)
- ✅ **iOS** (12.0+)
- ✅ **Web/PWA** (Vercel'de canlı: <https://manevi-rehber.vercel.app>)
  - Service Worker bildirimleri (namaz vakitleri için)
  - Web Speech API (Türkçe meal sesli okuma)
  - DeviceOrientation API (kıble pusulası)
  - Yüklenebilir PWA (installable)

## 🎨 Tasarım Sistemi

- **Renk paleti**: Soft sage pastel + altın aksanlar
- **Tipografi**: Amiri (Arapça başlıklar), Noto Sans (Türkçe gövde)
- **Spacing**: 8pt grid sistemi
- **Border radius**: 8/16/24dp
- **Shadows**: Yumuşak gölgeler (0.08-0.12 opacity)
- **Logo**: Yeni pastel cami + hilal tasarım (SVG kaynaktan tüm boyutlar `tools/generate_icons.py` ile üretilir)

## 📋 Roadmap

- [x] Namaz vakitleri (Diyanet + Aladhan fallback)
- [x] Zikirmatik + custom zikr ekleme
- [x] Kur'an okuma + Türkçe meal + sesli okuma
- [x] Yasin-i Şerif özel sayfası + otomatik bağış sorgusu
- [x] Vefat hatırası + bağışlama (manuel miktar)
- [x] Kıble bulucu (native + PWA)
- [x] Namaz takibi + kaza takibi
- [x] PWA: Service Worker bildirimleri, compass, TTS
- [ ] Ana ekran widget'ları (Android home_widget)
- [ ] Dark mode
- [ ] Çoklu dil desteği
- [ ] Kur'an sesli okuma reciter seçimi
- [ ] Favoriler ve "son okunan" gelişmiş takip

## 🤝 Katkıda Bulunma

1. Fork edin
2. Feature branch oluşturun (`git checkout -b feature/yeni-ozellik`)
3. Commit edin (`git commit -m 'Yeni özellik eklendi'`)
4. Push edin (`git push origin feature/yeni-ozellik`)
5. Pull Request açın

## 📄 Lisans

Bu proje MIT Lisansı altında lisanslanmıştır.

## 👨‍💻 Geliştirici

**Manevi Rehber** — Müslümanların günlük ibadetlerine yardımcı olmak amacıyla geliştirilmiştir.

Canlı: <https://manevi-rehber.vercel.app>

---

*"Bu uygulama Müslümanların günlük ibadetlerine yardımcı olmak amacıyla geliştirilmiştir."*