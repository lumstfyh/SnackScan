import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyService {
  static Future<double?> convert({
    required String from,
    required String to,
    required double amount,
  }) async {
    try {
      final url1 = Uri.parse(
        'https://api.exchangerate-api.com/v4/latest/$from',
      );
      final response1 = await http.get(url1).timeout(Duration(seconds: 10));

      if (response1.statusCode == 200) {
        final data = json.decode(response1.body);
        if (data['rates'] != null && data['rates'][to] != null) {
          final rate = (data['rates'][to] as num).toDouble();
          final result = amount * rate;
          print('CurrencyService: Converted $amount $from = $result $to');
          return result;
        }
      }
    } catch (e) {
      print('ExchangeRate-API failed: $e');
    }

    //exchangerate.host sebagai cadangan
    try {
      final url2 = Uri.parse(
        'https://api.exchangerate.host/convert?from=$from&to=$to&amount=$amount',
      );
      final response2 = await http.get(url2).timeout(Duration(seconds: 10));

      if (response2.statusCode == 200) {
        final data = json.decode(response2.body);
        if (data['result'] != null) {
          final result = (data['result'] as num).toDouble();
          print(
            'CurrencyService: Converted via exchangerate.host = $result $to',
          );
          return result;
        }
      }
    } catch (e) {
      print('exchangerate.host failed: $e');
    }

    // Jika semua API gagal, gunakan nilai tukar perkiraan (fallback)
    print('CurrencyService: Using fallback rates');
    return _convertWithFallbackRates(from, to, amount);
  }

  static double? _convertWithFallbackRates(
    String from,
    String to,
    double amount,
  ) {
    // Nilai tukar dasar terhadap USD (perkiraan)
    final Map<String, double> ratesAgainstUSD = {
      'USD': 1.0,
      'IDR': 15600.0,
      'EUR': 0.91,
      'GBP': 0.78,
      'JPY': 151.0,
      'SGD': 1.35,
      'MYR': 4.72,
      'CNY': 7.24,
    };

    // Periksa apakah kedua mata uang tersedia dalam daftar
    if (!ratesAgainstUSD.containsKey(from) ||
        !ratesAgainstUSD.containsKey(to)) {
      print('CurrencyService: Currency not supported in fallback');
      return null;
    }

    // Konversi dua tahap: dari -> USD -> ke tujuan
    final amountInUSD = amount / ratesAgainstUSD[from]!;
    final result = amountInUSD * ratesAgainstUSD[to]!;

    print('CurrencyService: Fallback conversion $amount $from = $result $to');
    return result;
  }
}
