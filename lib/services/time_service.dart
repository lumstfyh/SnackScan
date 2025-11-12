import 'dart:convert';
import 'package:http/http.dart' as http;

class TimeService {
  // Ambil info timezone dari beberapa API
  static Future<Map<String, dynamic>?> fetchTimezoneInfo(String zone) async {
    // Coba WorldTimeAPI
    try {
      final url1 = Uri.parse('https://worldtimeapi.org/api/timezone/$zone');
      print('📡 [TimeService] Fetching dari WorldTimeAPI: $zone');

      final response1 = await http
          .get(url1)
          .timeout(
            Duration(seconds: 10),
            onTimeout: () => throw Exception('WorldTimeAPI timeout'),
          );

      if (response1.statusCode == 200) {
        final data = json.decode(response1.body);
        print('✅ [TimeService] WorldTimeAPI berhasil: ${data['utc_offset']}');

        return {
          'currentLocalTimeOffset': data['utc_offset'],
          'utcOffset': data['utc_offset'],
          'timezone': data['timezone'],
          'datetime': data['datetime'],
        };
      } else {
        print('❌ [TimeService] WorldTimeAPI status: ${response1.statusCode}');
      }
    } catch (e) {
      print('❌ [TimeService] WorldTimeAPI error: $e');
    }

    // Coba TimeAPI.io jika gagal
    try {
      final url2 = Uri.parse(
        'https://timeapi.io/api/TimeZone/zone?timeZone=$zone',
      );
      print('📡 [TimeService] Coba TimeAPI.io: $zone');

      final response2 = await http
          .get(url2)
          .timeout(
            Duration(seconds: 10),
            onTimeout: () => throw Exception('TimeAPI.io timeout'),
          );

      if (response2.statusCode == 200) {
        final data = json.decode(response2.body);
        final offsetStr =
            data['currentLocalTimeOffset']?.toString() ?? '+00:00';

        // Validasi offset, hindari +00:00 untuk timezone selain UTC/GMT/London
        if (offsetStr == '+00:00' &&
            !zone.contains('UTC') &&
            !zone.contains('GMT') &&
            !zone.contains('London')) {
          print('⚠️  [TimeService] Offset +00:00 tidak valid untuk $zone');
          throw Exception('Invalid offset from TimeAPI.io');
        }

        print('✅ [TimeService] TimeAPI.io berhasil: $offsetStr');
        return {
          'currentLocalTimeOffset': offsetStr,
          'utcOffset': offsetStr,
          'timezone': zone,
        };
      } else {
        print('❌ [TimeService] TimeAPI.io status: ${response2.statusCode}');
      }
    } catch (e) {
      print('❌ [TimeService] TimeAPI.io error: $e');
    }

    // Coba TimezoneDB sebagai alternatif terakhir
    try {
      final url3 = Uri.parse(
        'http://api.timezonedb.com/v2.1/get-time-zone?key=demo&format=json&by=zone&zone=$zone',
      );
      print('📡 [TimeService] Coba TimezoneDB: $zone');

      final response3 = await http
          .get(url3)
          .timeout(
            Duration(seconds: 10),
            onTimeout: () => throw Exception('TimezoneDB timeout'),
          );

      if (response3.statusCode == 200) {
        final data = json.decode(response3.body);
        if (data['status'] == 'OK') {
          final gmtOffsetSeconds = data['gmtOffset'] as int;
          final hours = gmtOffsetSeconds ~/ 3600;
          final minutes = (gmtOffsetSeconds.abs() % 3600) ~/ 60;
          final sign = hours >= 0 ? '+' : '-';
          final offsetStr =
              '$sign${hours.abs().toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';

          print('✅ [TimeService] TimezoneDB berhasil: $offsetStr');
          return {
            'currentLocalTimeOffset': offsetStr,
            'utcOffset': offsetStr,
            'timezone': data['zoneName'],
          };
        }
      }
    } catch (e) {
      print('❌ [TimeService] TimezoneDB error: $e');
    }

    print('⚠️  [TimeService] Semua API gagal untuk $zone');
    return null;
  }

