import 'package:flutter/material.dart';

import 'services/api_service.dart';

class ProfilePage extends StatefulWidget {
  final int userId;

  const ProfilePage({super.key, required this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final fitnessLevelController = TextEditingController();
  final preferredWorkoutController = TextEditingController();
  final targetWeightController = TextEditingController();
  final calorieGoalController = TextEditingController();
  final proteinGoalController = TextEditingController();
  final medicalConditionsController = TextEditingController();

  String selectedGoal = "Lose Weight";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Fitness Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              "Logged In User ID: ${widget.userId}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: fitnessLevelController,
              decoration: const InputDecoration(labelText: "Fitness Level"),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: preferredWorkoutController,
              decoration: const InputDecoration(labelText: "Preferred Workout"),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: targetWeightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Target Weight"),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: calorieGoalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Daily Calorie Goal",
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: proteinGoalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Daily Protein Goal",
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: medicalConditionsController,
              decoration: const InputDecoration(
                labelText: "Medical Conditions",
              ),
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value: selectedGoal,
              decoration: const InputDecoration(labelText: "Fitness Goal"),
              items: const [
                DropdownMenuItem(
                  value: "Lose Weight",
                  child: Text("Lose Weight"),
                ),
                DropdownMenuItem(
                  value: "Gain Muscle",
                  child: Text("Gain Muscle"),
                ),
                DropdownMenuItem(
                  value: "Maintain Fitness",
                  child: Text("Maintain Fitness"),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  selectedGoal = value!;
                });
              },
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () async {
                Map<String, dynamic> profileData = {
                  "userID": widget.userId,
                  "fitnessLevel": fitnessLevelController.text,
                  "preferredWorkout": preferredWorkoutController.text,
                  "targetWeight":
                      int.tryParse(targetWeightController.text) ?? 0,
                  "dailyCalorieGoal":
                      int.tryParse(calorieGoalController.text) ?? 0,
                  "dailyProteinGoal":
                      int.tryParse(proteinGoalController.text) ?? 0,
                  "medicalConditions": medicalConditionsController.text,
                  "fitnessGoal": selectedGoal,
                };

                bool success = await ApiService.saveProfile(profileData);

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Profile Saved Successfully")),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Failed To Save Profile")),
                  );
                }
              },
              child: const Text("Save Profile"),
            ),
          ],
        ),
      ),
    );
  }
}
