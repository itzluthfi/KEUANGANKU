import 'dart:convert';
import 'package:http/http.dart' as http;

class ExchangeService {
  // App ID dari Open Exchange Rates
  final String appId = '6abc5d8591134ccaad7c79be7fe2b793';

  Future<Map<String, dynamic>> fetchRates() async {
    final url = Uri.parse('https://openexchangerates.org/api/latest.json?app_id=$appId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Gagal memuat data kurs');
      }
    } catch (e) {
      throw Exception('Kesalahan jaringan: $e');
    }
  }
}