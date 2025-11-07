# 🏭 Manufacturing Dashboard

A real-time production monitoring dashboard built with Flutter for manufacturing plants. Track production lines, monitor shift performance, and manage andon status in a beautiful, responsive interface.

## ✨ Features

- 📊 **Real-time Production Monitoring** - Live updates of production metrics
- 🔄 **Multi-Line Support** - Monitor multiple production lines simultaneously
- ⏰ **Shift Management** - Configurable shift timings and hourly tracking
- 🎯 **Andon Status** - Real-time line status and alerts
- 📈 **Performance Metrics** - Track targets, actuals, and efficiency rates
- 🌙 **Dark Mode** - Easy on the eyes during night shifts
- 🔧 **Configurable API** - Admin panel for API and shift configuration
- 🎨 **Responsive Design** - Works on desktop, tablet, and mobile
- 🔄 **Auto-scroll** - Automatic cycling through production lines
- 📱 **Communications Panel** - Important announcements and alerts


### Prerequisites

- Flutter SDK (3.0 or higher)
- Dart SDK
- IDE (VS Code, Android Studio, or IntelliJ)


### API Configuration

1. Launch the app
2. Navigate to **Settings → API Configuration**
3. Enter your API credentials:
   - API Username
   - API Password
   - API URLs (Andon, HrXHr, Termite)
4. Save configuration

### Shift Timings

Configure shifts in the admin panel:
- Shift start/end times
- Hourly intervals
- Break periods

### Production Lines

Add/remove production lines from the settings panel.

## 📦 Project Structure

```
lib/
├── models/
│   ├── admin_config_model.dart      # API & shift configuration
│   ├── andoin_models.dart           # Production data models
│   └── settings_model.dart          # App settings
├── services/
│   ├── admin_config_service.dart    # Config management
│   ├── final_api_service.dart       # API calls
│   └── settings_services.dart       # Settings persistence
├── screens/
│   ├── settings_aware_dashboard.dart # Main dashboard
│   ├── settings_screens.dart         # Settings UI
│   └── simple_admin_screen.dart      # Admin panel
├── widgets/
│   ├── final_compact_card_enhanced.dart # Production card
│   └── production_line_card.dart        # Line widget
└── main.dart
```

## 🔧 Key Technologies

- **Flutter** - Cross-platform UI framework
- **SharedPreferences** - Local data persistence
- **HTTP** - API communication
- **Intl** - Date formatting
- **Provider/State Management** - App state

## 📊 API Endpoints

The dashboard connects to three main APIs:

1. **Andon Status API** - Line status and comments
2. **HrXHr API** - Hourly production data
3. **Termite API** - Line overview and model info

## 🎨 Features in Detail

### Dashboard View
- Grid layout with configurable cards per row
- Real-time production metrics
- Color-coded performance indicators
- Shift hour tracking with visual progress
- Auto-scroll for large line counts

### Production Cards
- Line name and current status
- Target vs Actual production
- Hourly breakdown with visual indicators
- Model/product information
- Performance percentage

### Status Indicators
- 🟢 Green: ≥90% performance
- 🟠 Orange: 70-90% performance
- 🔴 Red: <70% performance or zero production
- ⚪ Gray: Not started

### Settings Panel
- Production line management
- Display preferences
- Data refresh intervals
- Auto-scroll configuration
- Dark mode toggle

## 🔐 Security

- API credentials stored locally (not in source code)
- Password-protected admin configuration
- No credentials in Git repository

