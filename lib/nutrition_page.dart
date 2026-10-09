import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class NutritionPage extends StatefulWidget {
  final int userId;

  const NutritionPage({super.key, required this.userId});

  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage> {
  // Goals and Profile
  double calorieGoal = 2000;
  double proteinGoal = 100;
  double carbsGoal = 250;
  double fatGoal = 65;
  String fitnessGoal = "General Fitness";
  Map<String, dynamic>? todayWorkout;

  // Today's Aggregations
  double totalCalories = 0;
  double totalProtein = 0;
  double totalCarbs = 0;
  double totalFat = 0;
  List<dynamic> todaysMeals = [];

  // Weekly History Records
  List<dynamic> weeklyMeals = [];
  Map<String, double> weeklyCaloriesByDate = {};
  double weeklyAverageCalories = 0;
  int weeklyActiveDays = 0;

  // UI State
  bool isLoading = true;
  String selectedFilter = "All";

  @override
  void initState() {
    super.initState();
    _loadAllNutritionData();
  }

  Future<void> _loadAllNutritionData() async {
    setState(() => isLoading = true);
    await Future.wait([
      _loadFitnessGoals(),
      _loadTodayWorkout(),
      _loadTodaysMeals(),
      _loadWeeklyAnalytics(),
    ]);
    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadFitnessGoals() async {
    try {
      final profile = await ApiService.getProfile(widget.userId);
      if (profile != null && mounted) {
        final cGoal = (profile["dailyCalorieGoal"] ?? 0).toDouble();
        final pGoal = (profile["dailyProteinGoal"] ?? 0).toDouble();
        final fGoal = (profile["fitnessGoal"] ?? "").toString().trim();

        setState(() {
          calorieGoal = cGoal > 0 ? cGoal : 2000;
          proteinGoal = pGoal > 0 ? pGoal : 100;
          if (fGoal.isNotEmpty) {
            fitnessGoal = fGoal;
          }
          // Balanced macronutrient targets derived from total calorie budget
          carbsGoal = (calorieGoal * 0.50) / 4.0;
          fatGoal = (calorieGoal * 0.25) / 9.0;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadTodayWorkout() async {
    try {
      final workout = await ApiService.getTodayWorkout(widget.userId);
      if (mounted) {
        setState(() {
          todayWorkout = workout;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadTodaysMeals() async {
    try {
      final meals = await ApiService.getTodaysMeals(widget.userId);
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

      if (mounted) {
        setState(() {
          todaysMeals = meals;
          totalCalories = calories;
          totalProtein = protein;
          totalCarbs = carbs;
          totalFat = fat;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadWeeklyAnalytics() async {
    try {
      final history = await ApiService.getWeeklyMeals(widget.userId);
      final Map<String, double> dateMap = {};
      final now = DateTime.now();

      // Initialize past 7 days with zero
      for (int i = 6; i >= 0; i--) {
        final d = now.subtract(Duration(days: i));
        final key = DateFormat('yyyy-MM-dd').format(d);
        dateMap[key] = 0.0;
      }

      for (var item in history) {
        final dateStr = item["mealDate"]?.toString();
        final cal = (item["calories"] ?? 0).toDouble();
        if (dateStr != null && dateMap.containsKey(dateStr)) {
          dateMap[dateStr] = (dateMap[dateStr] ?? 0.0) + cal;
        }
      }

      // Ensure today's loaded meals reflect on today's chart bar
      final todayKey = DateFormat('yyyy-MM-dd').format(now);
      if (totalCalories > 0) {
        dateMap[todayKey] = totalCalories;
      }

      int activeDays = 0;
      double sum = 0;
      dateMap.forEach((_, val) {
        if (val > 0) {
          activeDays++;
          sum += val;
        }
      });

      if (mounted) {
        setState(() {
          weeklyMeals = history;
          weeklyCaloriesByDate = dateMap;
          weeklyActiveDays = activeDays;
          weeklyAverageCalories = activeDays > 0 ? (sum / activeDays) : 0;
        });
      }
    } catch (_) {}
  }

  // ==========================================
  // MEAL MODAL (ADD & EDIT)
  // ==========================================
  void _openMealBottomSheet({Map<String, dynamic>? mealToEdit}) {
    final isEditing = mealToEdit != null;
    final foodController = TextEditingController(text: isEditing ? (mealToEdit["foodName"] ?? "") : "");
    final quantityController = TextEditingController(text: isEditing ? (mealToEdit["quantity"] ?? "") : "");
    final caloriesController = TextEditingController(
      text: isEditing ? (mealToEdit["calories"] != null ? mealToEdit["calories"].toString() : "") : "",
    );
    final proteinController = TextEditingController(
      text: isEditing ? (mealToEdit["protein"] != null ? mealToEdit["protein"].toString() : "") : "",
    );
    final carbsController = TextEditingController(
      text: isEditing ? (mealToEdit["carbs"] != null ? mealToEdit["carbs"].toString() : "") : "",
    );
    final fatController = TextEditingController(
      text: isEditing ? (mealToEdit["fat"] != null ? mealToEdit["fat"].toString() : "") : "",
    );

    String selectedMealType = isEditing ? (mealToEdit["mealType"] ?? "Breakfast") : "Breakfast";
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void calculateCaloriesFromMacros() {
              final p = double.tryParse(proteinController.text.trim()) ?? 0;
              final c = double.tryParse(carbsController.text.trim()) ?? 0;
              final f = double.tryParse(fatController.text.trim()) ?? 0;
              final calc = (p * 4.0) + (c * 4.0) + (f * 9.0);
              if (calc > 0) {
                setModalState(() {
                  caloriesController.text = calc.toStringAsFixed(0);
                });
              }
            }

            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sheet Handle
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Sheet Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? "Edit Logged Meal" : "Log a Meal",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E1B4B),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded, color: Colors.grey),
                        ),
                      ],
                    ),
                    const Text(
                      "Record food items and nutritional values for your daily goals",
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    const SizedBox(height: 20),

                    // Meal Type Selector Chips
                    const Text(
                      "Meal Category",
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ["Breakfast", "Lunch", "Dinner", "Snacks"].map((type) {
                        final isSel = selectedMealType.toLowerCase() == type.toLowerCase();
                        return ChoiceChip(
                          label: Text(type),
                          selected: isSel,
                          selectedColor: const Color(0xFF5E35B1),
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : Colors.black87,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (val) {
                            if (val) {
                              setModalState(() => selectedMealType = type);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Food Name Field
                    TextField(
                      controller: foodController,
                      decoration: InputDecoration(
                        labelText: "Food Name *",
                        hintText: "e.g., Oatmeal with Berries, Grilled Chicken",
                        prefixIcon: const Icon(Icons.restaurant_menu_rounded, color: Color(0xFF5E35B1)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Quantity Field
                    TextField(
                      controller: quantityController,
                      decoration: InputDecoration(
                        labelText: "Serving Quantity",
                        hintText: "e.g., 200g, 1 bowl, 2 slices",
                        prefixIcon: const Icon(Icons.scale_rounded, color: Color(0xFF5E35B1)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Calories with Macro Calculator
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: caloriesController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: "Calories (kcal) *",
                              hintText: "e.g., 350",
                              prefixIcon: const Icon(Icons.local_fire_department_rounded, color: Colors.deepOrange),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: calculateCaloriesFromMacros,
                          icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                          label: const Text("Auto-Est", style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF5E35B1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Macronutrients (3 Columns)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: proteinController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: "Protein (g)",
                              prefixIcon: const Icon(Icons.fitness_center_rounded, size: 18, color: Color(0xFF5E35B1)),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: carbsController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: "Carbs (g)",
                              prefixIcon: const Icon(Icons.bakery_dining_rounded, size: 18, color: Colors.amber),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: fatController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: "Fat (g)",
                              prefixIcon: const Icon(Icons.egg_alt_rounded, size: 18, color: Colors.teal),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text("Cancel"),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    final foodName = foodController.text.trim();
                                    final calText = caloriesController.text.trim();

                                    if (foodName.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Please enter a food name")),
                                      );
                                      return;
                                    }

                                    final calVal = double.tryParse(calText) ?? 0.0;
                                    final protVal = double.tryParse(proteinController.text.trim()) ?? 0.0;
                                    final carbVal = double.tryParse(carbsController.text.trim()) ?? 0.0;
                                    final fatVal = double.tryParse(fatController.text.trim()) ?? 0.0;

                                    setModalState(() => isSaving = true);

                                    final payload = {
                                      "userid": widget.userId,
                                      "foodName": foodName,
                                      "quantity": quantityController.text.trim().isEmpty ? "1 serving" : quantityController.text.trim(),
                                      "mealType": selectedMealType,
                                      "calories": calVal,
                                      "protein": protVal,
                                      "carbs": carbVal,
                                      "fat": fatVal,
                                      "mealDate": DateFormat('yyyy-MM-dd').format(DateTime.now()),
                                    };

                                    bool success = false;
                                    if (isEditing) {
                                      final mealId = mealToEdit["mealid"] ?? mealToEdit["mealId"];
                                      if (mealId != null) {
                                        success = await ApiService.updateMeal(mealId, payload);
                                      }
                                    } else {
                                      success = await ApiService.addMeal(payload);
                                    }

                                    if (!context.mounted) return;

                                    if (success) {
                                      Navigator.pop(ctx);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(isEditing ? "Meal updated successfully" : "Meal logged successfully!"),
                                          backgroundColor: Colors.green.shade700,
                                        ),
                                      );
                                      _loadAllNutritionData();
                                    } else {
                                      setModalState(() => isSaving = false);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Failed to save meal. Please check connection."),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5E35B1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 2,
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(
                                    isEditing ? "Update Meal" : "Save Meal Log",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteMeal(Map<String, dynamic> meal) {
    final mealId = meal["mealid"] ?? meal["mealId"];
    if (mealId == null) return;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Meal Log"),
        content: Text("Are you sure you want to remove '${meal["foodName"]}' from today's meals?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final deleted = await ApiService.deleteMeal(mealId);
              if (deleted && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Meal deleted")),
                );
                _loadAllNutritionData();
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Failed to delete meal")),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // INSIGHT ENGINE (TRANSPARENT RULES)
  // ==========================================
  List<Map<String, dynamic>> _generatePersonalizedInsights() {
    final List<Map<String, dynamic>> insights = [];
    final currentHour = DateTime.now().hour;

    // 1. Missing Meal Warnings based on time of day
    final loggedTypes = todaysMeals.map((m) => (m["mealType"] ?? "").toString().toLowerCase()).toSet();

    if (currentHour >= 11 && !loggedTypes.contains("breakfast")) {
      insights.add({
        "icon": Icons.wb_twilight_rounded,
        "color": Colors.orange,
        "title": "Breakfast Reminder",
        "desc": "No breakfast logged today yet. A balanced morning meal enhances cognitive focus for morning lectures.",
      });
    }

    if (currentHour >= 14 && !loggedTypes.contains("lunch")) {
      insights.add({
        "icon": Icons.wb_sunny_rounded,
        "color": Colors.amber.shade800,
        "title": "Midday Refuel",
        "desc": "No lunch logged today yet. Sustained afternoon laboratory & study sessions require timely energy replenishing.",
      });
    }

    if (currentHour >= 20 && !loggedTypes.contains("dinner")) {
      insights.add({
        "icon": Icons.nightlight_round,
        "color": Colors.indigo,
        "title": "Evening Nutrition",
        "desc": "No dinner logged yet tonight. Adequate evening nutrition facilitates physical and cognitive muscle recovery.",
      });
    }

    // 2. Calorie Pace Insight
    final remainingCal = calorieGoal - totalCalories;
    if (totalCalories == 0) {
      insights.add({
        "icon": Icons.info_outline_rounded,
        "color": Colors.blue,
        "title": "Start Your Daily Log",
        "desc": "No meals logged today yet. Tap '+ Log Meal' to track your breakfast or morning snack.",
      });
    } else if (remainingCal > 0) {
      final pct = ((totalCalories / calorieGoal) * 100).toInt();
      insights.add({
        "icon": Icons.local_fire_department_rounded,
        "color": const Color(0xFF5E35B1),
        "title": "Calorie Pace ($pct%)",
        "desc": "You have consumed ${totalCalories.toInt()} kcal with ${remainingCal.toInt()} kcal remaining to hit your target of ${calorieGoal.toInt()} kcal.",
      });
    } else {
      final over = (totalCalories - calorieGoal).toInt();
      insights.add({
        "icon": Icons.warning_amber_rounded,
        "color": Colors.deepOrange,
        "title": "Calorie Target Reached",
        "desc": "You have exceeded your daily target by $over kcal. Focus on hydration and light fiber for remaining snacks.",
      });
    }

    // 3. Protein Target Insight
    final remProt = proteinGoal - totalProtein;
    if (totalProtein > 0 && remProt > 0) {
      insights.add({
        "icon": Icons.fitness_center_rounded,
        "color": Colors.teal,
        "title": "Protein Tracking",
        "desc": "You need ${remProt.toInt()}g more protein to reach your daily goal of ${proteinGoal.toInt()}g. Consider eggs, paneer, tofu, chicken, or lentils.",
      });
    } else if (totalProtein >= proteinGoal && proteinGoal > 0) {
      insights.add({
        "icon": Icons.verified_rounded,
        "color": Colors.green.shade700,
        "title": "Protein Goal Achieved!",
        "desc": "Great job! You reached ${totalProtein.toInt()}g protein, supporting muscle synthesis and recovery.",
      });
    }

    // 4. Workout Fueling Integration
    if (todayWorkout != null && todayWorkout!.containsKey("workoutTitle")) {
      final title = todayWorkout!["workoutTitle"] ?? "Workout";
      final burned = todayWorkout!["caloriesEstimated"] ?? 200;
      insights.add({
        "icon": Icons.bolt_rounded,
        "color": Colors.purple,
        "title": "Workout Synergy: $title",
        "desc": "You have an estimated $burned kcal burned today. Keep yourself hydrated and prioritize protein post-workout.",
      });
    }

    // 5. Goal Alignment
    if (fitnessGoal.toLowerCase().contains("weight loss") && totalCalories > 0) {
      insights.add({
        "icon": Icons.trending_down_rounded,
        "color": Colors.indigo,
        "title": "Weight Loss Strategy",
        "desc": "Staying close to your calorie ceiling preserves a steady caloric deficit for healthy fat loss.",
      });
    }

    return insights;
  }

  // ==========================================
  // BUILD METHOD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    final remainingCalories = calorieGoal - totalCalories;
    final calorieRatio = calorieGoal > 0 ? (totalCalories / calorieGoal).clamp(0.0, 1.0) : 0.0;
    final proteinRatio = proteinGoal > 0 ? (totalProtein / proteinGoal).clamp(0.0, 1.0) : 0.0;
    final carbsRatio = carbsGoal > 0 ? (totalCarbs / carbsGoal).clamp(0.0, 1.0) : 0.0;
    final fatRatio = fatGoal > 0 ? (totalFat / fatGoal).clamp(0.0, 1.0) : 0.0;

    final filteredMeals = selectedFilter == "All"
        ? todaysMeals
        : todaysMeals.where((m) => (m["mealType"] ?? "").toString().toLowerCase() == selectedFilter.toLowerCase()).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Nutrition & Wellness"),
        backgroundColor: const Color(0xFF5E35B1),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: "Refresh Data",
            onPressed: _loadAllNutritionData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openMealBottomSheet(),
        backgroundColor: const Color(0xFF5E35B1),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text("Log Meal", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadAllNutritionData,
        color: const Color(0xFF5E35B1),
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF5E35B1)))
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 90),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Refined Gradient Brand Header
                    _buildBrandHeader(),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),

                          // 2. Primary Calorie & Macro Dashboard Card
                          _buildCalorieAndMacroCard(
                            calorieRatio: calorieRatio,
                            remainingCalories: remainingCalories,
                            proteinRatio: proteinRatio,
                            carbsRatio: carbsRatio,
                            fatRatio: fatRatio,
                          ),

                          const SizedBox(height: 20),

                          // 3. Compact Metric Pills
                          _buildCompactMetricsRow(),

                          const SizedBox(height: 20),

                          // 4. Personalized Rule-Based Nutrition Insights
                          _buildPersonalizedInsightsSection(),

                          const SizedBox(height: 20),

                          // 5. Weekly Analytics & Trends
                          _buildWeeklyAnalyticsSection(),

                          const SizedBox(height: 24),

                          // 6. Today's Meals Section Header with Category Chips
                          _buildMealsSectionHeader(filteredMeals.length),

                          const SizedBox(height: 12),

                          // 7. Today's Logged Meals Cards List
                          _buildMealsList(filteredMeals),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // ==========================================
  // WIDGET COMPONENTS
  // ==========================================

  Widget _buildBrandHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5E35B1), Color(0xFF2575FC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Nutrition & Wellness",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Fuel your mind & body for peak campus performance",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _openMealBottomSheet(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF5E35B1),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text("Log", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildHeaderBadge(Icons.flag_rounded, "Goal: $fitnessGoal"),
              _buildHeaderBadge(Icons.restaurant_rounded, "${todaysMeals.length} Meals Logged"),
              if (todayWorkout != null && todayWorkout!.containsKey("workoutTitle"))
                _buildHeaderBadge(Icons.fitness_center_rounded, todayWorkout!["workoutTitle"] ?? "Workout"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieAndMacroCard({
    required double calorieRatio,
    required double remainingCalories,
    required double proteinRatio,
    required double carbsRatio,
    required double fatRatio,
  }) {
    final isExceeded = remainingCalories < 0;
    final ringColor = isExceeded
        ? Colors.deepOrange
        : (calorieRatio >= 0.85 ? Colors.amber.shade700 : const Color(0xFF5E35B1));

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Top Row: Calorie Ring + Stats
            Row(
              children: [
                // Visual Calorie Progress Ring
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          value: isExceeded ? 1.0 : calorieRatio,
                          strokeWidth: 12,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(ringColor),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "${totalCalories.toInt()}",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E1B4B),
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            "kcal eaten",
                            style: TextStyle(fontSize: 10, color: Colors.black54),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),

                // Right Column Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Daily Target", style: TextStyle(color: Colors.black54, fontSize: 13)),
                          Text(
                            "${calorieGoal.toInt()} kcal",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isExceeded ? "Over Budget" : "Remaining",
                            style: TextStyle(
                              color: isExceeded ? Colors.deepOrange : Colors.black54,
                              fontSize: 13,
                              fontWeight: isExceeded ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          Text(
                            isExceeded ? "+${(-remainingCalories).toInt()} kcal" : "${remainingCalories.toInt()} kcal",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isExceeded ? Colors.deepOrange : const Color(0xFF5E35B1),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 18),
                      Text(
                        isExceeded
                            ? "Calorie goal exceeded for today."
                            : "${(calorieRatio * 100).toInt()}% of daily energy goal consumed",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isExceeded ? Colors.deepOrange : Colors.teal.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),

            // Color-Coded Macronutrient Progress Bars
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Macronutrients Breakdown",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B)),
                ),
                Text(
                  "P: ${totalProtein.toInt()}g • C: ${totalCarbs.toInt()}g • F: ${totalFat.toInt()}g",
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 14),

            _buildMacroBar(
              name: "Protein",
              consumed: totalProtein,
              target: proteinGoal,
              unit: "g",
              ratio: proteinRatio,
              color: const Color(0xFF5E35B1),
              icon: Icons.fitness_center_rounded,
            ),
            const SizedBox(height: 10),
            _buildMacroBar(
              name: "Carbohydrates",
              consumed: totalCarbs,
              target: carbsGoal,
              unit: "g",
              ratio: carbsRatio,
              color: Colors.amber.shade800,
              icon: Icons.bakery_dining_rounded,
            ),
            const SizedBox(height: 10),
            _buildMacroBar(
              name: "Healthy Fats",
              consumed: totalFat,
              target: fatGoal,
              unit: "g",
              ratio: fatRatio,
              color: Colors.teal,
              icon: Icons.egg_alt_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroBar({
    required String name,
    required double consumed,
    required double target,
    required String unit,
    required double ratio,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 6),
                Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
            Text(
              "${consumed.toInt()} / ${target.toInt()} $unit",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 7,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactMetricsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            title: "Calories",
            value: "${totalCalories.toInt()}",
            unit: "kcal eaten",
            icon: Icons.local_fire_department_rounded,
            color: Colors.deepOrange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricTile(
            title: "Protein",
            value: "${totalProtein.toInt()}g",
            unit: "of ${proteinGoal.toInt()}g",
            icon: Icons.bolt_rounded,
            color: const Color(0xFF5E35B1),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricTile(
            title: "Meals",
            value: "${todaysMeals.length}",
            unit: "logged today",
            icon: Icons.restaurant_rounded,
            color: Colors.teal,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color, height: 1.0),
          ),
          const SizedBox(height: 4),
          Text(
            "$title\n$unit",
            maxLines: 2,
            style: const TextStyle(fontSize: 10, color: Colors.black54, height: 1.15),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalizedInsightsSection() {
    final insights = _generatePersonalizedInsights();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Personalized Nutrition Insights",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B)),
        ),
        const SizedBox(height: 10),
        Column(
          children: insights.map((item) {
            final Color color = item["color"] as Color;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.2)),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1))],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item["icon"] as IconData, size: 18, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item["title"] as String,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item["desc"] as String,
                          style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 4),
        const Text(
          "* Nutrition recommendations are rule-based academic wellness aids, not medical advice.",
          style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.black45),
        ),
      ],
    );
  }

  Widget _buildWeeklyAnalyticsSection() {
    final now = DateTime.now();
    final dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    final List<Map<String, dynamic>> barData = [];

    double maxCal = calorieGoal > 0 ? calorieGoal * 1.2 : 2500;
    weeklyCaloriesByDate.forEach((dateStr, cal) {
      if (cal > maxCal) maxCal = cal;
      final dt = DateTime.tryParse(dateStr) ?? now;
      barData.add({
        "day": dayNames[dt.weekday - 1],
        "cal": cal,
        "isToday": DateFormat('yyyy-MM-dd').format(dt) == DateFormat('yyyy-MM-dd').format(now),
      });
    });

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Weekly Calorie Intake Trend",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B)),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Past 7 days intake compared against daily target",
                      style: TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "Avg: ${weeklyAverageCalories.toInt()} kcal",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 7-Day Bar Chart
            SizedBox(
              height: 120,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: barData.map((data) {
                  final cal = data["cal"] as double;
                  final isToday = data["isToday"] as bool;
                  final heightRatio = maxCal > 0 ? (cal / maxCal).clamp(0.05, 1.0) : 0.05;

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (cal > 0)
                        Text(
                          "${cal.toInt()}",
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isToday ? const Color(0xFF5E35B1) : Colors.black54,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Container(
                        width: 22,
                        height: 75 * heightRatio,
                        decoration: BoxDecoration(
                          color: isToday
                              ? const Color(0xFF5E35B1)
                              : (cal > 0 ? Colors.indigo.shade200 : Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        data["day"] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                          color: isToday ? const Color(0xFF5E35B1) : Colors.black87,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Active Logging: $weeklyActiveDays / 7 days",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
                Text(
                  "Daily Goal: ${calorieGoal.toInt()} kcal",
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealsSectionHeader(int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Today's Meals ($count)",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B)),
            ),
            TextButton.icon(
              onPressed: () => _openMealBottomSheet(),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text("Add Food", style: TextStyle(fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF5E35B1)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ["All", "Breakfast", "Lunch", "Dinner", "Snacks"].map((cat) {
              final isSel = selectedFilter == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(cat),
                  selected: isSel,
                  selectedColor: const Color(0xFF5E35B1).withOpacity(0.15),
                  checkmarkColor: const Color(0xFF5E35B1),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: isSel ? const Color(0xFF5E35B1) : Colors.black87,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (val) {
                    setState(() => selectedFilter = cat);
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMealsList(List<dynamic> meals) {
    if (meals.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.restaurant_rounded, size: 54, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              selectedFilter == "All" ? "No meals logged today yet" : "No $selectedFilter logged today",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B)),
            ),
            const SizedBox(height: 6),
            const Text(
              "Keep your nutrition balanced by tracking your daily intake.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _openMealBottomSheet(),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text("Log a Meal Now"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5E35B1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: meals.map((meal) {
        final mealMap = meal as Map<String, dynamic>;
        final type = (mealMap["mealType"] ?? "Meal").toString();
        final foodName = mealMap["foodName"] ?? "Food";
        final qty = mealMap["quantity"] ?? "";
        final cal = (mealMap["calories"] ?? 0).toDouble();
        final p = (mealMap["protein"] ?? 0).toDouble();
        final c = (mealMap["carbs"] ?? 0).toDouble();
        final f = (mealMap["fat"] ?? 0).toDouble();

        IconData typeIcon = Icons.restaurant_rounded;
        Color typeColor = Colors.deepPurple;
        if (type.toLowerCase() == "breakfast") {
          typeIcon = Icons.free_breakfast_rounded;
          typeColor = Colors.orange;
        } else if (type.toLowerCase() == "lunch") {
          typeIcon = Icons.lunch_dining_rounded;
          typeColor = Colors.green.shade700;
        } else if (type.toLowerCase() == "dinner") {
          typeIcon = Icons.dinner_dining_rounded;
          typeColor = Colors.indigo;
        } else if (type.toLowerCase() == "snacks") {
          typeIcon = Icons.apple_rounded;
          typeColor = Colors.teal;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1.5,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Meal Type Avatar
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 24),
                ),
                const SizedBox(width: 14),

                // Meal Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              foodName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E1B4B),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.deepOrange.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "${cal.toInt()} kcal",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "$type • $qty",
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      const SizedBox(height: 8),

                      // Macro chips
                      Row(
                        children: [
                          _buildMiniMacroChip("P", "${p.toInt()}g", const Color(0xFF5E35B1)),
                          const SizedBox(width: 6),
                          _buildMiniMacroChip("C", "${c.toInt()}g", Colors.amber.shade800),
                          const SizedBox(width: 6),
                          _buildMiniMacroChip("F", "${f.toInt()}g", Colors.teal),
                          const Spacer(),
                          // Action Popup
                          PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.more_vert_rounded, size: 18, color: Colors.grey),
                            onSelected: (val) {
                              if (val == "edit") {
                                _openMealBottomSheet(mealToEdit: mealMap);
                              } else if (val == "delete") {
                                _confirmDeleteMeal(mealMap);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: "edit",
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_rounded, size: 16, color: Colors.indigo),
                                    SizedBox(width: 8),
                                    Text("Edit"),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: "delete",
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                                    SizedBox(width: 8),
                                    Text("Delete"),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMiniMacroChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        "$label: $value",
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
