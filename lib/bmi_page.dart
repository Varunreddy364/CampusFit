import 'package:flutter/material.dart';

class BMIPage extends StatefulWidget {
  const BMIPage({super.key});

  @override
  State<BMIPage> createState() => _BMIPageState();
}

class _BMIPageState extends State<BMIPage> {
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();

  double bmi = 0;
  String category = "";

  void calculateBMI() {
    double height = double.tryParse(heightController.text) ?? 0;

    double weight = double.tryParse(weightController.text) ?? 0;

    if (height > 0 && weight > 0) {
      double h = height / 100;
      bmi = weight / (h * h);

      if (bmi < 18.5) {
        category = "Underweight";
      } else if (bmi < 25) {
        category = "Normal Weight";
      } else if (bmi < 30) {
        category = "Overweight";
      } else {
        category = "Obese";
      }

      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("BMI Calculator"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: heightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Height (cm)"),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Weight (kg)"),
            ),

            const SizedBox(height: 25),

            ElevatedButton(
              onPressed: calculateBMI,
              child: const Text("Calculate BMI"),
            ),

            const SizedBox(height: 30),

            Text(
              "BMI: ${bmi.toStringAsFixed(1)}",
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Text(
              category,
              style: const TextStyle(
                fontSize: 22,
                color: Colors.deepPurple,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
