import 'package:flutter/material.dart';

import 'services/api_service.dart';

class ViewProfilePage extends StatefulWidget {
  final int userId;

  const ViewProfilePage({super.key, required this.userId});

  @override
  State<ViewProfilePage> createState() => _ViewProfilePageState();
}

class _ViewProfilePageState extends State<ViewProfilePage> {
  Map<String, dynamic>? user;
  Map<String, dynamic>? profile;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
  final userData = await ApiService.getUser(widget.userId);
  final profileData = await ApiService.getProfile(widget.userId);

  print("PROFILE DATA = $profileData");

  setState(() {
    user = userData;
    profile = profileData;
    isLoading = false;
  });
}

  

  Widget buildInfoTile(String title, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurple),
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.deepPurple,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),

            const SizedBox(height: 15),

            Text(
              user?["fullName"] ?? "User",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            Text(
              user?["email"] ?? "",
              style: TextStyle(color: Colors.grey[700]),
            ),

            const SizedBox(height: 25),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Personal Information",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 10),

            buildInfoTile(
              "Gender",
              user?["gender"]?.toString() ?? "Not Available",
              Icons.person_outline,
            ),

            buildInfoTile(
              "Height",
              "${user?["height"] ?? "-"} cm",
              Icons.height,
            ),

            buildInfoTile(
              "Weight",
              "${user?["weight"] ?? "-"} kg",
              Icons.monitor_weight,
            ),

            const SizedBox(height: 20),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Fitness Information",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 10),

            buildInfoTile(
              "Fitness Level",
              profile?["fitnessLevel"]?.toString() ?? "Not Available",
              Icons.fitness_center,
            ),

            buildInfoTile(
              "Preferred Workout",
              profile?["preferredWorkout"]?.toString() ?? "Not Available",
              Icons.sports_gymnastics,
            ),

            buildInfoTile(
              "Fitness Goal",
              profile?["fitnessGoal"]?.toString() ?? "Not Available",
              Icons.flag,
            ),

            buildInfoTile(
              "Target Weight",
              "${profile?["targetWeight"] ?? "-"} kg",
              Icons.track_changes,
            ),

            buildInfoTile(
              "Daily Calorie Goal",
              "${profile?["dailyCalorieGoal"] ?? "-"} kcal",
              Icons.local_fire_department,
            ),

            buildInfoTile(
              "Daily Protein Goal",
              "${profile?["dailyProteinGoal"] ?? "-"} g",
              Icons.egg_alt,
            ),

            buildInfoTile(
              "Medical Conditions",
              profile?["medicalConditions"]?.toString() ?? "None",
              Icons.medical_information,
            ),
          ],
        ),
      ),
    );
  }
}
