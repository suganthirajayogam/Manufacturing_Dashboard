// lib/services/final_api_service.dart

import 'package:http/http.dart' as http;
import 'package:manufacturing_dashboard/models/andoin_models.dart';
import 'dart:convert';
import 'dart:io';

class FinalApiService {
  // Hardcoded API credentials for basic auth
  static const String _user = "API_ANDON_ANDONPLANT";
  static const String _password = "4nd0n.P@ssw0rd";
  static final String _auth = 'Basic ' + base64Encode(utf8.encode('$_user:$_password'));

  // API URLs
  static const String _andonApiUrl = 'https://veicim011.vistcorp.ad.visteon.com/andon/api/AndonStatus/';
  static const String _hrXhrApiUrl = 'https://veicim011.vistcorp.ad.visteon.com/andon/api/HrXHr/getHrXHr/';
  static const String _termiteApiUrl = 'http://10.218.199.159/termite/service.svc/LnOverview/';

  // Logging setup
  late File _logFile;
  bool _loggingInitialized = false;

  FinalApiService() {
    _initializeLogging();
  }

  Future<void> _initializeLogging() async {
    try {
      // Get the executable directory (where the app is running from)
      final exeDir = Directory.current;
      _logFile = File('${exeDir.path}/api_debug_log.txt');
      
      // Create log file if it doesn't exist
      if (!await _logFile.exists()) {
        await _logFile.create();
      }
      
      _loggingInitialized = true;
      await _logMessage('=== API Debug Log Initialized ===');
      //await _logSystemInfo();
    } catch (e) {
      print('Failed to initialize logging: $e');
      _loggingInitialized = false;
    }
  }

  Future<void> _logMessage(String message) async {
    if (!_loggingInitialized) return;
    
    try {
      final timestamp = DateTime.now().toString();
      final logEntry = '[$timestamp] $message\n';
      await _logFile.writeAsString(logEntry, mode: FileMode.append);
      print(logEntry.trim()); // Also print to console
    } catch (e) {
      print('Failed to write to log: $e');
    }
  }

  Future<void> _logSystemInfo() async {
    await _logMessage('--- SYSTEM INFORMATION ---');
    await _logMessage('Platform: ${Platform.operatingSystem}');
    await _logMessage('Platform Version: ${Platform.operatingSystemVersion}');
    await _logMessage('Dart Version: ${Platform.version}');
    await _logMessage('Number of Processors: ${Platform.numberOfProcessors}');
    await _logMessage('Executable: ${Platform.executable}');
    await _logMessage('Script: ${Platform.script}');
    
    // Check network interfaces
    try {
      final interfaces = await NetworkInterface.list();
      await _logMessage('Network Interfaces (${interfaces.length}):');
      for (final interface in interfaces) {
        await _logMessage('  - ${interface.name}: ${interface.addresses.map((a) => a.address).join(', ')}');
      }
    } catch (e) {
      await _logMessage('Failed to get network interfaces: $e');
    }

    // Check environment variables related to proxy/network
    //final networkEnvVars = ['HTTP_PROXY', 'HTTPS_PROXY', 'NO_PROXY', 'http_proxy', 'https_proxy', 'no_proxy'];
    //await _logMessage('Network Environment Variables:');
    // for (final envVar in networkEnvVars) {
    //   final value = Platform.environment[envVar];
    //   await _logMessage('  $envVar: ${value ?? 'not set'}');
    // }
    
    //await _logMessage('--- END SYSTEM INFORMATION ---\n');
  }

  

  // Create HttpClient with SSL verification disabled (equivalent to verify=False in Python)
  HttpClient _createHttpClient() {
    final client = HttpClient();
    client.badCertificateCallback = (X509Certificate cert, String host, int port) {
      // Log certificate details but accept all certificates
     // _logMessage('Accepting certificate for $host:$port - Subject: ${cert.subject}');
      return true; // Always accept certificates (verify=False equivalent)
    };
    return client;
  }

