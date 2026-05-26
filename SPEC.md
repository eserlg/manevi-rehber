# Ruh Huzur - Islamic Daily Companion

## 📱 Project Overview

**Project Name:** Ruh Huzur (Soul Serenity)
**Type:** Cross-platform Mobile Application (Flutter)
**Core Functionality:** A comprehensive Islamic daily companion app providing prayer times, zikr counter, daily prayers, Quran reading, and home screen widgets with a soft pastel, peaceful aesthetic.
**Target Users:** Muslims seeking a calming, accessible daily Islamic companion
**Platforms:** Android & iOS
**Publishing Target:** Google Play Store & Apple App Store

---

## 🎨 Design Specification

### Color Palette (Soft Pastel)

| Color | Hex Code | Usage |
|-------|----------|-------|
| Primary | `#A8D5BA` | App bar, primary buttons, active states |
| Secondary | `#F5E6CC` | Card backgrounds, secondary elements |
| Accent | `#E8B4B8` | Highlights, selected items, CTAs |
| Background | `#FDF8F5` | Main screen background |
| Surface | `#FFFFFF` | Cards, bottom sheets |
| Text Primary | `#4A4A4A` | Main text |
| Text Secondary | `#8B8B8B` | Subtitles, hints |
| Success | `#A8D5BA` | Completed states |
| Soft Blue | `#B8D4E8` | Prayer time highlight |

### Typography

| Style | Font | Size | Weight |
|-------|------|------|--------|
| App Title | Amiri | 28sp | Bold |
| Screen Title | Noto Sans | 24sp | SemiBold |
| Card Title | Noto Sans | 18sp | Medium |
| Body | Noto Sans | 16sp | Regular |
| Caption | Noto Sans | 14sp | Regular |
| Small | Noto Sans | 12sp | Regular |

### Spacing System (8pt Grid)

- XS: 4dp
- SM: 8dp
- MD: 16dp
- LG: 24dp
- XL: 32dp
- XXL: 48dp

### Border Radius

- Small: 8dp
- Medium: 16dp
- Large: 24dp
- Circle: 50%

### Shadows

- Soft: `0 2dp 8dp rgba(0,0,0,0.08)`
- Medium: `0 4dp 16dp rgba(0,0,0,0.12)`

---

## 🏗️ Architecture

### Tech Stack

- **Framework:** Flutter 3.x
- **State Management:** Riverpod
- **HTTP Client:** Dio
- **Local Storage:** SharedPreferences + Hive
- **Location:** Geolocator
- **Notifications:** flutter_local_notifications
- **Widgets:** home_widget (Android), home_widget (iOS)

### Project Structure

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   │   ├── colors.dart
│   │   ├── strings.dart
│   │   └── dimensions.dart
│   ├── theme/
│   │   └── app_theme.dart
│   └── utils/
│       └── date_utils.dart
├── data/
│   ├── models/
│   │   ├── prayer_times.dart
│   │   ├── zikr.dart
│   │   ├── prayer.dart
│   │   └── qibla.dart
│   ├── repositories/
│   │   ├── prayer_repository.dart
│   │   └── quran_repository.dart
│   └── services/
│       ├── location_service.dart
│       └── notification_service.dart
├── presentation/
│   ├── screens/
│   │   ├── home_screen.dart
│   │   ├── prayer_times_screen.dart
│   │   ├── zikr_screen.dart
│   │   ├── prayers_screen.dart
│   │   ├── quran_screen.dart
│   │   └── qibla_screen.dart
│   ├── widgets/
│   │   ├── prayer_card.dart
│   │   ├── zikr_counter.dart
│   │   ├── soft_button.dart
│   │   └── compass_widget.dart
│   └── providers/
│       └── providers.dart
└── assets/
    └── data/
        └── daily_prayers.json
```

---

## 📋 Features Specification

### 1. Prayer Times (Ezan Vakti) - 🔴 CRITICAL

**API:** Aladhan Prayer Times API
**Endpoint:** `https://api.aladhan.com/v1/timings`

**Features:**
- GPS-based automatic location detection
- Manual city selection fallback
- Display all 5 daily prayer times:
  - İmsak (Fajr)
  - Güneş (Sunrise)
  - Öğle (Dhuhr)
  - İkindi (Asr)
  - Akşam (Maghrib)
  - Yatsı (Isha)
- Next prayer countdown timer
- Prayer time notifications (optional)
- Hijri calendar date display

**Data Display:**
- Current prayer highlighted
- Time remaining until next prayer
- Weekly prayer schedule view

### 2. Zikirmatik (Tasbeeh Counter) - 🔴 CRITICAL

**Features:**
- Multiple zikr presets:
  - Subhanallah (33x)
  - Elhamdülillah (33x)
  - Allahu Ekber (33x)
  - La İlhe İllallah (1x)
  - Custom counter
- Visual counter with large number display
- Haptic feedback on tap
- Progress indicator (current/target)
- Daily reset option
- Session statistics
- Auto-save progress

