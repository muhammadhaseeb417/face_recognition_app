import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://192.168.181.73:5000';

  static Future<http.Response> post(
      String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    return await http.post(url,
        body: jsonEncode(data), headers: {'Content-Type': 'application/json'});
  }

  static Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    return await http.get(url);
  }

  static Future<http.Response> delete(
      String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    return await http.delete(url,
        body: jsonEncode(data), headers: {'Content-Type': 'application/json'});
  }
}
