import 'package:flutter/material.dart';

import '../services/api_service.dart';

class NutritionPage extends StatefulWidget {
  final int userId;

  const NutritionPage({super.key, required this.userId});
  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage> {
  double calorieGoal = 0;
  double proteinGoal = 0;

  String fitnessGoal = "";

  double totalCalories = 0;
  double totalProtein = 0;
  double totalCarbs = 0;
  double totalFat = 0;
  List<dynamic> todaysMeals = [];
  String recommendation = "";
  final TextEditingController foodController = TextEditingController();

  final TextEditingController quantityController = TextEditingController();

  final TextEditingController caloriesController = TextEditingController();

  final TextEditingController proteinController = TextEditingController();

  final TextEditingController carbsController = TextEditingController();

  final TextEditingController fatController = TextEditingController();

  String selectedMeal = "Breakfast";
  @override
  @override
  void initState() {
    super.initState();
    loadFitnessGoals();
    loadTodaysMeals();
  }

  Future<void> loadFitnessGoals() async {
    final profile = await ApiService.getProfile(widget.userId);

    if (profile != null) {
      setState(() {
        calorieGoal = (profile["dailyCalorieGoal"] ?? 0).toDouble();

        proteinGoal = (profile["dailyProteinGoal"] ?? 0).toDouble();

        fitnessGoal = profile["fitnessGoal"] ?? "";
      });
    }
  }

  Future<void> loadTodaysMeals() async {
    try {
      List<dynamic> meals = await ApiService.getTodaysMeals(widget.userId);

      double calories = 0;
      double protein = 0;
      double carbs = 0;
      double fat = 0;

      for (var meal in meals) {
        calories += (meal["calories"] ?? 0).toDouble();
        protein += (meal["protein"] ?? 0).toDouble();
        carbs += (meal["carbs"] ?? 0).toDouble();
        fat += (meal["fat"] ?? 0).toDouble();
      }

      setState(() {
        todaysMeals = meals;

        totalCalories = calories;
        totalProtein = protein;
        totalCarbs = carbs;
        totalFat = fat;
      });
    } catch (e) {
      print(e);
    }
  }

  Widget buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  @override
  void dispose() {
    foodController.dispose();
    quantityController.dispose();
    caloriesController.dispose();
    proteinController.dispose();
    carbsController.dispose();
    fatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nutrition Tracker"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Nutrition Tracker",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 8),

                  Text(
                    "Track meals and monitor your nutrition goals",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Goal Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Daily Goals",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Calories Goal"),
                        Text(
                          "${calorieGoal.toStringAsFixed(0)} kcal",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),

                    SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Protein Goal"),
                        Text(
                          "${proteinGoal.toStringAsFixed(0)} g",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Fitness Goal"),
                        Text(
                          fitnessGoal,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Log New Meal",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            buildInputField(
              controller: foodController,
              label: "Food Name",
              icon: Icons.restaurant,
            ),

            buildInputField(
              controller: quantityController,
              label: "Quantity (grams)",
              icon: Icons.scale,
              keyboardType: TextInputType.number,
            ),

            buildInputField(
              controller: caloriesController,
              label: "Calories",
              icon: Icons.local_fire_department,
              keyboardType: TextInputType.number,
            ),

            buildInputField(
              controller: proteinController,
              label: "Protein (g)",
              icon: Icons.fitness_center,
              keyboardType: TextInputType.number,
            ),

            buildInputField(
              controller: carbsController,
              label: "Carbs (g)",
              icon: Icons.bakery_dining,
              keyboardType: TextInputType.number,
            ),

            buildInputField(
              controller: fatController,
              label: "Fat (g)",
              icon: Icons.egg_alt,
              keyboardType: TextInputType.number,
            ),

            DropdownButtonFormField<String>(
              value: selectedMeal,
              decoration: InputDecoration(
                labelText: "Meal Type",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: const [
                DropdownMenuItem(value: "Breakfast", child: Text("Breakfast")),
                DropdownMenuItem(value: "Lunch", child: Text("Lunch")),
                DropdownMenuItem(value: "Dinner", child: Text("Dinner")),
                DropdownMenuItem(value: "Snacks", child: Text("Snacks")),
              ],
              onChanged: (value) {
                setState(() {
                  selectedMeal = value!;
                });
              },
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () async {
                  double calories =
                      double.tryParse(caloriesController.text) ?? 0;

                  double protein = double.tryParse(proteinController.text) ?? 0;

                  double carbs = double.tryParse(carbsController.text) ?? 0;

                  double fat = double.tryParse(fatController.text) ?? 0;
                  Map<String, dynamic> mealData = {
                    "userid": widget.userId,
                    "foodName": foodController.text,
                    "quantity": quantityController.text,
                    "mealType": selectedMeal,
                    "calories": calories,
                    "protein": protein,
                    "carbs": carbs,
                    "fat": fat,
                    "mealDate": DateTime.now().toIso8601String().split("T")[0],
                  };

                  bool saved = await ApiService.addMeal(mealData);

                  if (!saved) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Failed to save meal")),
                    );
                    return;
                  }
                  await loadTodaysMeals();
                  setState(() {
                    if (totalCalories == 0) {
                      recommendation = "";
                    } else if (totalProtein < proteinGoal * 0.5 &&
                        totalCalories < calorieGoal * 0.5) {
                      recommendation = "You are significantly below your calorie and protein goals. Add protein-rich and energy-dense foods.";
                    } else if (totalProtein < proteinGoal * 0.5) {
                      recommendation = "Protein intake is low. Consider eggs, paneer, fish, chicken, soy chunks, tofu or whey protein.";
                    } else if (totalCalories < calorieGoal * 0.5) {
                      recommendation = "Your calorie intake is low for the day. Add healthy calorie sources like rice, oats, nuts or fruits.";
                    } else if (totalCalories > calorieGoal * 1.2) {
                      recommendation = "You have exceeded your calorie goal significantly. Keep remaining meals lighter.";
                    } else if (totalFat > 70) {
                      recommendation = "Fat intake is quite high today. Reduce fried foods and focus on lean protein sources.";
                    } else if (totalCarbs > 300) {
                      recommendation = "Carbohydrate intake is high. Balance remaining meals with protein and vegetables.";
                    } else if (totalProtein >= proteinGoal &&
                        totalCalories <= calorieGoal) {
                      recommendation = "Excellent! You have achieved your protein goal while staying within calorie limits.";
                    } else if (totalProtein >= proteinGoal) {
                      recommendation = "Great protein intake today. Monitor calories to stay aligned with your fitness goal.";
                    } else if (totalCalories >= calorieGoal * 0.8 &&
                        totalProtein >= proteinGoal * 0.8) {
                      recommendation = "You are close to achieving today's nutrition goals. Keep it up!";
                    } else {
                      recommendation = "Your nutrition intake is progressing well. Continue balancing protein, carbs and fats.";
                    }
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Meal Analyzed Successfully")),
                  );
                },
                icon: const Icon(Icons.analytics),
                label: const Text("Analyze & Save Meal"),
              ),
            ),

            const SizedBox(height: 30),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Today's Nutrition Summary",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      "Calories Consumed: ${totalCalories.toStringAsFixed(0)} kcal",
                    ),

                    Text(
                      "Protein Consumed: ${totalProtein.toStringAsFixed(0)} g",
                    ),

                    Text("Carbs Consumed: ${totalCarbs.toStringAsFixed(0)} g"),

                    Text("Fat Consumed: ${totalFat.toStringAsFixed(0)} g"),

                    const Divider(),

                    Text(
                      "Calories Remaining: ${(calorieGoal - totalCalories).toStringAsFixed(0)} kcal",
                    ),

                    Text(
                      "Protein Remaining: ${(proteinGoal - totalProtein).toStringAsFixed(0)} g",
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Recommendations",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    recommendation.isEmpty
                        ? const Text(
                            "Add a meal to get nutrition recommendations",
                            style: TextStyle(color: Colors.grey),
                          )
                        : Text(recommendation),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              "Today's Meals",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            todaysMeals.isEmpty
                ? const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text("No meals logged today"),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: todaysMeals.length,
                    itemBuilder: (context, index) {
                      final meal = todaysMeals[index];

                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.restaurant),
                          title: Text(meal["foodName"] ?? ""),
                          subtitle: Text(
                            "${meal["mealType"]} • ${meal["quantity"]}",
                          ),
                          trailing: Text("${meal["calories"]} kcal"),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