**UI:**
- Large central counter display
- Circular progress ring
- Tap anywhere to increment
- Swipe down to reset
- Zikr selection carousel

### 3. Günlük Dualar (Daily Prayers) - 🟡 IMPORTANT

**Data Source:** Local JSON database (50+ prayers)
**Categories:**
- Sabah duaları (Morning prayers)
- Ahiret duaları (Afterlife prayers)
- Günlük dualar (Daily prayers)
- Hasta duaları (Sick prayers)
- Yemek duaları (Meal prayers)

**Features:**
- Searchable prayer list
- Prayer detail view with Arabic + Turkish translation
- Favorite prayers
- Share prayer option

### 4. Kur'an-ı Kerim (Quran) - 🟡 IMPORTANT

**API:** Quran.com API
**Endpoint:** `https://api.quran.com/api/v4/`

**Features:**
- Surah list with Arabic names
- Audio playback (tilavet)
- Verse-by-verse display
- Translation (Turkish - Diyanet)
- Reading progress tracking
- Last read position
- Bookmark favorites

**Surahs:** Full list of 114 surahs
**Audio:** Multiple reciters available

### 5. Widget System - 🟡 IMPORTANT

**Android Widgets:**
- Prayer times widget (small, medium, large)
- Next prayer countdown widget
- Daily verse widget

**iOS Widgets:**
- iOS 16+ WidgetKit support
- Prayer times widget
- Next prayer widget

**Widget Content:**
- Next prayer name and time
- Remaining time countdown
- Hijri date
- Soft pastel design matching app

### 6. Kıble Bulucu (Qibla Finder) - 🔴 CRITICAL

**Features:**
- GPS-based automatic location detection
- Real-time compass using magnetometer sensor
- Visual compass with Qibla direction indicator
- Distance to Kaaba (km/m)
- Precise degree display (0-360°)
- Alignment notification when pointing to Qibla

**Technical:**
- Uses magnetometer + accelerometer for accurate heading
- Haversine formula for distance calculation
- Real-time sensor updates (50ms interval)
- Soft pastel compass design

**UI:**
- Rotating compass rose with N/E/S/W
- Animated Qibla indicator arrow
- Color feedback (green when aligned)
- Location info card with distance
- Info panel with direction, angle, distance

### 6. Additional Features

**Settings:**
- Notification preferences
- Location settings (auto/manual)
- Language (Turkish primary)
- Theme preferences (light mode only for v1)
- About/Help section

**Onboarding:**
- Welcome screen
- Location permission request
- Notification permission request

---

## 🔌 API Specifications

### Aladhan API

```bash
GET https://api.aladhan.com/v1/timings/{date}
Query params:
  - latitude: float
  - longitude: float
  - method: int (3 = Turkey)
```

### Quran.com API

```bash
GET https://api.quran.com/api/v4/chapters
GET https://api.quran.com/api/v4/verses/{chapter_id}
GET https://api.quran.com/api/v4/verses/by_chapter/{chapter_id}
```

---

## 📱 Screen Flow

```
Splash → Onboarding (first launch) → Home
                                   ↓
Home ──────────────────────────────────
  │    │       │       │       │
  ↓    ↓       ↓       ↓       ↓
Namaz  Zikir   Dualar  Kur'an  Ayarlar
Times
```

### Home Screen Layout

1. **Header:** Hijri date, city name
2. **Prayer Times Card:** Next prayer highlight + countdown
3. **Quick Actions:** Zikirmatik, Günlük Dua shortcut
4. **Quran Verse of the Day:** Featured verse card
5. **Bottom Navigation:** 5 tabs

---

## 🚀 Development Phases

### Phase 1: MVP (Current)
- [x] Prayer times with GPS
- [x] Basic zikrmatik
- [x] Daily prayers collection
- [x] Core UI with soft pastel theme

### Phase 2: Enhancement
- [ ] Quran integration
- [ ] Notification system
- [ ] Widget implementation

### Phase 3: Polish
- [ ] App Store optimization
- [ ] Performance optimization
- [ ] A/B testing setup

---

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.4.9
  dio: ^5.4.0
  geolocator: ^10.1.0
  shared_preferences: ^2.2.2
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  flutter_local_notifications: ^16.3.0
  home_widget: ^0.4.1
  google_fonts: ^6.1.0
  intl: ^0.18.1
  just_audio: ^0.9.36
  permission_handler: ^11.2.0
```

---

## 🎯 Success Metrics

- Prayer times accuracy: 99%+
- App launch time: < 2 seconds
- Offline capability: Basic features work offline
- Widget reliability: Update every 15 minutes
- Accessibility: Support for screen readers

---

## 📝 Notes

- All Turkish text uses Amiri font for Arabic, Noto Sans for Turkish
- Soft haptic feedback on all interactions
- Dark mode NOT included in v1 (future consideration)
- No analytics in v1 (privacy first)
- GDPR compliant data handling
