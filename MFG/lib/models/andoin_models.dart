// lib/models/updated_andon_models.dart

class AndonStatus {
  final String status;
  final String initial;
  final String? finalTime;
  final String comments;

  AndonStatus({
    required this.status,
    required this.initial,
    this.finalTime,
    required this.comments,
  });

  factory AndonStatus.fromJson(Map<String, dynamic> json) {
    return AndonStatus(
      status: json['status'] ?? 'N/A',
      initial: json['initial'] ?? '',
      finalTime: json['final'],
      comments: json['comments'] ?? '',
    );
  }
}

class HourlyProduction {
  final int hour;
  final int production;
  final int target;
  final String status; // 'on-track', 'behind', 'ahead', 'not-started'

  HourlyProduction({
    required this.hour,
    required this.production,
    required this.target,
    required this.status,
  });
}

class HrXHrData {
  final int totalProduction;
  final int target;
  final List<HourlyProduction> hourlyData;

  HrXHrData({
    required this.totalProduction,
    required this.target,
    required this.hourlyData,
  });

  factory HrXHrData.fromJson(Map<String, dynamic> json) {
    // Parse hourly data from the API response
    List<HourlyProduction> hourlyList = [];
    
    // The API typically returns hour1, hour2, etc. fields
    for (int i = 1; i <= 8; i++) {
      final hourKey = 'hour$i';
      final targetKey = 'objective$i';
      
      if (json.containsKey(hourKey)) {
        final production = json[hourKey] ?? 0;
        final hourTarget = json[targetKey] ?? 0;
        
        String status = 'not-started';
        if (production > 0) {
          if (production >= hourTarget) {
            status = 'on-track';
          } else if (production >= hourTarget * 0.9) {
            status = 'behind';
          } else {
            status = 'critical';
          }
        }
        
        hourlyList.add(HourlyProduction(
          hour: i,
          production: production is int ? production : int.tryParse(production.toString()) ?? 0,
          target: hourTarget is int ? hourTarget : int.tryParse(hourTarget.toString()) ?? 0,
          status: status,
        ));
      }
    }
    
    return HrXHrData(
      totalProduction: json['totalProduction'] ?? 0,
      target: json['objective2'] ?? json['totalObjective'] ?? 0,
      hourlyData: hourlyList,
    );
  }
}

class LineOverview {
  final String lineDesc;
  final String modelType;
  final String modelTypeDesc;
  final String modelFamily;
  final String fttDay;
  final String fttHour;

  LineOverview({
    required this.lineDesc,
    required this.modelType,
    required this.modelTypeDesc,
    required this.modelFamily,
    required this.fttDay,
    required this.fttHour,
  });

  factory LineOverview.fromJson(Map<String, dynamic> json) {
    return LineOverview(
      lineDesc: json['LineDesc'] ?? 'N/A',
      modelType: json['ModelType'] ?? 'N/A',
      modelTypeDesc: json['ModelTypeDesc'] ?? 'N/A',
      modelFamily: json['ModelFamily'] ?? 'N/A',
      fttDay: json['FTT_Day'] ?? '0',
      fttHour: json['FTT_Hour'] ?? '0',
    );
  }
}

class AllData {
  final AndonStatus andonStatus;
  final HrXHrData hrXhrData;
  final LineOverview lineOverview;

  AllData({
    required this.andonStatus,
    required this.hrXhrData,
    required this.lineOverview,
  });
}

class ProductionCardData {
  final AndonStatus andonStatus;
  final HrXHrData hrXhrData;
  final LineOverview lineOverview;

  ProductionCardData({
    required this.andonStatus,
    required this.hrXhrData,
    required this.lineOverview,
  });
}