  Future<AllData> fetchAllData({
    required String lineName,
    required String date,
    required String shift,
  }) async {
    //await _logMessage('=== STARTING FETCH ALL DATA ===');
    //await _logMessage('Parameters: line=$lineName, date=$date, shift=$shift');
    //await _logMessage('SSL Certificate Verification: DISABLED (verify=false equivalent)');
    
    // Run network tests on first call
    // await _logNetworkTest();
    
    final stopwatch = Stopwatch()..start();
    
    try {
      final futures = await Future.wait([
        _getAndonStatus(lineName),
        _getProductionDataWithHourly(lineName, date, shift),
        _getLineOverview(lineName),
      ]);

      final AndonStatus andonStatus = futures[0] as AndonStatus;
      final HrXHrData hrXhrData = futures[1] as HrXHrData;
      final LineOverview lineOverview = futures[2] as LineOverview;

      stopwatch.stop();
      await _logMessage('✓ All API calls completed successfully in ${stopwatch.elapsedMilliseconds}ms');

      return AllData(
        andonStatus: andonStatus,
        hrXhrData: hrXhrData,
        lineOverview: lineOverview,
      );
    } catch (e) {
      stopwatch.stop();
      await _logMessage('✗ Error in fetchAllData after ${stopwatch.elapsedMilliseconds}ms: $e');
      rethrow;
    } finally {
      await _logMessage('=== END FETCH ALL DATA ===\n');
    }
  }

