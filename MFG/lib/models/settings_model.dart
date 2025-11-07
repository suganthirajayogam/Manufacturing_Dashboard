// lib/models/settings_model.dart
 
import 'dart:convert';
 
class AppSettings {
  // Production lines configuration
  List<String> productionLines;
 
  // Display preferences
  bool showProductionNumbers; // true: show numbers, false: show percentage
  int cardsPerRow; // Number of cards per row in grid
  int 
  
  fetchIntervalSeconds; // Interval between fetching each line
  bool showStaleDataWarning; // Show warning icon for stale data
  int dataExpiryMinutes; // Minutes before data is considered stale
 
  // Visual preferences
  bool darkMode;
  bool showCommunicationsPanel;
  double cardScale; // Scale factor for card size
 
  // New auto-scrolling preferences
  bool autoScroll;
  int scrollIntervalSeconds;
 
  AppSettings({
    List<String>? productionLines,
    this.showProductionNumbers = true,
    this.cardsPerRow = 3,
    this.fetchIntervalSeconds = 20,
    this.showStaleDataWarning = true,
    this.dataExpiryMinutes = 15,
    this.darkMode = false,
    this.showCommunicationsPanel = true,
    double? cardScale,
    this.autoScroll = false,
    this.scrollIntervalSeconds = 15,
  }) : productionLines = productionLines ?? _defaultLines,
        cardScale = cardScale ?? _calculateCardScale(cardsPerRow ?? 3);
 
  static final List<String> _defaultLines = [
    'SMT-L01', 'SMT-L02', 'SMT-L03', 'SMT-L04', 'SMT-L05', 'SMT-L06',
    'FA-1', 'FA-2', 'FA-3', 'FA-4', 'FA-5', 'FA-6', 'FA-7', 'FA-8', 'FA-9'
  ];
 
  // Calculate card scale based on cards per row
 // Calculate card scale based on cards per row
// Calculate card scale based on cards per row
static double _calculateCardScale(int cardsPerRow) {
  switch (cardsPerRow) {
    case 1:
      return 0.95; // Very large for single card
    case 2:
      return 0.95; // Large for two cards
    case 3:
      return 0.8; // Medium for three cards
    case 4:
      return 0.7; // Slightly smaller for four cards
    case 5:
      return 0.7; // Much smaller for five cards to prevent overflow
// Smaller for six cards
    default:
      return 0.5; // Very small for more than 6 cards
  }
}
 
  // Get the calculated card scale based on current cardsPerRow
  double get dynamicCardScale => _calculateCardScale(cardsPerRow);
 
  // Method to update cards per row and automatically adjust scale
  AppSettings updateCardsPerRow(int newCardsPerRow) {
    return copyWith(
      cardsPerRow: newCardsPerRow,
      cardScale: _calculateCardScale(newCardsPerRow),
    );
  }
 
  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'productionLines': productionLines,
      'showProductionNumbers': showProductionNumbers,
      'cardsPerRow': cardsPerRow,
      'fetchIntervalSeconds': fetchIntervalSeconds,
      'showStaleDataWarning': showStaleDataWarning,
      'dataExpiryMinutes': dataExpiryMinutes,
      'darkMode': darkMode,
      'showCommunicationsPanel': showCommunicationsPanel,
      'cardScale': cardScale,
      'autoScroll': autoScroll,
      'scrollIntervalSeconds': scrollIntervalSeconds,
    };
  }
 
  // Create from JSON
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final cardsPerRow = json['cardsPerRow'] ?? 3;
    return AppSettings(
      productionLines: List<String>.from(json['productionLines'] ?? _defaultLines),
      showProductionNumbers: json['showProductionNumbers'] ?? true,
      cardsPerRow: cardsPerRow,
      fetchIntervalSeconds: json['fetchIntervalSeconds'] ?? 20,
      showStaleDataWarning: json['showStaleDataWarning'] ?? true,
      dataExpiryMinutes: json['dataExpiryMinutes'] ?? 15,
      darkMode: json['darkMode'] ?? false,
      showCommunicationsPanel: json['showCommunicationsPanel'] ?? true,
      cardScale: json['cardScale']?.toDouble() ?? _calculateCardScale(cardsPerRow),
      autoScroll: json['autoScroll'] ?? false,
      scrollIntervalSeconds: json['scrollIntervalSeconds'] ?? 20,
    );
  }
 
  // Create a copy with modifications
  AppSettings copyWith({
    List<String>? productionLines,
    bool? showProductionNumbers,
    int? cardsPerRow,
    int? fetchIntervalSeconds,
    bool? showStaleDataWarning,
    int? dataExpiryMinutes,
    bool? darkMode,
    bool? showCommunicationsPanel,
    double? cardScale,
    bool? autoScroll,
    int? scrollIntervalSeconds,
  }) {
    final newCardsPerRow = cardsPerRow ?? this.cardsPerRow;
    return AppSettings(
      productionLines: productionLines ?? this.productionLines,
      showProductionNumbers: showProductionNumbers ?? this.showProductionNumbers,
      cardsPerRow: newCardsPerRow,
      fetchIntervalSeconds: fetchIntervalSeconds ?? this.fetchIntervalSeconds,
      showStaleDataWarning: showStaleDataWarning ?? this.showStaleDataWarning,
      dataExpiryMinutes: dataExpiryMinutes ?? this.dataExpiryMinutes,
      darkMode: darkMode ?? this.darkMode,
      showCommunicationsPanel: showCommunicationsPanel ?? this.showCommunicationsPanel,
      cardScale: cardScale ?? _calculateCardScale(newCardsPerRow),
      autoScroll: autoScroll ?? this.autoScroll,
      scrollIntervalSeconds: scrollIntervalSeconds ?? this.scrollIntervalSeconds,
    );
  }
 
  // Encode to string for SharedPreferences
  String encode() => json.encode(toJson());
 
  // Decode from string
  factory AppSettings.decode(String str) {
    return AppSettings.fromJson(json.decode(str));
  }
}
 