  // Parse string offset UTC menjadi Duration
  static Duration? parseUtcOffset(String? offset) {
    if (offset == null || offset.isEmpty) {
      print('⚠️  [TimeService] Offset null atau kosong');
      return null;
    }

    try {
      print('🔄 [TimeService] Parsing offset: "$offset"');
      offset = offset.trim();
      final sign = offset.startsWith('-') ? -1 : 1;
      final cleanOffset = offset.substring(1).replaceAll(':', '');

      int hours = 0, mins = 0;
      if (cleanOffset.length >= 4) {
        hours = int.parse(cleanOffset.substring(0, 2));
        mins = int.parse(cleanOffset.substring(2, 4));
      } else if (cleanOffset.length == 3) {
        hours = int.parse(cleanOffset.substring(0, 1));
        mins = int.parse(cleanOffset.substring(1, 3));
      } else if (cleanOffset.length >= 2) {
        hours = int.parse(cleanOffset.substring(0, 2));
      } else if (cleanOffset.length == 1) {
        hours = int.parse(cleanOffset);
      }

      final duration = Duration(hours: sign * hours, minutes: sign * mins);
      print(
        '✅ [TimeService] Parsed: ${duration.inHours}h ${duration.inMinutes.remainder(60)}m',
      );
      return duration;
    } catch (e) {
      print('❌ [TimeService] Error parsing offset "$offset": $e');
      return null;
    }
  }

  // Fallback offset untuk timezone populer
  static final Map<String, Duration> fallbackOffsets = {
    //Asia
    'Asia/Jakarta': Duration(hours: 7),
    'Asia/Makassar': Duration(hours: 8),
    'Asia/Jayapura': Duration(hours: 9),
    'Asia/Tokyo': Duration(hours: 9),
    'Asia/Singapore': Duration(hours: 8),
    'Asia/Hong_Kong': Duration(hours: 8),
    'Asia/Bangkok': Duration(hours: 7),
    'Asia/Kuala_Lumpur': Duration(hours: 8),
    'Asia/Manila': Duration(hours: 8),
    'Asia/Seoul': Duration(hours: 9),
    'Asia/Dubai': Duration(hours: 4),
    'Asia/Kolkata': Duration(hours: 5, minutes: 30),
    'Asia/Shanghai': Duration(hours: 8),

    //Eropa
    'Europe/London': Duration(hours: 0),
    'Europe/Paris': Duration(hours: 1),
    'Europe/Berlin': Duration(hours: 1),
    'Europe/Rome': Duration(hours: 1),
    'Europe/Madrid': Duration(hours: 1),
    'Europe/Amsterdam': Duration(hours: 1),
    'Europe/Moscow': Duration(hours: 3),

    //Amerika
    'America/New_York': Duration(hours: -5),
    'America/Chicago': Duration(hours: -6),
    'America/Denver': Duration(hours: -7),
    'America/Los_Angeles': Duration(hours: -8),
    'America/Toronto': Duration(hours: -5),
    'America/Mexico_City': Duration(hours: -6),
    'America/Sao_Paulo': Duration(hours: -3),

    //Australia
    'Australia/Sydney': Duration(hours: 11),
    'Australia/Melbourne': Duration(hours: 11),
    'Australia/Perth': Duration(hours: 8),

    //Etc
    'Pacific/Auckland': Duration(hours: 13),
    'UTC': Duration.zero,
    'GMT': Duration.zero,
  };

  // Ambil offset timezone dengan fallback otomatis
  static Future<Duration> getTimezoneOffset(String zone) async {
    print('🌍 [TimeService] Mendapatkan offset untuk: $zone');
    final info = await fetchTimezoneInfo(zone);

    if (info != null) {
      final offsetStr = info['currentLocalTimeOffset'] ?? info['utcOffset'];
      final parsed = parseUtcOffset(offsetStr);

      if (parsed != null && parsed != Duration.zero) {
        print('✅ [TimeService] Menggunakan API offset: $parsed');
        return parsed;
      } else if (parsed != null &&
          parsed == Duration.zero &&
          (zone.contains('UTC') ||
              zone.contains('GMT') ||
              zone.contains('London'))) {
        return Duration.zero;
      }
      print('⚠️  [TimeService] API mengembalikan offset 00:00 tidak valid');
    }

    if (fallbackOffsets.containsKey(zone)) {
      final fallback = fallbackOffsets[zone]!;
      print('⚠️  [TimeService] Menggunakan fallback offset: $fallback');
      return fallback;
    }

    print('❌ [TimeService] Tidak ada offset, default ke UTC');
    return Duration.zero;
  }

  // Format Duration ke string offset
  static String formatOffset(Duration offset) {
    final sign = offset.isNegative ? '-' : '+';
    final abs = offset.abs();
    final hours = abs.inHours;
    final mins = abs.inMinutes.remainder(60);
    return '$sign${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
  }

  // Cek apakah ada fallback untuk timezone
  static bool hasFallback(String zone) {
    return fallbackOffsets.containsKey(zone);
  }
}
