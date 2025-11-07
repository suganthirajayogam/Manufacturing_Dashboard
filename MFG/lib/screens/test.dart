//  // 1. Add ScrollController and Scroll Timer (EXISTING, CORRECT)
//   import 'package:manufacturing_dashboard/services/api_service.dart';

// final ScrollController _scrollController = ScrollController();
//   Timer? _scrollTimer;
 
//   final FinalApiService _apiService = FinalApiService();
//   final SettingsService _settingsService = SettingsService.instance;
 
//   AppSettings _settings = AppSettings();
//   final Map<String, AllData?> _lineData = {};
//   final Map<String, DateTime> _lastFetchTime = {};
//   int _currentLineIndex = 0;
//   bool _isLoadingSettings = true;
 
//   // --- Configuration Constants for Scroll Logic ---
//   // These should match your GridView's mainAxisSpacing and childAspectRatio
//   static const double _gridMainAxisSpacing = 5.0;
//   static const double _gridChildAspectRatio = 1.3;
//   // Estimated height of the largest card for accurate scrolling (based on aspect ratio)
//   double get _cardHeight {
//     // Check if context is available and settings loaded
//     if (!mounted || _isLoadingSettings) return 0.0;
 
//     // Calculate card width based on screen size and crossAxisCount
//     final screenWidth = MediaQuery.of(context).size.width;
//     // Assuming 5.0 horizontal padding on the outer Row, and 5.0 crossAxisSpacing
//     // Total horizontal padding is 5.0 * 2 for the outer Padding.
//     // Let's refine the available width calculation based on the build method's structure.
//     // The GridView is inside an Expanded widget, so its width is calculated dynamically.
//     // Assuming 5.0 crossAxisSpacing between cards.
//     final padding = 5.0 * 2; // Outer Padding: 5.0 on left/right
//     final crossAxisSpacing = (_settings.cardsPerRow - 1) * 5.0;
   
//     // The width of the GridView itself is (screenWidth * fraction) - padding.
//     // Since we don't have the exact width of the Expanded widget here,
//     // we use a simplified approach based on the `crossAxisCount` and spacing defined
//     // in the GridView.builder in the `build` method.
//     // Let's assume the screen size calculation is approximately correct for the card width
//     // within its Expanded container.
   
//     // For simplicity, let's just re-use the available width calculation logic from your original plan:
//     final availableWidth = screenWidth - padding - crossAxisSpacing;
//     final cardWidth = availableWidth / _settings.cardsPerRow;
   
//     // Height is width / aspect ratio
//     return cardWidth / _gridChildAspectRatio;
//   }
 
 
//   @override
//   void initState() {
//     super.initState();
//     _initializeApp();
//   }
 
//   Future<void> _initializeApp() async {
//     // Load settings first
//     await _loadSettings();
 
//     // Initialize clock
//     _updateTimeAndShift();
//     _clockTimer = Timer.periodic(
//         const Duration(seconds: 1), (Timer t) => _updateTimeAndShift());
 
//     // Initialize data for all lines
//     for (var line in _settings.productionLines) {
//       _lineData[line] = null;
//     }
 
//     // Start sequential data fetching
//     _startSequentialFetch();
   
//     // 2. Start Auto-Scrolling if enabled (EXISTING, CORRECT)
//     _startAutoScroll();
//   }
 
//   Future<void> _loadSettings() async {
//     final settings = await _settingsService.loadSettings();
//     setState(() {
//       _settings = settings;
//       _isLoadingSettings = false;
//     });
//   }
 
//   @override
//   void dispose() {
//     _clockTimer.cancel();
//     _dataFetchTimer?.cancel();
//     _scrollTimer?.cancel(); // 3. Cancel the scroll timer (EXISTING, CORRECT)
//     _scrollController.dispose();
//     super.dispose();
//   }
 
//   // New: Logic to start/stop the auto-scrolling timer (EXISTING, CORRECT)
//   void _startAutoScroll() {
//     _scrollTimer?.cancel();
 
//     // Only start if enabled AND there are more lines than fit on one row (i.e., multiple rows)
//     if (_settings.autoScroll && _settings.productionLines.length > _settings.cardsPerRow) {
//       // Use the interval from settings, defaulting to 20 seconds if it's somehow <= 0
//       final interval = _settings.scrollIntervalSeconds > 0
//           ? _settings.scrollIntervalSeconds
//           : 20;
 
//       _scrollTimer = Timer.periodic(
//         Duration(seconds: interval),
//         (timer) {
//           _performScroll();
//         },
//       );
//     }
//   }
 
//   // New: Logic to perform the scroll action
//   void _performScroll() {
//     // Ensure the controller is attached and we're not still loading settings
//     if (!_scrollController.hasClients || _isLoadingSettings) return;
 
//     final maxScroll = _scrollController.position.maxScrollExtent;
//     final currentScroll = _scrollController.offset;
   
//     // Calculate the scroll distance as one row's height + mainAxisSpacing
//     // This ensures exactly one row is scrolled out of view.
//     final scrollDistance = _cardHeight + _gridMainAxisSpacing;
 
//     double newScrollOffset = currentScroll + scrollDistance;
 
//     // --- CORRECTED LOGIC START ---
//     if (newScrollOffset >= maxScroll) {
//       // If the current scroll is already at the max extent (meaning we displayed the last cards)
//       if (currentScroll >= maxScroll) {
//         // Jump back to the start (0.0) for a seamless loop
//         _scrollController.animateTo(
//           0.0,
//           duration: const Duration(milliseconds: 500),
//           curve: Curves.easeOut,
//         );
//       } else {
//         // If the calculated next scroll is beyond maxScroll, but we're not at maxScroll yet,
//         // animate to the exact maxScroll to show the last cards fully.
//         _scrollController.animateTo(
//           maxScroll,
//           duration: const Duration(milliseconds: 1000),
//           curve: Curves.easeInOut,
//         );
//       }
//     } else {
//       // Normal scroll to the next row
//       _scrollController.animateTo(
//         newScrollOffset,
//         duration: const Duration(milliseconds: 1000),
//         curve: Curves.easeInOut,
//       );
//     }
//     // --- CORRECTED LOGIC END ---
//   }