  Future<AndonStatus> _getAndonStatus(String lineName) async {
    final apiName = 'AndonStatus';
    final url = _andonApiUrl + lineName;
    await _logMessage('--- CALLING $apiName API ---');
    await _logMessage('URL: $url');
    
    final stopwatch = Stopwatch()..start();
    final client = _createHttpClient();
    
    try {
      //await _logMessage('Creating HTTP GET request with SSL verification disabled...');
      //await _logMessage('Headers: authorization=[BASIC_AUTH_HEADER]');
      
      final request = await client.getUrl(Uri.parse(url));
      request.headers.set('authorization', _auth);
      
      final httpResponse = await request.close().timeout(const Duration(seconds: 10));
      final responseBody = await httpResponse.transform(utf8.decoder).join();
      
      stopwatch.stop();
      //await _logMessage('Response received in ${stopwatch.elapsedMilliseconds}ms');
      //await _logMessage('Status Code: ${httpResponse.statusCode}');
     // await _logMessage('Response Headers: ${httpResponse.headers}');
      //await _logMessage('Response Body Length: ${responseBody.length} characters');
     // await _logMessage('Response Body Preview: ${responseBody.length > 200 ? responseBody.substring(0, 200) + "..." : responseBody}');
      
      if (httpResponse.statusCode == 200) {
        final data = jsonDecode(responseBody);
        //await _logMessage('JSON parsed successfully - Type: ${data.runtimeType}');
        
        if (data is List && data.isNotEmpty) {
          await _logMessage('✓ $apiName API successful - Found ${data.length} records');
          return AndonStatus.fromJson(data[0]);
        } else {
          await _logMessage('⚠ $apiName API returned empty or invalid data');
        }
      } else {
        await _logMessage('✗ $apiName API failed with status ${httpResponse.statusCode}');
      }
    } catch (e) {
      stopwatch.stop();
     // await _logMessage('✗ $apiName API error after ${stopwatch.elapsedMilliseconds}ms: $e');
     // await _logMessage('Error Type: ${e.runtimeType}');
      await _logMessage('Error Details: ${e.toString()}');
    } finally {
      client.close();
    }
    
    //await _logMessage('Returning default AndonStatus');
    return AndonStatus(status: 'N/A', initial: '', comments: '');
  }

Future<HrXHrData> _getProductionDataWithHourly(
    String lineName, String date, String shift) async {
  final apiName = 'HrXHr';
  final url = '$_hrXhrApiUrl$lineName/$date/$shift';
  final stopwatch = Stopwatch()..start();  // ❌ No logging here!

  final client = _createHttpClient();

  try {
    //await _logMessage('Creating HTTP GET request with SSL verification disabled...');
      
    final request = await client.getUrl(Uri.parse(url));
    request.headers.set('authorization', _auth);
      
    final httpResponse = await request.close().timeout(const Duration(seconds: 10));
    final responseBody = await httpResponse.transform(utf8.decoder).join();
      
    stopwatch.stop();
    //await _logMessage('Response received in ${stopwatch.elapsedMilliseconds}ms');
    //await _logMessage('Status Code: ${httpResponse.statusCode}');
    //await _logMessage('Response Headers: ${httpResponse.headers}');
    //await _logMessage('Response Body Length: ${responseBody.length} characters');
      
    if (httpResponse.statusCode == 200) {
      final data = jsonDecode(responseBody);
      //await _logMessage('JSON parsed successfully - Type: ${data.runtimeType}');
        
      if (data is List && data.isNotEmpty) {
        //await _logMessage('✓ $apiName API successful - Found ${data.length} hours of data');
          
        List<HourlyProduction> hourlyData = [];
        int totalProduction = 0;
        int totalTarget = 0;
          
        // Get current shift details to determine how many hours to process
        final shiftDetails = _getCurrentShiftDetails(shift);
        final currentShiftHour = shiftDetails['currentHour']!;
        final totalShiftHours = shiftDetails['totalHours']!;
          
        //await _logMessage('Shift Details: currentHour=$currentShiftHour, totalHours=$totalShiftHours');
          
        // Process the correct number of hours based on shift
        for (int shiftHour = 1; shiftHour <= totalShiftHours; shiftHour++) {
          int hourProduction = 0;
          int hourTarget = 0;
          String status = 'not-started';
            
          // Check if we have data for this shift hour
          if (shiftHour - 1 < data.length) {
            final hourData = data[shiftHour - 1];
              
            // await _logMessage('Processing Hour $shiftHour: ${hourData.toString()}');
              
            // Extract values
            hourProduction = _parseIntValue(hourData['hourProduction'] ?? 0);
            hourTarget = _parseIntValue(hourData['objective1'] ?? 0);
            final apiStatusPercent = _parseIntValue(hourData['status'] ?? 0);
              
            // Determine status based on API status percentage
            if (shiftHour <= currentShiftHour) {
              if (hourProduction > 0) {
                if (apiStatusPercent >= 90) {
                  status = 'on-track';
                } else if (apiStatusPercent >= 70) {
                  status = 'behind';
                } else {
                  status = 'critical';
                }
              } else {
                status = 'critical';
              }
            } else {
              status = 'not-started';
            }
          } else if (shiftHour <= currentShiftHour) {
            status = 'critical';
          }
            
          hourlyData.add(HourlyProduction(
            hour: shiftHour,
            production: hourProduction,
            target: hourTarget,
            status: status,
          ));
        }
          
        // Get totals from the last record
        if (data.isNotEmpty) {
          final lastRecord = data.last;
          totalProduction = _parseIntValue(lastRecord['totalProduction'] ?? 0);
          totalTarget = _parseIntValue(lastRecord['objective2'] ?? 0);
        }
          
        // await _logMessage('Final totals: Production=$totalProduction, Target=$totalTarget');
          
        return HrXHrData(
          totalProduction: totalProduction,
          target: totalTarget,
          hourlyData: hourlyData,
        );
      } else {
        await _logMessage('⚠ $apiName API returned empty or invalid data');
      }
    } else {
      await _logMessage('✗ $apiName API failed with status ${httpResponse.statusCode}');
    }
  } catch (e) {
    stopwatch.stop();
    await _logMessage('✗ $apiName API error after ${stopwatch.elapsedMilliseconds}ms: $e');
    // await _logMessage('Error Type: ${e.runtimeType}');
  } finally {
    client.close();
  }
    
  // Return empty data if fetch fails
  final shiftDetails = _getCurrentShiftDetails(shift);
  final totalShiftHours = shiftDetails['totalHours']!;
    
  //await _logMessage('Returning default HrXHrData with $totalShiftHours hours');
  return HrXHrData(
    totalProduction: 0,
    target: 0,
    hourlyData: List.generate(
      totalShiftHours,
      (index) => HourlyProduction(
        hour: index + 1,
        production: 0,
        target: 0,
        status: 'not-started',
      ),
    ),
  );
}

