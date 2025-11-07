// lib/screens/settings_aware_dashboard.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Import for listEquals
import 'package:intl/intl.dart';
import 'package:manufacturing_dashboard/models/andoin_models.dart';

import 'package:manufacturing_dashboard/models/settings_model.dart';
import 'package:manufacturing_dashboard/screens/settings_screens.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

import 'dart:async';

import 'package:manufacturing_dashboard/services/api_service.dart';
import 'package:manufacturing_dashboard/services/settings_services.dart';
import 'package:manufacturing_dashboard/widgets/horizonatal_metrics_card.dart';
import 'package:manufacturing_dashboard/widgets/production_line_card.dart';

class SettingsAwareDashboard extends StatefulWidget {
  const SettingsAwareDashboard({Key? key}) : super(key: key);

  @override
  _SettingsAwareDashboardState createState() => _SettingsAwareDashboardState();
}

class _SettingsAwareDashboardState extends State<SettingsAwareDashboard>
    with TickerProviderStateMixin {
  String _currentDateTime = '';
  String _currentShift = '';
  late Timer _clockTimer;
  Timer? _dataFetchTimer;

  late AutoScrollController _autoScrollController;

  late AnimationController _scrollIndicatorController;
  late Animation<double> _scrollIndicatorAnimation;

  // Animation controller for pulsing glow effect
  late AnimationController _pulseAnimationController;
  late Animation<double> _pulseAnimation;

  bool _isAutoScrolling = false;

  // Track fetch state - this is the key to making the indicator work continuously
  int? _fetchingLineIndex;

  final FinalApiService _apiService = FinalApiService();
  final SettingsService _settingsService = SettingsService.instance;

  AppSettings _settings = AppSettings();
  final Map<String, AllData?> _lineData = {};
  final Map<String, DateTime> _lastFetchTime = {};
  int _currentLineIndex = 0;
  bool _isLoadingSettings = true;

  bool _initialFetchComplete = false;

  @override
  void initState() {
    super.initState();
    _autoScrollController = AutoScrollController();
    _initializeAnimations();
    _initializeApp();
  }

  void _initializeAnimations() {
    _scrollIndicatorController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _scrollIndicatorAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _scrollIndicatorController, curve: Curves.easeInOut));

    // Initialize pulse animation for the glow effect
    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  Future<void> _initializeApp() async {
    await _loadSettings();
    _updateTimeAndShift();
    _clockTimer = Timer.periodic(
        const Duration(seconds: 1), (Timer t) => _updateTimeAndShift());
    for (var line in _settings.productionLines) {
      _lineData[line] = null;
    }
    _startSequentialFetch();
  }

  Future<void> _loadSettings() async {
    final settings = await _settingsService.loadSettings();
    setState(() {
      _settings = settings;
      _isLoadingSettings = false;
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _dataFetchTimer?.cancel();
    _autoScrollController.dispose();
    _scrollIndicatorController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    // Check if auto-scroll is enabled in settings before starting
    if (!_settings.autoScroll) {
      print("Auto-scroll is disabled in settings. Not starting scroll.");
      return;
    }

    if (_isAutoScrolling) return;

    if (_settings.autoScroll &&
        _settings.productionLines.length > _settings.cardsPerRow) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_autoScrollController.hasClients) {
          _autoScrollController.jumpTo(0);
        }
        _isAutoScrolling = true;
        _scrollIndicatorController.repeat(reverse: true);
        _performContinuousScroll();
      });
    }
  }

  void _stopAutoScroll() {
    if (_isAutoScrolling) {
      _isAutoScrolling = false;
      _scrollIndicatorController.stop();
      _scrollIndicatorController.reset();
      print("Auto-scroll animation stopped.");
    }
  }

