// lib/widgets/final_compact_card_enhanced.dart

import 'package:flutter/material.dart';
import 'package:manufacturing_dashboard/models/andoin_models.dart';
import 'package:manufacturing_dashboard/models/settings_model.dart';

class FinalCompactCard extends StatefulWidget {
  final String lineName;
  final AllData? data;
  final bool isFetching;
  final AppSettings settings;
  final bool isStale;

  const FinalCompactCard({
    Key? key,
    required this.lineName,
    required this.data,
    required this.isFetching,
    required this.settings,
    this.isStale = false,
  }) : super(key: key);

  @override
  State<FinalCompactCard> createState() => _FinalCompactCardState();
}

class _FinalCompactCardState extends State<FinalCompactCard>
    with TickerProviderStateMixin {
  AnimationController? _pulseController;
  AnimationController? _scaleController;
  AnimationController? _warningController;
  AnimationController? _glowController;
  AnimationController? _statusPulseController;
  AnimationController? _progressAnimationController;
  AnimationController? _fetchingGlowController;

  // Marquee animation controllers
  AnimationController? _statusMarqueeController;
  AnimationController? _commentMarqueeController;

  Animation<double>? _pulseAnimation;
  Animation<double>? _scaleAnimation;
  Animation<double>? _warningAnimation;
  Animation<double>? _glowAnimation;
  Animation<double>? _statusPulseAnimation;
  Animation<double>? _progressAnimation;
  Animation<double>? _fetchingGlowAnimation;

  // Marquee animations
  Animation<double>? _statusMarqueeAnimation;
  Animation<double>? _commentMarqueeAnimation;

  double _previousPercentage = 0.0;
  int _previousTarget = 0;
  int _previousActual = 0;
  bool _animationsInitialized = false;

  double _getResponsiveSize(double baseSize) {
    final scale = widget.settings.cardScale;
    return baseSize * scale;
  }

  double _getResponsiveFontSize(double baseFontSize) {
    final scale = widget.settings.cardScale;
    final cardsPerRow = widget.settings.cardsPerRow;
    if (cardsPerRow == 5) {
      if (baseFontSize >= 40) {
        return baseFontSize * 0.85;
      } else if (baseFontSize >= 18) {
        return baseFontSize * 0.9;
      } else if (baseFontSize >= 14) {
        return baseFontSize * 0.95;
      } else {
        return baseFontSize;
      }
    }
    if (scale >= 2.5) {
      return baseFontSize * scale * 1.5;
    } else if (scale >= 2.0) {
      return baseFontSize * scale * 1.3;
    } else if (scale >= 1.5) {
      return baseFontSize * scale * 1.2;
    } else if (scale >= 1.0) {
      return baseFontSize * scale * 1.1;
    } else if (scale >= 0.8) {
      return baseFontSize * scale * 1.4;
    } else {
      return baseFontSize * 0.9;
    }
  }

  double _getResponsivePadding(double basePadding) {
    final scale = widget.settings.cardScale;
    final cardsPerRow = widget.settings.cardsPerRow;
    if (cardsPerRow == 5) {
      return basePadding * 0.6;
    }
    if (scale >= 2) {
      return basePadding * scale * 1.5;
    } else if (scale >= 2.0) {
      return basePadding * scale * 1.3;
    } else if (scale >= 1.5) {
      return basePadding * scale * 1.2;
    } else if (scale >= 0.8) {
      return basePadding * scale * 1.1;
    }
    return basePadding * scale;
  }

  double _getResponsiveSpacing(double baseSpacing) {
    final scale = widget.settings.cardScale;
    final cardsPerRow = widget.settings.cardsPerRow;
    if (cardsPerRow == 5) {
      return baseSpacing * 0.5;
    }
    if (scale >= 2.5) {
      return baseSpacing * scale * 1.5;
    } else if (scale >= 2.0) {
      return baseSpacing * scale * 1.3;
    } else if (scale >= 1.5) {
      return baseSpacing * scale * 1.2;
    } else if (scale >= 0.8) {
      return baseSpacing * scale * 1.1;
    }
    return baseSpacing * scale;
  }

  @override
  void initState() {
    super.initState();

    _pulseController =
        AnimationController(duration: const Duration(seconds: 2), vsync: this);
    _scaleController = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);
    _warningController = AnimationController(
        duration: const Duration(milliseconds: 1000), vsync: this);
    _glowController =
        AnimationController(duration: const Duration(seconds: 2), vsync: this);
    _statusPulseController = AnimationController(
        duration: const Duration(milliseconds: 1500), vsync: this);
    _progressAnimationController = AnimationController(
        duration: const Duration(milliseconds: 1200), vsync: this);
    _fetchingGlowController = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this);

    // Initialize marquee controllers - slower to reduce performance impact
    _statusMarqueeController =
        AnimationController(duration: const Duration(seconds: 12), vsync: this);
    _commentMarqueeController =
        AnimationController(duration: const Duration(seconds: 15), vsync: this);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
        CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut));
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _scaleController!, curve: Curves.elasticOut));
    _warningAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _warningController!, curve: Curves.bounceOut));
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _glowController!, curve: Curves.easeInOut));
    _statusPulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
        CurvedAnimation(
            parent: _statusPulseController!, curve: Curves.easeInOut));
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _progressAnimationController!, curve: Curves.easeOutCubic));
    _fetchingGlowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _fetchingGlowController!, curve: Curves.easeInOut));

    // Setup marquee animations
    _statusMarqueeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _statusMarqueeController!, curve: Curves.linear));
    _commentMarqueeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _commentMarqueeController!, curve: Curves.linear));

    _scaleController!.forward();
    _pulseController!.repeat(reverse: true);
    _glowController!.repeat(reverse: true);
    _statusPulseController!.repeat(reverse: true);
    _progressAnimationController!.forward();

    if (widget.isStale) {
      _warningController!.repeat(reverse: true);
    }
    if (widget.isFetching) {
      _fetchingGlowController!.repeat(reverse: true);
    }

    // Start marquee animations after a delay to avoid initial load issues
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _statusMarqueeController?.repeat();
        _commentMarqueeController?.repeat();
      }
    });

    _animationsInitialized = true;
  }

  @override
  void didUpdateWidget(FinalCompactCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isStale && !oldWidget.isStale) {
      _warningController?.repeat(reverse: true);
    } else if (!widget.isStale && oldWidget.isStale) {
      _warningController?.stop();
    }

    if (widget.isFetching && !oldWidget.isFetching) {
      _fetchingGlowController?.repeat(reverse: true);
    } else if (!widget.isFetching && oldWidget.isFetching) {
      _fetchingGlowController?.stop();
      _fetchingGlowController?.animateTo(0.0,
          duration: const Duration(milliseconds: 400));
    }

    if (widget.data != null && oldWidget.data != null) {
      final newPercentage = widget.data!.hrXhrData.target > 0
          ? (widget.data!.hrXhrData.totalProduction /
              widget.data!.hrXhrData.target *
              100)
          : 0.0;
      final oldPercentage = oldWidget.data!.hrXhrData.target > 0
          ? (oldWidget.data!.hrXhrData.totalProduction /
              oldWidget.data!.hrXhrData.target *
              100)
          : 0.0;
      if (newPercentage != oldPercentage) {
        _previousPercentage = oldPercentage;
        _progressAnimationController?.reset();
        _progressAnimationController?.forward();
      }
      _previousTarget = oldWidget.data?.hrXhrData.target ?? 0;
      _previousActual = oldWidget.data?.hrXhrData.totalProduction ?? 0;
    }
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    _scaleController?.dispose();
    _warningController?.dispose();
    _glowController?.dispose();
    _statusPulseController?.dispose();
    _progressAnimationController?.dispose();
    _fetchingGlowController?.dispose();
    _statusMarqueeController?.dispose();
    _commentMarqueeController?.dispose();
    super.dispose();
  }

  Map<String, int> _getCurrentShiftDetails() {
    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final shifts = {
      'Shift 1': {
        'start': 15,
        'end': 435,
        'intervals': [45, 60, 60, 60, 60, 60, 60, 15]
      },
      'Shift 2': {
        'start': 435,
        'end': 945,
        'intervals': [45, 60, 60, 60, 60, 60, 60, 60, 45]
      },
      'Shift 3': {
        'start': 945,
        'end': 1455,
        'intervals': [15, 60, 60, 60, 60, 60, 60, 60, 60, 15]
      },
    };
    String currentShiftName = 'Shift 1';
    if (nowMinutes >= (shifts['Shift 2']!['start'] as int) &&
        nowMinutes < (shifts['Shift 2']!['end'] as int)) {
      currentShiftName = 'Shift 2';
    } else if (nowMinutes >= (shifts['Shift 3']!['start'] as int) ||
        nowMinutes < (shifts['Shift 1']!['end'] as int)) {
      currentShiftName = 'Shift 3';
    } else {
      currentShiftName = 'Shift 1';
    }
    int shiftStartMinutes = shifts[currentShiftName]!['start'] as int;
    List<int> intervals =
        (shifts[currentShiftName]!['intervals'] as List<dynamic>).cast<int>();
    final int totalHours = intervals.length;
    int elapsedMinutes = nowMinutes - shiftStartMinutes;
    if (elapsedMinutes < 0) {
      elapsedMinutes += 1440;
    }
    int currentIntervalIndex = -1;
    int cumulativeMinutes = 0;
    for (int i = 0; i < intervals.length; i++) {
      cumulativeMinutes += intervals[i];
      if (elapsedMinutes < cumulativeMinutes) {
        currentIntervalIndex = i;
        break;
      }
    }
    int currentShiftHour =
        (currentIntervalIndex == -1) ? totalHours : currentIntervalIndex + 1;
    return {'currentHour': currentShiftHour, 'totalHours': totalHours};
  }

  bool _isProductionComplete(HourlyProduction hourData) {
    if (hourData.status == 'not-started' || hourData.target <= 0) {
      return false;
    }
    double achievement = (hourData.production / hourData.target * 100);
    return achievement >= 100.0;
  }

  // Simplified Marquee text builder for better performance
