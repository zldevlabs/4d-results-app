import 'dart:convert';
import 'package:http/http.dart' as http;

class ResultService {
  Future<Map<String, dynamic>> fetchResults() async {
    // TEMP API (we can change later)
    final url = Uri.parse('https://api.mocki.io/v2/549a5d8b');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load results');
    }
  }
}
