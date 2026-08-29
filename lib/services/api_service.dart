import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  // SAVE FITNESS PROFILE
  static Future<bool> saveProfile(Map<String, dynamic> profileData) async {
    final response = await http.post(
      Uri.parse("http://10.0.2.2:8080/fitness/save"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(profileData),
    );

    return response.statusCode == 200;
  }

  // REGISTER USER
  static Future<bool> registerUser(Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse("http://10.0.2.2:8080/user/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(userData),
    );

    return response.statusCode == 200;
  }

  // LOGIN USER
  static Future<Map<String, dynamic>?> loginUser(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse("http://10.0.2.2:8080/user/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    if (response.statusCode == 200 && response.body.isNotEmpty) {
      return jsonDecode(response.body);
    }

    return null;
  }
}
