import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  // =========================
  // REGISTER USER
  // =========================
  static Future<bool> registerUser(Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse("http://10.0.2.2:8080/user/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(userData),
    );

    return response.statusCode == 200;
  }

  // =========================
  // LOGIN USER
  // =========================
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

  // =========================
  // GET USER DETAILS
  // =========================
  static Future<Map<String, dynamic>?> getUser(int userId) async {
    final response = await http.get(
      Uri.parse("http://10.0.2.2:8080/user/$userId"),
    );

    if (response.statusCode == 200 && response.body.isNotEmpty) {
      return jsonDecode(response.body);
    }

    return null;
  }

  // =========================
  // SAVE FITNESS PROFILE
  // =========================
  static Future<bool> saveProfile(Map<String, dynamic> profileData) async {
    final response = await http.post(
      Uri.parse("http://10.0.2.2:8080/fitness/save"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(profileData),
    );

    return response.statusCode == 200;
  }

  // =========================
  // GET FITNESS PROFILE
  // =========================
  static Future<Map<String, dynamic>?> getProfile(int userId) async {
    final response = await http.get(
      Uri.parse("http://10.0.2.2:8080/fitness/$userId"),
    );

    if (response.statusCode == 200 && response.body.isNotEmpty) {
      return jsonDecode(response.body);
    }

    return null;
  }

  static Future<bool> addMeal(Map<String, dynamic> mealData) async {
    final response = await http.post(
      Uri.parse("http://10.0.2.2:8080/meal/add"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(mealData),
    );

    return response.statusCode == 200;
  }

  static Future<List<dynamic>> getTodaysMeals(int userId) async {
    final response = await http.get(
      Uri.parse("http://10.0.2.2:8080/meal/today/$userId"),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return [];
  }

  static Future<List<dynamic>> getUserSchedule(int userId) async {
    final response = await http.get(
      Uri.parse("http://10.0.2.2:8080/schedule/user/$userId"),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return [];
  }

  static Future<bool> updateScheduleStatus(int itemId, String status) async {
    final response = await http.put(
      Uri.parse("http://10.0.2.2:8080/schedule/updateStatus/$itemId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"status": status}),
    );

    return response.statusCode == 200;
  }

  // =========================
  // ADAPTIVE PLANNING SYSTEM
  // =========================

  static Future<bool> addTimetableClass(Map<String, dynamic> classData) async {
    final response = await http.post(
      Uri.parse("http://10.0.2.2:8080/api/adaptive/timetable/add"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(classData),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<bool> addAcademicTask(Map<String, dynamic> taskData) async {
    final response = await http.post(
      Uri.parse("http://10.0.2.2:8080/api/adaptive/academic-task/add"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(taskData),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<Map<String, dynamic>?> generateAdaptivePlan(int userId, String dayOfWeek) async {
    final response = await http.get(
      Uri.parse("http://10.0.2.2:8080/api/adaptive/plan/generate/$userId/$dayOfWeek"),
    );

    if (response.statusCode == 200 && response.body.isNotEmpty) {
      return jsonDecode(response.body);
    }
    return null;
  }

  static Future<List<dynamic>> getUserTimetable(int userId) async {
    final response = await http.get(
      Uri.parse("http://10.0.2.2:8080/api/adaptive/timetable/$userId"),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  static Future<bool> deleteTimetableClass(int classId) async {
    final response = await http.delete(
      Uri.parse("http://10.0.2.2:8080/api/adaptive/timetable/delete/$classId"),
    );
    return response.statusCode == 200;
  }

  static Future<List<dynamic>> getAcademicTasks(int userId) async {
    final response = await http.get(
      Uri.parse("http://10.0.2.2:8080/api/adaptive/academic-task/$userId"),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  static Future<bool> updateAcademicTaskProgress(int taskId, int minutesCompleted) async {
    final response = await http.put(
      Uri.parse("http://10.0.2.2:8080/api/adaptive/academic-task/progress/$taskId?minutesCompleted=$minutesCompleted"),
    );
    return response.statusCode == 200;
  }

  static Future<bool> updateAcademicTaskStatus(int taskId, String status) async {
    return await updateAcademicTask(taskId, {"status": status});
  }

  static Future<bool> updateAcademicTask(int taskId, Map<String, dynamic> updatedData) async {
    final response = await http.put(
      Uri.parse("http://10.0.2.2:8080/api/adaptive/academic-task/update/$taskId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(updatedData),
    );
    return response.statusCode == 200;
  }

  static Future<bool> deleteAcademicTask(int taskId) async {
    final response = await http.delete(
      Uri.parse("http://10.0.2.2:8080/api/adaptive/academic-task/delete/$taskId"),
    );
    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>?> generateAdaptivePlanForDate(int userId, String dateStr) async {
    final response = await http.get(
      Uri.parse("http://10.0.2.2:8080/api/adaptive/plan/generate-by-date/$userId/$dateStr"),
    );
    if (response.statusCode == 200 && response.body.isNotEmpty) {
      return jsonDecode(response.body);
    }
    return null;
  }
  static Future<bool> submitFeedback(Map<String, dynamic> feedbackData) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/feedback/submit"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(feedbackData),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
    } catch (_) {}

    // Fallback if baseUrl was emulator but running on desktop/web or vice versa
    try {
      final fallbackUrl = baseUrl.contains("10.0.2.2")
          ? "http://localhost:8080/api/feedback/submit"
          : "http://10.0.2.2:8080/api/feedback/submit";
      final response = await http.post(
        Uri.parse(fallbackUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(feedbackData),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  // =========================
  // ACADEMIC SCHEDULE MODULE
  // =========================
  static String get baseUrl {
    try {
      // Android emulator uses 10.0.2.2, desktop/web uses localhost
      return "http://10.0.2.2:8080";
    } catch (_) {
      return "http://localhost:8080";
    }
  }

  static Future<Map<String, dynamic>> addAcademicSchedule(Map<String, dynamic> scheduleData) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/academic-schedule/add"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(scheduleData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {"success": true, "data": jsonDecode(response.body)};
      } else {
        String errorMessage = "Failed to add class";
        try {
          final body = jsonDecode(response.body);
          if (body is Map && body.containsKey("error")) {
            errorMessage = body["error"];
          }
        } catch (_) {}
        return {"success": false, "error": errorMessage};
      }
    } catch (e) {
      return {"success": false, "error": e.toString()};
    }
  }

  static Future<List<dynamic>> getAcademicSchedule(int userId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/academic-schedule/user/$userId"),
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> deleteAcademicSchedule(int scheduleId) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/api/academic-schedule/$scheduleId"),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // =========================
  // ACADEMIC TASKS MODULE
  // =========================
  static Future<Map<String, dynamic>> addAcademicTaskItem(Map<String, dynamic> taskData) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/academic-task/add"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(taskData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {"success": true, "data": jsonDecode(response.body)};
      } else {
        String errorMessage = "Failed to add task";
        try {
          final body = jsonDecode(response.body);
          if (body is Map && body.containsKey("error")) {
            errorMessage = body["error"];
          }
        } catch (_) {}
        return {"success": false, "error": errorMessage};
      }
    } catch (e) {
      return {"success": false, "error": e.toString()};
    }
  }

  static Future<List<dynamic>> fetchAcademicTasks(int userId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/academic-task/user/$userId"),
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> markAcademicTaskCompleted(int taskId) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/api/academic-task/$taskId/complete"),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> toggleAcademicTaskStatus(int taskId, String status) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/api/academic-task/$taskId/status"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"status": status}),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> deleteAcademicTaskItem(int taskId) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/api/academic-task/$taskId"),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // =========================
  // STUDY PLAN GENERATION ENGINE
  // =========================
  static Future<Map<String, dynamic>> generateStudyPlanForUser(int userId) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/study-plan/generate/$userId"),
      );

      if (response.statusCode == 200) {
        return {"success": true, "data": jsonDecode(response.body)};
      } else {
        String errorMessage = "Failed to generate study plan";
        try {
          final body = jsonDecode(response.body);
          if (body is Map && body.containsKey("error")) {
            errorMessage = body["error"];
          }
        } catch (_) {}
        return {"success": false, "error": errorMessage};
      }
    } catch (e) {
      return {"success": false, "error": e.toString()};
    }
  }

  static Future<List<dynamic>> fetchStudyPlans(int userId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/study-plan/user/$userId"),
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> markStudyPlanCompleted(int planId) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/api/study-plan/$planId/complete"),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> toggleStudyPlanStatus(int planId, String status) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/api/study-plan/$planId/status"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"status": status}),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> deleteStudyPlanItem(int planId) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/api/study-plan/$planId"),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // =========================
  // WORKOUT PLAN GENERATOR
  // =========================

  static Future<Map<String, dynamic>> generateWorkoutPlan(int userId, {String? date}) async {
    try {
      final uri = date != null && date.isNotEmpty
          ? Uri.parse("$baseUrl/api/workout-plan/generate/$userId?date=$date")
          : Uri.parse("$baseUrl/api/workout-plan/generate/$userId");

      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        return {
          "success": true,
          "data": jsonDecode(response.body),
        };
      } else {
        String errorMessage = "Failed to generate workout plan.";
        try {
          final body = jsonDecode(response.body);
          if (body is Map && body.containsKey("error")) {
            errorMessage = body["error"];
          }
        } catch (_) {}
        return {"success": false, "error": errorMessage};
      }
    } catch (e) {
      return {"success": false, "error": e.toString()};
    }
  }

  static Future<Map<String, dynamic>?> getTodayWorkout(int userId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/workout-plan/today/$userId"),
      );
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded.containsKey("workoutId")) {
          return decoded;
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<List<dynamic>> getWorkoutPlans(int userId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/workout-plan/user/$userId"),
      );
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded;
        }
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> markWorkoutCompleted(int workoutId) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/api/workout-plan/$workoutId/complete"),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getWorkoutHistory(int userId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/workout-plan/history/$userId"),
      );
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> deleteWorkoutPlan(int workoutId) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/api/workout-plan/$workoutId"),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // =========================
  // BMI & HEALTH INSIGHTS
  // =========================

  static Future<Map<String, dynamic>?> logBmiRecord(int userId, double height, double weight) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/bmi/log"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": userId,
          "height": height,
          "weight": weight,
        }),
      );
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return null;
  }

  static Future<List<dynamic>> getBmiHistory(int userId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/bmi/history/$userId"),
      );
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) return decoded;
      }
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>?> getLatestBmi(int userId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/bmi/latest/$userId"),
      );
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded.containsKey("recordId")) {
          return decoded;
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> deleteBmiRecord(int recordId) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/api/bmi/$recordId"),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

