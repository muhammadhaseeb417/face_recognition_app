import 'dart:convert';
import 'package:http/http.dart' as http;

import '../env_variables.dart';

class ApiService {
  static Future<http.Response> post(
      String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('${requestUrl}/$endpoint');
    return await http.post(url,
        body: jsonEncode(data), headers: {'Content-Type': 'application/json'});
  }

  static Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('${requestUrl}/$endpoint');
    return await http.get(url);
  }

  static Future<http.Response> delete(
      String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('${requestUrl}/$endpoint');
    return await http.delete(url,
        body: jsonEncode(data), headers: {'Content-Type': 'application/json'});
  }
}
