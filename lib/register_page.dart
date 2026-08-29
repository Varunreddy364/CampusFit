import 'package:flutter/material.dart';

import 'services/api_service.dart';

class RegisterPage extends StatelessWidget {
  RegisterPage({super.key});

  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final genderController = TextEditingController();
  final heightController = TextEditingController();
  final weightController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("CampusFit Register")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: fullNameController,
              decoration: const InputDecoration(labelText: "Full Name"),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: genderController,
              decoration: const InputDecoration(labelText: "Gender"),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: heightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Height"),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Weight"),
            ),

            const SizedBox(height: 25),

            ElevatedButton(
              onPressed: () async {
                Map<String, dynamic> userData = {
                  "fullName": fullNameController.text,
                  "email": emailController.text,
                  "password": passwordController.text,
                  "gender": genderController.text,
                  "height": int.tryParse(heightController.text) ?? 0,
                  "weight": int.tryParse(weightController.text) ?? 0,
                };

                bool success = await ApiService.registerUser(userData);

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Registration Successful")),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Registration Failed")),
                  );
                }
              },
              child: const Text("Register"),
            ),
          ],
        ),
      ),
    );
  }
}