// Replace the _buildMarqueeText method with this corrected version

Widget _buildMarqueeText(String text, Animation<double>? animation,
    TextStyle style, double maxWidth) {
  // Always return simple text if animation not ready
  if (animation == null || text.isEmpty) {
    return Text(
      text,
      style: style,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }

  return LayoutBuilder(
    builder: (context, constraints) {
      final availableWidth = constraints.maxWidth;

      // Return simple text for invalid constraints
      if (availableWidth.isInfinite || availableWidth <= 0) {
        return Text(
          text,
          style: style,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        );
      }

      // Better text width calculation using TextPainter
      final textPainter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();

      final textWidth = textPainter.width;

      // If text fits, no marquee needed
      if (textWidth <= availableWidth) {
        return Text(
          text,
          style: style,
          overflow: TextOverflow.clip,
          maxLines: 1,
        );
      }

      // Calculate proper spacing between repeated text
      final spacing = availableWidth * 0.5;

      // Marquee implementation with ClipRect to prevent overflow
      return ClipRect(
        child: SizedBox(
          width: availableWidth,
          height: textPainter.height,
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              // Calculate offset to animate smoothly
              final totalDistance = textWidth + spacing;
              final offset = -totalDistance * animation.value;
              
              return Transform.translate(
                offset: Offset(offset, 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // First instance of text
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: textWidth),
                      child: Text(
                        text,
                        style: style,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.clip,
                      ),
                    ),
                    SizedBox(width: spacing),
                    // Second instance of text for seamless loop
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: textWidth),
                      child: Text(
                        text,
                        style: style,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.clip,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    if (!_animationsInitialized ||
        _scaleAnimation == null ||
        _fetchingGlowAnimation == null) {
      return _buildLoadingCard();
    }

    final hasNoData = widget.data != null &&
        widget.data!.hrXhrData.target == 0 &&
        widget.data!.hrXhrData.totalProduction == 0;
    final cardOpacity = hasNoData ? 0.4 : 1.0;

    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation!, _fetchingGlowAnimation!]),
      builder: (context, child) {
        final glowValue = _fetchingGlowAnimation!.value;
        return Transform.scale(
          scale: _scaleAnimation!.value,
          child: AnimatedOpacity(
            opacity: cardOpacity,
            duration: const Duration(milliseconds: 300),
            child: Container(
              decoration: BoxDecoration(
                color: widget.settings.darkMode
                    ? const Color(0xFF2E4057)
                    : Colors.white,
                borderRadius: BorderRadius.circular(_getResponsiveSize(12)),
                border: Border.all(
                  color: Colors.blue.withOpacity(glowValue),
                  width: _getResponsiveSize(2.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: _getResponsiveSize(8),
                    offset: Offset(0, _getResponsiveSize(2)),
                  ),
                  if (glowValue > 0)
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.6 * glowValue),
                      blurRadius: 6 + (10 * glowValue),
                      spreadRadius: 1 + (2 * glowValue),
                    ),
                ],
              ),
              child: child,
            ),
          ),
        );
      },
      child: Stack(
        children: [
          if (widget.data == null)
            _buildLoadingCard()
          else
            _buildDataCard(_getCurrentShiftDetails()['currentHour']!,
                _getCurrentShiftDetails()['totalHours']!),
          if (widget.isStale &&
              widget.settings.showStaleDataWarning &&
              widget.data != null &&
              _warningAnimation != null)
            AnimatedBuilder(
              animation: _warningAnimation!,
              builder: (context, child) {
                return Positioned(
                  top: _getResponsiveSize(8),
                  right: _getResponsiveSize(8),
                  child: Transform.scale(
                    scale: 0.8 + (_warningAnimation!.value * 0.4),
                    child: Container(
                      padding: EdgeInsets.all(_getResponsiveSize(4)),
                      decoration: const BoxDecoration(
                          color: Colors.orange, shape: BoxShape.circle),
                      child: Icon(Icons.warning,
                          color: Colors.white, size: _getResponsiveSize(12)),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Center(
        child: Padding(
            padding: EdgeInsets.all(_getResponsivePadding(16.0)),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              SizedBox(
                  width: _getResponsiveSize(24),
                  height: _getResponsiveSize(24),
                  child: CircularProgressIndicator(
                      strokeWidth: _getResponsiveSize(2.0),
                      color: widget.settings.darkMode ? Colors.white70 : null)),
              SizedBox(height: _getResponsiveSpacing(10)),
              Text(widget.lineName,
                  style: TextStyle(
                      fontSize: _getResponsiveFontSize(18),
                      fontWeight: FontWeight.bold,
                      color: widget.settings.darkMode
                          ? Colors.white
                          : Colors.black87)),
            ])));
  }

  Widget _buildDataCard(int currentShiftHour, int totalShiftHours) {
    final andonStatus = widget.data!.andonStatus;
    final productionData = widget.data!.hrXhrData;
    final lineOverview = widget.data!.lineOverview;
    Color statusColor = _getStatusColor(andonStatus.status);
    final percentage = productionData.target > 0
        ? (productionData.totalProduction / productionData.target * 100)
        : 0.0;
    String timeAgoString = '';
    try {
      if (andonStatus.initial != null && andonStatus.initial.isNotEmpty) {
        final stopTime = DateTime.parse(andonStatus.initial);
        final duration = DateTime.now().difference(stopTime);
        timeAgoString = _formatDuration(duration);
      }
    } catch (e) {
      debugPrint("Error parsing andonStatus.initial: $e");
      timeAgoString = 'Invalid Time';
    }
    return Padding(
        padding: EdgeInsets.all(_getResponsivePadding(12.0)),
        child: LayoutBuilder(builder: (context, constraints) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                          child: Text(widget.lineName,
                              style: TextStyle(
                                  fontSize: _getResponsiveFontSize(20),
                                  fontWeight: FontWeight.bold,
                                  color: widget.settings.darkMode
                                      ? Colors.white
                                      : Colors.black87),
                              overflow: TextOverflow.ellipsis)),
                      Flexible(
                          child: (_statusPulseAnimation != null &&
                                  _glowAnimation != null &&
                                  _statusMarqueeAnimation != null)
                              ? AnimatedBuilder(
                                  animation: Listenable.merge([
                                    _statusPulseAnimation!,
                                    _glowAnimation!
                                  ]),
                                  builder: (context, child) {
                                    return Transform.scale(
                                        scale: _statusPulseAnimation!.value,
                                        child: Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal:
                                                    _getResponsivePadding(8),
                                                vertical:
                                                    _getResponsivePadding(3)),
                                            decoration: BoxDecoration(
                                                color: statusColor
                                                    .withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        _getResponsiveSize(20)),
                                                border: Border.all(
                                                    color: statusColor,
                                                    width: _getResponsiveSize(
                                                        1.5)),
                                                boxShadow: [
                                                  BoxShadow(
                                                      color: statusColor
                                                          .withOpacity(
                                                              _glowAnimation!
                                                                      .value *
                                                                  0.6),
                                                      blurRadius:
                                                          _getResponsiveSize(
                                                              12),
                                                      spreadRadius:
                                                          _getResponsiveSize(2))
                                                ]),
                                            child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                      _getStatusIcon(
                                                          andonStatus.status),
                                                      color: statusColor,
                                                      size: _getResponsiveSize(
                                                          18)),
                                                  SizedBox(
                                                      width:
                                                          _getResponsiveSpacing(
                                                              3)),
                                                  Flexible(
                                                      child: ConstrainedBox(
                                                          constraints: BoxConstraints(
                                                              maxWidth: 200),
                                                          child: _buildMarqueeText(
                                                              "${andonStatus.status.toUpperCase()} --  $timeAgoString",
                                                              _statusMarqueeAnimation,
                                                              TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize:
                                                                      _getResponsiveFontSize(
                                                                          18)),
                                                              200.0))),
                                                ])));
                                  })
                              : Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: _getResponsivePadding(8),
                                      vertical: _getResponsivePadding(3)),
                                  decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(
                                          _getResponsiveSize(20)),
                                      border: Border.all(
                                          color: statusColor,
                                          width: _getResponsiveSize(1.5))),
                                  child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(_getStatusIcon(andonStatus.status),
                                            color: statusColor,
                                            size: _getResponsiveSize(18)),
                                        SizedBox(
                                            width: _getResponsiveSpacing(3)),
                                        Flexible(
                                            child: ConstrainedBox(
                                                constraints: BoxConstraints(
                                                    maxWidth: 200),
                                                child: Text(
                                                    "${andonStatus.status.toUpperCase()} --  $timeAgoString",
                                                    style: TextStyle(
                                                        color: statusColor,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize:
                                                            _getResponsiveFontSize(
                                                                18)),
                                                    overflow: TextOverflow
                                                        .ellipsis))),
                                      ]))),
                    ]),
                SizedBox(height: _getResponsiveSpacing(8)),
                IntrinsicHeight(
                    child: Row(children: [
                  _buildMetricItem('Target', productionData.target.toString(),
                      Colors.white, Icons.flag),
                  SizedBox(width: _getResponsiveSpacing(8)),
                  _buildMetricItem(
                      'Actual',
                      productionData.totalProduction.toString(),
                      _getProductionColor(percentage),
                      Icons.check_circle),
                ])),
                SizedBox(height: _getResponsiveSpacing(3)),
                AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: EdgeInsets.symmetric(
                        horizontal: _getResponsivePadding(10),
                        vertical: _getResponsivePadding(6)),
                    decoration: BoxDecoration(
                        color: widget.settings.darkMode
                            ? Colors.white10
                            : Colors.black.withOpacity(0.05),
                        borderRadius:
                            BorderRadius.circular(_getResponsiveSize(6))),
                    child: Row(children: [
                      Expanded(
                          child: _buildMarqueeText(
                              andonStatus.status != 'Running'
                                  ? 'Reason:${andonStatus.comments}'
                                  : 'Product: ${lineOverview.modelTypeDesc}',
                              _commentMarqueeAnimation,
                              TextStyle(
                                  color: widget.settings.darkMode
                                      ? Colors.white
                                      : Colors.black87,
                                  fontSize: _getResponsiveFontSize(18)),
                              400.0)),
                      if (andonStatus.status == 'Running') ...[
                        SizedBox(width: _getResponsiveSpacing(6)),
                        Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: _getResponsivePadding(6),
                                vertical: _getResponsivePadding(2)),
                            decoration: BoxDecoration(
                                color: widget.settings.darkMode
                                    ? Colors.white10
                                    : Colors.black.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(
                                    _getResponsiveSize(3))),
                            child: Text(lineOverview.modelType,
                                style: TextStyle(
                                    color: widget.settings.darkMode
                                        ? Colors.white
                                        : Colors.black87,
                                    fontSize: _getResponsiveFontSize(16),
                                    fontWeight: FontWeight.bold)))
                      ],
                    ])),
                SizedBox(height: _getResponsiveSpacing(8)),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Rate',
                            style: TextStyle(
                                color: widget.settings.darkMode
                                    ? Colors.white70
                                    : Colors.black54,
                                fontSize: _getResponsiveFontSize(14),
                                fontWeight: FontWeight.w500)),
                        (_progressAnimation != null)
                            ? AnimatedBuilder(
                                animation: _progressAnimation!,
                                builder: (context, child) {
                                  final animatedPercentage =
                                      _previousPercentage +
                                          (percentage - _previousPercentage) *
                                              _progressAnimation!.value;
                                  return Text(
                                      '${animatedPercentage.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                          color: _getProductionColor(
                                              animatedPercentage),
                                          fontWeight: FontWeight.bold,
                                          fontSize: _getResponsiveFontSize(20),
                                          shadows: [
                                            Shadow(
                                                color: _getProductionColor(
                                                        animatedPercentage)
                                                    .withOpacity(0.5),
                                                blurRadius: 8)
                                          ]));
                                })
                            : Text('${percentage.toStringAsFixed(1)}%',
                                style: TextStyle(
                                    color: _getProductionColor(percentage),
                                    fontWeight: FontWeight.bold,
                                    fontSize: _getResponsiveFontSize(20))),
                      ]),
                  SizedBox(height: _getResponsiveSpacing(3)),
                  ClipRRect(
                      borderRadius:
                          BorderRadius.circular(_getResponsiveSize(4)),
                      child: (_progressAnimation != null &&
                              _glowAnimation != null)
                          ? AnimatedBuilder(
                              animation: _progressAnimation!,
                              builder: (context, child) {
                                final animatedValue = (_previousPercentage /
                                        100) +
                                    ((percentage - _previousPercentage) / 100) *
                                        _progressAnimation!.value;
                                return Stack(children: [
                                  LinearProgressIndicator(
                                      value: animatedValue,
                                      backgroundColor: widget.settings.darkMode
                                          ? Colors.white12
                                          : Colors.grey[200],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          _getProductionColor(
                                              animatedValue * 100)),
                                      minHeight: _getResponsiveSize(8)),
                                  Positioned.fill(
                                      child: AnimatedBuilder(
                                          animation: _glowAnimation!,
                                          builder: (context, child) {
                                            return Container(
                                                decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                        begin: Alignment
                                                            .centerLeft,
                                                        end: Alignment
                                                            .centerRight,
                                                        colors: [
                                                          Colors.transparent,
                                                          Colors.white.withOpacity(
                                                              _glowAnimation!
                                                                      .value *
                                                                  0.3),
                                                          Colors.transparent
                                                        ],
                                                        stops: [
                                                          0.0,
                                                          animatedValue,
                                                          animatedValue + 0.1
                                                        ]
                                                            .map((e) => e.clamp(
                                                                0.0, 1.0))
                                                            .toList())));
                                          })),
                                ]);
                              })
                          : LinearProgressIndicator(
                              value: percentage / 100,
                              backgroundColor: widget.settings.darkMode
                                  ? Colors.white12
                                  : Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  _getProductionColor(percentage)),
                              minHeight: _getResponsiveSize(8))),
                ]),
                SizedBox(height: _getResponsiveSpacing(8)),
                Text('Shift Hours',
                    style: TextStyle(
                        color: widget.settings.darkMode
                            ? Colors.white70
                            : Colors.black54,
                        fontSize: _getResponsiveFontSize(12),
                        fontWeight: FontWeight.w500)),
                SizedBox(height: _getResponsiveSpacing(4)),
                Expanded(
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(totalShiftHours, (index) {
                          final hour = index + 1;
                          final isCurrentHour = hour == currentShiftHour;
                          final hourData = productionData.hourlyData.firstWhere(
                              (h) => h.hour == hour,
                              orElse: () => HourlyProduction(
                                  hour: hour,
                                  production: 0,
                                  target: 0,
                                  status: 'not-started'));
                          return _buildHourIndicator(
                              hour, hourData, isCurrentHour);
                        }))),
              ]);
        }));
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return 'just now';
    }
  }

  Widget _buildMetricItem(
      String label, String value, Color color, IconData icon) {
    final cardsPerRow = widget.settings.cardsPerRow;
    double verticalPadding = cardsPerRow == 5 ? 8.0 : _getResponsivePadding(16);
    double horizontalPadding =
        cardsPerRow == 5 ? 6.0 : _getResponsivePadding(12);
    double labelFontSize = cardsPerRow == 5 ? 12.0 : _getResponsiveFontSize(16);
    double valueFontSize = cardsPerRow == 5 ? 28.0 : _getResponsiveFontSize(40);
    double spacing = cardsPerRow == 5 ? 4.0 : _getResponsiveSpacing(8);
    double borderRadius = cardsPerRow == 5 ? 6.0 : _getResponsiveSize(8);
    return Expanded(
        child: (_progressAnimation != null)
            ? AnimatedBuilder(
                animation: _progressAnimation!,
                builder: (context, child) {
                  int targetValue = int.tryParse(value) ?? 0;
                  int animatedValue = targetValue;
                  if (label == "Target" && _previousTarget > 0) {
                    animatedValue = (_previousTarget +
                            (targetValue - _previousTarget) *
                                _progressAnimation!.value)
                        .round();
                  } else if (label == "Actual" && _previousActual >= 0) {
                    animatedValue = (_previousActual +
                            (targetValue - _previousActual) *
                                _progressAnimation!.value)
                        .round();
                  }
                  return AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      padding: EdgeInsets.symmetric(
                          vertical: verticalPadding,
                          horizontal: horizontalPadding),
                      decoration: BoxDecoration(
                          color: label == "Target"
                              ? Colors.teal.withOpacity(0.2)
                              : color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(borderRadius),
                          border: Border.all(
                              color: color.withOpacity(0.3),
                              width: cardsPerRow == 5
                                  ? 0.8
                                  : _getResponsiveSize(1)),
                          boxShadow: [
                            BoxShadow(
                                color: color.withOpacity(0.2),
                                blurRadius: _getResponsiveSize(8),
                                spreadRadius: -2)
                          ]),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text("$label(nos)",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: labelFontSize,
                                    fontWeight: FontWeight.w500))),
                        SizedBox(height: spacing),
                        FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(animatedValue.toString(),
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: valueFontSize))),
                      ]));
                })
            : AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                padding: EdgeInsets.symmetric(
                    vertical: verticalPadding, horizontal: horizontalPadding),
                decoration: BoxDecoration(
                    color: label == "Target"
                        ? Colors.teal.withOpacity(0.2)
                        : color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(borderRadius),
                    border: Border.all(
                        color: color.withOpacity(0.3),
                        width: cardsPerRow == 5 ? 0.8 : _getResponsiveSize(1)),
                    boxShadow: [
                      BoxShadow(
                          color: color.withOpacity(0.2),
                          blurRadius: _getResponsiveSize(8),
                          spreadRadius: -2)
                    ]),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text("$label(nos)",
                          style: TextStyle(
                              color: widget.settings.darkMode
                                  ? Colors.white
                                  : Colors.black54,
                              fontSize: labelFontSize,
                              fontWeight: FontWeight.w500))),
                  SizedBox(height: spacing),
                  FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(value,
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: valueFontSize))),
                ])));
  }

  Widget _buildHourIndicator(
      int hour, HourlyProduction hourData, bool isCurrentHour) {
    Color indicatorColor;
    Widget centerWidget;
    bool isComplete = _isProductionComplete(hourData);
    if (hourData.status == 'not-started') {
      indicatorColor = Colors.grey;
    } else if (hourData.production == 0) {
      indicatorColor = Colors.red;
    } else {
      double achievement = hourData.target > 0
          ? (hourData.production / hourData.target * 100)
          : 100;
      if (achievement >= 90) {
        indicatorColor = Colors.green;
      } else if (achievement >= 70) {
        indicatorColor = Colors.orange;
      } else {
        indicatorColor = Colors.red;
      }
    }
    if (widget.settings.showProductionNumbers) {
      if (hourData.status == 'not-started') {
        centerWidget = Text(hour.toString(),
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: _getResponsiveFontSize(10)));
      } else if (hourData.production == 0) {
        centerWidget =
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(hour.toString(),
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: _getResponsiveFontSize(8),
                  height: 0.9)),
          Icon(Icons.close, color: Colors.white, size: _getResponsiveSize(12))
        ]);
      } else if (isComplete) {
        centerWidget =
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(hour.toString(),
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: _getResponsiveFontSize(8),
                  height: 0.9)),
          Icon(Icons.check,
              color: const Color.fromARGB(255, 19, 18, 18),
              size: _getResponsiveSize(20),
              weight: 800)
        ]);
      } else {
        centerWidget =
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(hour.toString(),
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: _getResponsiveFontSize(8),
                  height: 0.9)),
          Text(hourData.production.toString(),
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: _getResponsiveFontSize(10),
                  height: 1.0))
        ]);
      }
    } else {
      double achievement = hourData.target > 0
          ? (hourData.production / hourData.target * 100)
          : 100;
      if (hourData.status == 'not-started') {
        centerWidget = Text(hour.toString(),
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: _getResponsiveFontSize(10)));
      } else if (hourData.production == 0) {
        centerWidget =
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(hour.toString(),
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: _getResponsiveFontSize(8),
                  height: 0.9)),
          Icon(Icons.close, color: Colors.white, size: _getResponsiveSize(12))
        ]);
      } else if (isComplete) {
        centerWidget =
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(hour.toString(),
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: _getResponsiveFontSize(8),
                  height: 0.9)),
          Icon(Icons.check,
              color: const Color.fromARGB(255, 247, 246, 246),
              size: _getResponsiveSize(30),
              weight: 800)
        ]);
      } else {
        centerWidget =
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(hour.toString(),
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: _getResponsiveFontSize(8),
                  height: 0.9)),
          Text('${achievement.round()}%',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: _getResponsiveFontSize(16),
                  height: 1.0))
        ]);
      }
    }
    final indicatorContent = isCurrentHour
        ? ((_pulseAnimation != null && _glowAnimation != null)
            ? AnimatedBuilder(
                animation:
                    Listenable.merge([_pulseAnimation!, _glowAnimation!]),
                builder: (context, child) {
                  return Transform.scale(
                      scale: _pulseAnimation!.value,
                      child: Container(
                          decoration: BoxDecoration(
                              color: indicatorColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.blue,
                                  width: _getResponsiveSize(3)),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.blue.withOpacity(
                                        0.6 * _glowAnimation!.value),
                                    blurRadius: _getResponsiveSize(12),
                                    spreadRadius: _getResponsiveSize(4)),
                                BoxShadow(
                                    color: indicatorColor.withOpacity(0.4),
                                    blurRadius: _getResponsiveSize(4),
                                    offset: Offset(0, _getResponsiveSize(2)))
                              ]),
                          child: Center(
                              child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: centerWidget))));
                })
            : Container(
                decoration: BoxDecoration(
                    color: indicatorColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.blue, width: _getResponsiveSize(3))),
                child: Center(
                    child:
                        FittedBox(fit: BoxFit.scaleDown, child: centerWidget))))
        : TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 200 + (hour * 50)),
            tween: Tween<double>(begin: 0.0, end: 1.0),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(
                  scale: value,
                  child: (_glowAnimation != null)
                      ? AnimatedBuilder(
                          animation: _glowAnimation!,
                          builder: (context, child) {
                            final glowOpacity =
                                isComplete ? _glowAnimation!.value * 0.3 : 0.2;
                            return Container(
                                decoration: BoxDecoration(
                                    color: indicatorColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                          color: indicatorColor
                                              .withOpacity(glowOpacity),
                                          blurRadius: _getResponsiveSize(8),
                                          spreadRadius: _getResponsiveSize(1))
                                    ]),
                                child: Center(
                                    child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: centerWidget)));
                          })
                      : Container(
                          decoration: BoxDecoration(
                              color: indicatorColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color: indicatorColor.withOpacity(0.2),
                                    blurRadius: _getResponsiveSize(4),
                                    offset: Offset(0, _getResponsiveSize(2)))
                              ]),
                          child: Center(
                              child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: centerWidget))));
            });
    return Flexible(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
      Flexible(child: AspectRatio(aspectRatio: 1, child: indicatorContent)),
      if (isCurrentHour) SizedBox(height: _getResponsiveSpacing(2)),
      if (isCurrentHour)
        (_statusPulseAnimation != null)
            ? AnimatedBuilder(
                animation: _statusPulseAnimation!,
                builder: (context, child) {
                  return Transform.scale(
                      scale: _statusPulseAnimation!.value,
                      child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: _getResponsivePadding(4),
                              vertical: _getResponsivePadding(1)),
                          decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius:
                                  BorderRadius.circular(_getResponsiveSize(8)),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.blue.withOpacity(0.5),
                                    blurRadius: _getResponsiveSize(6),
                                    spreadRadius: _getResponsiveSize(1))
                              ]),
                          child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Now',
                                  style: TextStyle(
                                      fontSize: _getResponsiveFontSize(8),
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)))));
                })
            : Container(
                padding: EdgeInsets.symmetric(
                    horizontal: _getResponsivePadding(4),
                    vertical: _getResponsivePadding(1)),
                decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(_getResponsiveSize(8))),
                child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Now',
                        style: TextStyle(
                            fontSize: _getResponsiveFontSize(8),
                            color: Colors.white,
                            fontWeight: FontWeight.bold)))),
    ]));
  }

  IconData _getStatusIcon(String status) {
    final statusLower = status.toLowerCase();
    if (statusLower.contains('running')) return Icons.play_arrow;
    if (statusLower.contains('maintenance')) return Icons.stop;
    if (statusLower.contains('break') || statusLower.contains('others'))
      return Icons.pause;
    return Icons.info;
  }

  Color _getStatusColor(String status) {
    final statusLower = status.toLowerCase();
    if (statusLower.contains('running')) {
      return Colors.green;
    } else if (statusLower.contains('line feeding delay') ||
        statusLower.contains('maintenance')) {
      return Colors.red;
    } else if (statusLower.contains('break') ||
        statusLower.contains('lunch') ||
        statusLower.contains('others')) {
      return Colors.grey;
    }
    return Colors.orange;
  }

  Color _getProductionColor(double percentage) {
    if (percentage >= 100) return Colors.green;
    if (percentage >= 90) return const Color(0xFF4CAF50);
    if (percentage >= 80) return Colors.teal;
    if (percentage >= 70) return Colors.orange;
    return Colors.red;
  }
}