Future<void> _performContinuousScroll() async {
  while (_isAutoScrolling && mounted && _settings.autoScroll) {
    // IMPORTANT: Jump to beginning
    if (_autoScrollController.hasClients) {
      _autoScrollController.jumpTo(0.0);
    }

    // MODIFIED: Add 10 second delay at the beginning of EACH cycle
    print("Waiting 10 seconds before starting scroll from beginning...");
    await Future.delayed(const Duration(seconds: 5));
    
    if (!_isAutoScrolling || !mounted || !_settings.autoScroll) {
      print("Auto-scroll cancelled during delay.");
      break;
    }

    if (!_autoScrollController.hasClients || _isLoadingSettings) {
      await Future.delayed(const Duration(milliseconds: 1000));
      continue;
    }

    final maxScroll = _autoScrollController.position.maxScrollExtent;
    if (maxScroll < 10) {
      await Future.delayed(const Duration(seconds: 5));
      continue;
    }

    print("Starting scroll animation now...");
    final scrollDuration = Duration(seconds: _settings.scrollIntervalSeconds);

    try {
      await _autoScrollController.animateTo(
        maxScroll,
        duration: scrollDuration,
        curve: Curves.linear,
      );
    } catch (e) {
      print('Scroll animation error: $e');
      continue;
    }

    if (!_isAutoScrolling || !mounted || !_settings.autoScroll) break;
    
    // Optional: Add delay at the end (after reaching bottom) before jumping back
    print("Scroll completed. Waiting 10 seconds at bottom before restarting...");
    await Future.delayed(const Duration(seconds: 5));
    if (!_isAutoScrolling || !mounted || !_settings.autoScroll) break;
  }

  // If we exit the loop because auto-scroll was disabled, ensure animation is stopped
  if (!_settings.autoScroll && _isAutoScrolling) {
    _stopAutoScroll();
  }
}

  void _updateTimeAndShift() {
    final now = DateTime.now();
    String shift;
    final timeOfDay = TimeOfDay.fromDateTime(now);
    final currentHour = timeOfDay.hour + timeOfDay.minute / 60.0;

    if (currentHour >= 0.25 && currentHour < 7.25) {
      shift = 'Shift 1';
    } else if (currentHour >= 7.25 && currentHour < 15.75) {
      shift = 'Shift 2';
    } else {
      shift = 'Shift 3';
    }
    final formatter = DateFormat('EEEE, MMMM dd, yyyy');
    final timeFormatter = DateFormat('hh:mm:ss a');
    final formattedDate = formatter.format(now);
    final formattedTime = timeFormatter.format(now);

    if (mounted) {
      setState(() {
        _currentDateTime = '$formattedDate at $formattedTime';
        _currentShift = shift;
      });
    }
  }

  void _startSequentialFetch() {
    _dataFetchTimer?.cancel();
    if (_settings.productionLines.isEmpty) return;

    _currentLineIndex = 0;
    _fetchingLineIndex = null;
    _fetchNextLine();

    _dataFetchTimer = Timer.periodic(
      Duration(seconds: _settings.fetchIntervalSeconds),
      (timer) {
        _fetchNextLine();
      },
    );
  }

  // FIXED: This method now properly handles the pulsing animation and status for ALL cards
  Future<void> _fetchNextLine() async {
    // Prevent overlapping fetches
    if (_fetchingLineIndex != null || _settings.productionLines.isEmpty) {
      return;
    }

    // Cycle back to start if needed
    if (_currentLineIndex >= _settings.productionLines.length) {
      _currentLineIndex = 0;
      print('=== Completed one full cycle of all lines ===');

      if (!_initialFetchComplete) {
        _initialFetchComplete = true;
        print('✅ Initial data fetch complete. Switching to continuous scroll.');
        // Only start auto-scroll if it's enabled in settings
        if (_settings.autoScroll) {
          _startAutoScroll();
        }
      }
    }

    final int indexToFetch = _currentLineIndex;
    final lineName = _settings.productionLines[indexToFetch];

    // IMPORTANT: Set the fetching state and START the pulse animation
    if (mounted) {
      setState(() {
        _fetchingLineIndex = indexToFetch;
      });

      // Start the pulsing animation for the glow effect
      _pulseAnimationController.repeat(reverse: true);

      // Only scroll to card during initial fetch phase
      if (!_initialFetchComplete &&
          _autoScrollController.hasClients &&
          _settings.autoScroll) {
        _autoScrollController.scrollToIndex(
          indexToFetch,
          preferPosition: AutoScrollPosition.end,
          duration: const Duration(milliseconds: 800),
        );
      }
    }

    final date = DateFormat('yyyy-M-d').format(DateTime.now());
    final shift = _currentShift.contains('1')
        ? '1'
        : _currentShift.contains('2')
            ? '2'
            : '3';

    print(
        '[...] Fetching line: $lineName (Card ${indexToFetch + 1}/${_settings.productionLines.length})');

    try {
      // Perform the actual data fetching
      final allData = await _apiService.fetchAllData(
          lineName: lineName, date: date, shift: shift);
      if (mounted) {
        setState(() {
          _lineData[lineName] = allData;
          _lastFetchTime[lineName] = DateTime.now();
        });
      }
    } catch (e) {
      print('✗ Error fetching data for line $lineName: $e');
    } finally {
      // IMPORTANT: Stop the animation and clear the fetching state
      if (mounted) {
        _pulseAnimationController.stop();
        _pulseAnimationController.reset();
        setState(() {
          _fetchingLineIndex = null;
        });
      }
      // Move to next line
      _currentLineIndex++;
    }
  }

  bool _isDataStale(String lineName) {
    if (!_settings.showStaleDataWarning) return false;
    if (!_lastFetchTime.containsKey(lineName)) return true;
    final timeSinceFetch = DateTime.now().difference(_lastFetchTime[lineName]!);
    return timeSinceFetch.inMinutes > _settings.dataExpiryMinutes;
  }

  Color _getShiftButtonColor() {
    if (_currentShift.contains('1')) return Colors.blue;
    if (_currentShift.contains('2')) return Colors.green;
    return Colors.orange;
  }

  Future<void> _navigateToSettings() async {
    _dataFetchTimer?.cancel();
    _fetchingLineIndex = null;

    final originalLines = List<String>.from(_settings.productionLines);
    final originalAutoScroll = _settings.autoScroll;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );

    final newSettings = await _settingsService.loadSettings();
    final bool linesHaveChanged =
        !listEquals(originalLines, newSettings.productionLines);
    final bool autoScrollChanged = originalAutoScroll != newSettings.autoScroll;

    // Stop auto-scroll if it was turned off in settings
    if (!newSettings.autoScroll && _isAutoScrolling) {
      print("Auto-scroll disabled in settings. Stopping scroll animation...");
      _stopAutoScroll();
    }

    if (linesHaveChanged) {
      print("Production lines have changed. Resetting dashboard...");
      _stopAutoScroll();
      _initialFetchComplete = false;

      setState(() {
        _settings = newSettings;
        _lineData.removeWhere(
            (key, value) => !_settings.productionLines.contains(key));
        _lastFetchTime.removeWhere(
            (key, value) => !_settings.productionLines.contains(key));
        final newLines = _settings.productionLines
            .where((line) => !_lineData.containsKey(line))
            .toList();
        for (var line in newLines) {
          _lineData[line] = null;
        }
      });

      if (_autoScrollController.hasClients) {
        _autoScrollController.jumpTo(0);
      }

      _startSequentialFetch();
    } else {
      print("Settings updated. Applying changes without resetting scroll.");
      setState(() {
        _settings = newSettings;
      });

      // Handle auto-scroll changes
      if (autoScrollChanged) {
        if (newSettings.autoScroll && _initialFetchComplete) {
          print(
              "Auto-scroll enabled in settings. Starting scroll animation...");
          _startAutoScroll();
        } else if (!newSettings.autoScroll) {
          print("Auto-scroll disabled in settings.");
          _stopAutoScroll();
        }
      }

      _startSequentialFetch();
    }
  }

  Widget _buildScrollIndicator() {
    if (!_initialFetchComplete ||
        !_settings.autoScroll ||
        _settings.productionLines.length <= _settings.cardsPerRow) {
      return const SizedBox.shrink();
    }

    return Positioned(
      right: 20,
      top: MediaQuery.of(context).size.height * 0.4,
      child: AnimatedBuilder(
        animation: _scrollIndicatorAnimation,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue
                  .withOpacity(0.2 + (0.3 * _scrollIndicatorAnimation.value)),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue
                      .withOpacity(0.3 * _scrollIndicatorAnimation.value),
                  blurRadius: 10 + (10 * _scrollIndicatorAnimation.value),
                  spreadRadius: 2 * _scrollIndicatorAnimation.value,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.keyboard_arrow_up,
                    color: Colors.blue.withOpacity(
                        0.6 + (0.4 * _scrollIndicatorAnimation.value)),
                    size: 20),
                Container(
                  width: 2,
                  height: 30,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.blue.withOpacity(0.3),
                          Colors.blue.withOpacity(0.8)
                        ]),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                Icon(Icons.keyboard_arrow_down,
                    color: Colors.blue.withOpacity(
                        0.6 + (0.4 * _scrollIndicatorAnimation.value)),
                    size: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLegendItem(
      String label, Color color, String? text, bool showCross, bool showCheck) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Center(
            child: showCross
                ? const Icon(Icons.close, color: Colors.white, size: 12)
                : showCheck
                    ? const Icon(Icons.check, color: Colors.white, size: 12)
                    : text != null
                        ? Text(text,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold))
                        : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                color: _settings.darkMode ? Colors.white60 : Colors.black54,
                fontSize: 11)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingSettings) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final backgroundColor =
        _settings.darkMode ? const Color(0xFF1E1E2E) : const Color(0xFFF5F5F5);
    final cardBackgroundColor =
        _settings.darkMode ? const Color(0xFF2E4057) : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Row(
              children: [
                Expanded(
                  flex: _settings.showCommunicationsPanel ? 3 : 1,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 5.0),
                        decoration: BoxDecoration(
                            color: cardBackgroundColor,
                            borderRadius: BorderRadius.circular(12.0),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2))
                            ]),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(
                                  height: 40,
                                  child: Image.asset(
                                      'assets/images/visteon_logo.png',
                                      errorBuilder: (c, e, s) => const Text(
                                          'visteon',
                                          style: TextStyle(
                                              color: Color(0xFFFF8800),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20)))),
                              Expanded(
                                  child: Text(
                                      'VEI - Manufacturing Andon System',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: _settings.darkMode
                                              ? Colors.white
                                              : Colors.black87))),
                              Row(children: [
                                Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                        color: _getShiftButtonColor(),
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    child: Row(children: [
                                      const Icon(Icons.schedule,
                                          color: Colors.white, size: 16),
                                      const SizedBox(width: 6),
                                      Text(_currentShift,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold))
                                    ])),
                                const SizedBox(width: 16),
                                IconButton(
                                    icon: Icon(Icons.settings,
                                        color: _settings.darkMode
                                            ? Colors.white70
                                            : Colors.black54),
                                    onPressed: _navigateToSettings,
                                    tooltip: 'Settings'),
                              ]),
                            ]),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _settings.productionLines.isEmpty
                            ? Center(
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                    Icon(Icons.warning,
                                        size: 64,
                                        color: _settings.darkMode
                                            ? Colors.white54
                                            : Colors.black54),
                                    const SizedBox(height: 16),
                                    Text('No production lines configured',
                                        style: TextStyle(
                                            fontSize: 18,
                                            color: _settings.darkMode
                                                ? Colors.white70
                                                : Colors.black54)),
                                    const SizedBox(height: 8),
                                    ElevatedButton.icon(
                                        onPressed: _navigateToSettings,
                                        icon: const Icon(Icons.settings),
                                        label: const Text('Go to Settings')),
                                  ]))
                            : GridView.builder(
                                controller: _autoScrollController,
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: _settings.productionLines.length,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: _settings.cardsPerRow,
                                        childAspectRatio:
                                            _settings.cardsPerRow == 3
                                                ? 1.4
                                                : 1.2,
                                        crossAxisSpacing: 5.0,
                                        mainAxisSpacing: 5.0),
                                itemBuilder: (context, index) {
                                  final lineName =
                                      _settings.productionLines[index];
                                  final data = _lineData[lineName];
                                  final isStale = _isDataStale(lineName);
                                  final isFetching =
                                      _fetchingLineIndex == index;

                                  // FIXED: Wrap card with pulsing glow animation
                                  return AutoScrollTag(
                                    key: ValueKey(index),
                                    controller: _autoScrollController,
                                    index: index,
                                    child: AnimatedBuilder(
                                      animation: _pulseAnimation,
                                      builder: (context, child) {
                                        return Container(
                                          decoration: isFetching
                                              ? BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      // ignore: deprecated_member_use
                                                      color: Colors.blue
                                                          .withOpacity(0.3 +
                                                              (_pulseAnimation
                                                                      .value *
                                                                  0.4)),
                                                      blurRadius: 15 +
                                                          (_pulseAnimation
                                                                  .value *
                                                              15),
                                                      spreadRadius: 2 +
                                                          (_pulseAnimation
                                                                  .value *
                                                              3),
                                                    ),
                                                  ],
                                                )
                                              : null,
                                          child: FinalCompactCard(
                                            lineName: lineName,
                                            data: data,
                                            isFetching: isFetching,
                                            settings: _settings,
                                            isStale: isStale,
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
                      if (_settings.productionLines.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                              color: cardBackgroundColor.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: AnimatedOpacity(
                                  // FIXED: Show status message for ALL fetches
                                  opacity:
                                      _fetchingLineIndex != null ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 300),
                                  child: _fetchingLineIndex != null &&
                                          _fetchingLineIndex! <
                                              _settings.productionLines.length
                                      ? Row(
                                          children: [
                                            const SizedBox(
                                                width: 12,
                                                height: 12,
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.blue)),
                                            const SizedBox(width: 8),
                                            Text(
                                                'Updating: ${_settings.productionLines[_fetchingLineIndex!]} (${_fetchingLineIndex! + 1}/${_settings.productionLines.length})',
                                                style: const TextStyle(
                                                    color: Colors.blue,
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ],
                                        )
                                      : const SizedBox(),
                                ),
                              ),
                              Expanded(
                                flex: 5,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildLegendItem('Not Started', Colors.grey,
                                        '1', false, false),
                                    const SizedBox(width: 15),
                                    _buildLegendItem('Zero Production',
                                        Colors.red, null, true, false),
                                    const SizedBox(width: 15),
                                    _buildLegendItem('< 70%', Colors.red, '69%',
                                        false, false),
                                    const SizedBox(width: 15),
                                    _buildLegendItem('70-90%', Colors.orange,
                                        '85%', false, false),
                                    const SizedBox(width: 15),
                                    _buildLegendItem('≥ 90%', Colors.green,
                                        '95%', false, false),
                                    const SizedBox(width: 15),
                                    _buildLegendItem('100% Complete',
                                        Colors.green, null, false, true),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (_initialFetchComplete &&
                                        _settings.autoScroll &&
                                        _settings.productionLines.length >
                                            _settings.cardsPerRow)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.autorenew,
                                                  size: 12, color: Colors.blue),
                                              const SizedBox(width: 4),
                                              Text('Auto-scroll',
                                                  style: TextStyle(
                                                      color: Colors.blue,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w500)),
                                            ]),
                                      ),
                                    const SizedBox(width: 12),
                                    Text(_currentDateTime,
                                        style: TextStyle(
                                            color: _settings.darkMode
                                                ? Colors.white70
                                                : Colors.black54,
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                if (_settings.showCommunicationsPanel) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: BoxDecoration(
                          color: cardBackgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2))
                          ]),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Icon(Icons.announcement,
                                    color: _settings.darkMode
                                        ? Colors.white
                                        : Colors.black87,
                                    size: 20),
                                const SizedBox(width: 8),
                                Text('Communications',
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: _settings.darkMode
                                            ? Colors.white
                                            : Colors.black87)),
                              ]),
                              const SizedBox(height: 15),
                              Divider(
                                  color: _settings.darkMode
                                      ? Colors.white30
                                      : Colors.black26,
                                  thickness: 1),
                              const SizedBox(height: 10),
                              Expanded(
                                  child: ListView(children: [
                                _buildCommunicationItem(
                                    'System Update',
                                    'Maintenance scheduled for Line FA-3 at 2:00 PM',
                                    Icons.build,
                                    Colors.orange),
                                _buildCommunicationItem(
                                    'Quality Alert',
                                    'FTT improved by 5% on SMT-L02',
                                    Icons.trending_up,
                                    Colors.green),
                                _buildCommunicationItem(
                                    'Shift Change',
                                    'Shift 2 handover completed successfully',
                                    Icons.swap_horiz,
                                    Colors.blue),
                              ])),
                            ]),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          _buildScrollIndicator(),
        ],
      ),
    );
  }

  Widget _buildCommunicationItem(
      String title, String message, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _settings.darkMode
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.2), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 16)),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 2),
              Text(message,
                  style: TextStyle(
                      color:
                          _settings.darkMode ? Colors.white70 : Colors.black54,
                      fontSize: 11)),
            ]),
          ),
        ],
      ),
    );
  }
}
