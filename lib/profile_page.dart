import 'package:flutter/material.dart';

import 'services/api_service.dart';

class ProfilePage extends StatefulWidget {
  final int userId;

  const ProfilePage({super.key, required this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final targetWeightController = TextEditingController();
  final calorieGoalController = TextEditingController();
  final proteinGoalController = TextEditingController();
  final medicalConditionsController = TextEditingController();

  String selectedFitnessLevel = "Beginner";
  String selectedWorkout = "Cardio";
  String selectedGoal = "Lose Weight";

  bool profileExists = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    setState(() {
      isLoading = true;
    });

    final profile = await ApiService.getProfile(widget.userId);

    if (profile != null) {
      profileExists = true;

      selectedFitnessLevel = profile["fitnessLevel"] ?? "Beginner";

      selectedWorkout = profile["preferredWorkout"] ?? "Cardio";

      selectedGoal = profile["fitnessGoal"] ?? "Lose Weight";

      targetWeightController.text = profile["targetWeight"]?.toString() ?? "";

      calorieGoalController.text =
          profile["dailyCalorieGoal"]?.toString() ?? "";

      proteinGoalController.text =
          profile["dailyProteinGoal"]?.toString() ?? "";

      medicalConditionsController.text = profile["medicalConditions"] ?? "";
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Fitness Profile"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),

      body: Container(
        color: const Color(0xFFF5F7FB),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(
                    Icons.fitness_center,
                    size: 80,
                    color: Colors.deepPurple,
                  ),

                  const SizedBox(height: 10),

                  Text(
                    profileExists
                        ? "Update Your Fitness Profile"
                        : "Create Your Fitness Profile",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 25),

                  DropdownButtonFormField<String>(
                    value: selectedFitnessLevel,
                    decoration: const InputDecoration(
                      labelText: "Fitness Level",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: "Beginner",
                        child: Text("Beginner"),
                      ),
                      DropdownMenuItem(
                        value: "Intermediate",
                        child: Text("Intermediate"),
                      ),
                      DropdownMenuItem(
                        value: "Advanced",
                        child: Text("Advanced"),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedFitnessLevel = value!;
                      });
                    },
                  ),

                  const SizedBox(height: 15),

                  DropdownButtonFormField<String>(
                    value: selectedWorkout,
                    decoration: const InputDecoration(
                      labelText: "Preferred Workout",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: "Cardio", child: Text("Cardio")),
                      DropdownMenuItem(
                        value: "Strength Training",
                        child: Text("Strength Training"),
                      ),
                      DropdownMenuItem(
                        value: "Running",
                        child: Text("Running"),
                      ),
                      DropdownMenuItem(
                        value: "Cycling",
                        child: Text("Cycling"),
                      ),
                      DropdownMenuItem(value: "Yoga", child: Text("Yoga")),
                      DropdownMenuItem(value: "HIIT", child: Text("HIIT")),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedWorkout = value!;
                      });
                    },
                  ),

                  const SizedBox(height: 15),

                  DropdownButtonFormField<String>(
                    value: selectedGoal,
                    decoration: const InputDecoration(
                      labelText: "Fitness Goal",
                      border: OutlineInputBorder(),
                    ),
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

                  const SizedBox(height: 15),

                  TextField(
                    controller: targetWeightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Target Weight (kg)",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: calorieGoalController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Daily Calorie Goal",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: proteinGoalController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Daily Protein Goal (g)",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: medicalConditionsController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Medical Conditions",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () async {
                        Map<String, dynamic> profileData = {
                          "userID": widget.userId,
                          "fitnessLevel": selectedFitnessLevel,
                          "preferredWorkout": selectedWorkout,
                          "targetWeight":
                              int.tryParse(targetWeightController.text) ?? 0,
                          "dailyCalorieGoal":
                              int.tryParse(calorieGoalController.text) ?? 0,
                          "dailyProteinGoal":
                              int.tryParse(proteinGoalController.text) ?? 0,
                          "medicalConditions": medicalConditionsController.text,
                          "fitnessGoal": selectedGoal,
                        };

                        bool success = await ApiService.saveProfile(
                          profileData,
                        );

                        if (success) {
                          // Reload latest data from MySQL
                          await loadProfile();

                          setState(() {
                            profileExists = true;
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Profile Updated Successfully"),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Failed To Save Profile"),
                            ),
                          );
                        }
                      },
                      child: Text(
                        profileExists ? "Update Profile" : "Save Profile",
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