  Future<LineOverview> _getLineOverview(String lineName) async {
    final apiName = 'LineOverview';
    final url = '$_termiteApiUrl$lineName/SNG';
    //await _logMessage('--- CALLING $apiName API ---');
    //await _logMessage('URL: $url');
    
    final stopwatch = Stopwatch()..start();
    final client = _createHttpClient();
    
    try {
     // await _logMessage('Creating HTTP GET request with SSL verification disabled...');
      
      final request = await client.getUrl(Uri.parse(url));
      request.headers.set('authorization', _auth);
      
      final httpResponse = await request.close().timeout(const Duration(seconds: 10));
      final responseBody = await httpResponse.transform(utf8.decoder).join();
      
      stopwatch.stop();
      //await _logMessage('Response received in ${stopwatch.elapsedMilliseconds}ms');
      //await _logMessage('Status Code: ${httpResponse.statusCode}');
     // await _logMessage('Response Headers: ${httpResponse.headers}');
      //await _logMessage('Response Body Length: ${responseBody.length} characters');
     // await _logMessage('Response Body Preview: ${responseBody.length > 200 ? responseBody.substring(0, 200) + "..." : responseBody}');
      
      if (httpResponse.statusCode == 200) {
        final data = jsonDecode(responseBody);
        await _logMessage('JSON parsed successfully - Type: ${data.runtimeType}');
        
        if (data is List && data.isNotEmpty) {
          await _logMessage('✓ $apiName API successful - Found ${data.length} records');
          return LineOverview.fromJson(data[0]);
        } else {
          await _logMessage('⚠ $apiName API returned empty or invalid data');
        }
      } else {
        await _logMessage('✗ $apiName API failed with status ${httpResponse.statusCode}');
      }
    } catch (e) {
      stopwatch.stop();
      await _logMessage('✗ $apiName API error after ${stopwatch.elapsedMilliseconds}ms: $e');
      await _logMessage('Error Type: ${e.runtimeType}');
    } finally {
      client.close();
    }
    
    await _logMessage('Returning default LineOverview');
    return LineOverview(
      lineDesc: 'N/A',
      modelType: 'N/A',
      modelTypeDesc: 'N/A',
      modelFamily: 'N/A',
      fttDay: '0',
      fttHour: '0',
    );
  }

  int _parseIntValue(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // Match the exact shift calculation logic from your widget
  Map<String, int> _getCurrentShiftDetails(String shift) {
    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;

    // Define shifts with their exact intervals in minutes (matching widget)
    final shifts = {
      '1': {
        'start': 15, // 12:15 AM
        'end': 435, // 7:15 AM
        'intervals': [45, 60, 60, 60, 60, 60, 60, 15], // 8 hours
      },
      '2': {
        'start': 435, // 7:15 AM
        'end': 945, // 3:45 PM
        'intervals': [45, 60, 60, 60, 60, 60, 60, 60, 45], // 9 hours
      },
      '3': {
        'start': 945, // 3:45 PM
        'end': 1455, // 12:15 AM (+1 day)
        'intervals': [15, 60, 60, 60, 60, 60, 60, 60, 60, 15], // 10 hours
      },
    };

    // Get shift data
    final shiftData = shifts[shift];
    if (shiftData == null) {
      return {'currentHour': 1, 'totalHours': 8}; // Default fallback
    }

    final shiftStart = shiftData['start'] as int;
    final intervals = (shiftData['intervals'] as List<dynamic>).cast<int>();
    final totalHours = intervals.length;

    // Calculate elapsed minutes from shift start
    int elapsedMinutes = nowMinutes - shiftStart;
    if (elapsedMinutes < 0) {
      elapsedMinutes += 1440; // Account for midnight wrap-around
    }

    // Find current hour based on intervals
    int currentHour = 1;
    int cumulativeMinutes = 0;
    
    for (int i = 0; i < intervals.length; i++) {
      cumulativeMinutes += intervals[i];
      if (elapsedMinutes < cumulativeMinutes) {
        currentHour = i + 1;
        break;
      }
    }

    // If no interval found, we're in the last hour or past shift end
    if (currentHour == 1 && elapsedMinutes >= cumulativeMinutes) {
      currentHour = totalHours;
    }

    return {'currentHour': currentHour, 'totalHours': totalHours};
  }

  // Method to manually clear log file if needed
  Future<void> clearLog() async {
    if (_loggingInitialized) {
      await _logFile.writeAsString('');
      await _logMessage('=== LOG CLEARED ===');
    }
  }

  // Method to get log file path
  String getLogFilePath() {
    return _logFile?.path ?? 'Log not initialized';
  }
}