import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final heightController = TextEditingController();
  final weightController = TextEditingController();

  String selectedGoal = "Lose Weight";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Fitness Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Full Name"),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Age"),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: heightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Height (cm)"),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Weight (kg)"),
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value: selectedGoal,
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
              decoration: const InputDecoration(labelText: "Fitness Goal"),
            ),

            const SizedBox(height: 30),

            ElevatedButton(onPressed: () async {
  await FirebaseFirestore.instance.collection('profiles').add({
    'name': nameController.text,
    'age': ageController.text,
    'height': heightController.text,
    'weight': weightController.text,
    'goal': selectedGoal,
  });

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Profile Saved"),
    ),
  );
}, child: const Text("Save Profile")),
          ],
        ),
      ),
    );
  }
}
