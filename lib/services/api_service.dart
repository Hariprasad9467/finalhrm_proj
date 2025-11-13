import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/leave.dart';

class ApiService {
  // Use your local server IP and correct port
  static const String baseUrl = 'http://localhost:5000/api/leave';

  static Future<List<Leave>> fetchLeaves() async {
    final res = await http.get(Uri.parse(baseUrl));
    if (res.statusCode == 200) {
      final List data = json.decode(res.body);
      return data.map((e) => Leave.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load leaves');
    }
  }

  static Future<void> applyLeave(Leave leave) async {
    final res = await http.post(
      Uri.parse('$baseUrl/apply'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(leave.toJson()),
    );

    if (res.statusCode != 201) {
      throw Exception('Failed to apply leave');
    }
  }

  static Future<void> updateLeave(String id, Leave leave) async {
    final res = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(leave.toJson()),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to update leave');
    }
  }

  static Future<void> deleteLeave(String id) async {
    final res = await http.delete(Uri.parse('$baseUrl/$id'));
    if (res.statusCode != 200) {
      throw Exception('Failed to delete leave');
    }
  }
}
