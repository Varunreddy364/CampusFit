import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'services/api_service.dart';

class BMIPage extends StatefulWidget {
  final int? userId;

  const BMIPage({
    super.key,
    this.userId,
  });

  @override
  State<BMIPage> createState() => _BMIPageState();
}

class _BMIPageState extends State<BMIPage> {
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();

  double bmi = 0.0;
  String categoryName = "";
  int selectedCategoryIndex = -1;
  String selectedGoal = "General Fitness"; // Weight Loss, Muscle Gain, General Fitness
  bool _isLoadingHistory = false;
  bool _isSavingRecord = false;
  List<Map<String, dynamic>> _bmiHistory = [];

  // Quote index
  int _quoteIndex = 0;

  static final List<String> _dailyQuotes = [
    "Your future health is built by today's decisions.",
    "Consistency beats intensity when intensity cannot be sustained.",
    "Small improvements repeated daily create extraordinary results.",
    "Every workout completed is a promise kept to yourself.",
    "Progress is measured in habits, not perfection.",
    "Take care of your body. It's the only place you have to live.",
    "Energy flows where focus goes. Prioritize your vitality.",
    "Strong bodies are sculpted by discipline, patience, and self-respect.",
  ];

  static final List<Map<String, String>> _weeklyFocusOptions = [
    {
      "title": "Increase Protein Intake",
      "desc": "Aim for 1.6-2.0g of protein per kg of body weight to support muscle recovery and satiety.",
      "tag": "Nutrition Focus",
    },
    {
      "title": "Complete 4 Workout Sessions",
      "desc": "Plan dedicated workout windows in your schedule and preserve consistency.",
      "tag": "Fitness Focus",
    },
    {
      "title": "Improve Daily Hydration",
      "desc": "Drink at least 2.5-3.0 liters of pure water daily to enhance cognitive and metabolic function.",
      "tag": "Hydration Focus",
    },
    {
      "title": "Maintain Sleep Consistency",
      "desc": "Target 7-8 hours of uninterrupted sleep to regulate hunger hormones and optimize muscle repair.",
      "tag": "Recovery Focus",
    },
  ];

  static final List<BmiZone> _bmiZones = [
    BmiZone(
      index: 0,
      title: "Severely Underweight",
      rangeLabel: "< 16.0",
      minBmi: 0.0,
      maxBmi: 15.99,
      color: const Color(0xFFEF4444), // Crimson
      healthStatus: "Significant caloric and nutrient deficit requiring structured nutritional intervention.",
      concerns: [
        "Chronic low energy and fatigue",
        "Muscle tissue wasting",
        "Nutritional and micronutrient deficiencies",
        "Compromised immune resistance",
      ],
      recommendations: [
        "Increase calorie intake gradually with nutrient-dense foods",
        "Consume protein-rich foods with every meal",
        "Follow progressive resistance strength training",
        "Improve meal consistency and avoid skipping meals",
        "Prioritize 8+ hours of restful sleep",
      ],
      motivation: "Every healthy kilogram gained is a step toward greater strength and energy.",
    ),
    BmiZone(
      index: 1,
      title: "Moderately Underweight",
      rangeLabel: "16.0 - 17.0",
      minBmi: 16.0,
      maxBmi: 16.99,
      color: const Color(0xFFF97316), // Orange
      healthStatus: "Body mass is below healthy threshold; focus on structured lean mass acquisition.",
      concerns: [
        "Reduced stamina during exercise",
        "Sub-optimal recovery between workouts",
        "Mild micronutrient shortfalls",
      ],
      recommendations: [
        "Increase nutrient-dense meals with healthy fats and complex carbs",
        "Track daily calories to ensure a 300-500 kcal surplus",
        "Improve physical recovery and sleep hygiene",
        "Focus on compound strength training movements",
      ],
      motivation: "Strong bodies are built through consistent nourishment and effort.",
    ),
    BmiZone(
      index: 2,
      title: "Mildly Underweight",
      rangeLabel: "17.0 - 18.4",
      minBmi: 17.0,
      maxBmi: 18.49,
      color: const Color(0xFFFBBF24), // Amber
      healthStatus: "Approaching healthy range; minor nutritional boost will establish optimal balance.",
      concerns: [
        "Susceptibility to energy slumps",
        "Lower bone density potential over time",
      ],
      recommendations: [
        "Build lean functional muscle through hypertrophy training",
        "Increase dietary protein intake (chicken, fish, eggs, tofu, lentils)",
        "Follow progressive workouts with adequate progressive overload",
      ],
      motivation: "Small gains today become major improvements tomorrow.",
    ),
    BmiZone(
      index: 3,
      title: "Healthy Lean",
      rangeLabel: "18.5 - 20.0",
      minBmi: 18.5,
      maxBmi: 19.99,
      color: const Color(0xFF38BDF8), // Sky Blue
      healthStatus: "Normal body mass with lean composition; great base for strength and athletic performance.",
      concerns: [],
      recommendations: [
        "Maintain balanced, whole-food nutrition",
        "Continue regular cardiovascular and resistance exercise",
        "Focus on building core strength and functional endurance",
      ],
      motivation: "You have a strong foundation. Continue building upon it.",
    ),
    BmiZone(
      index: 4,
      title: "Ideal Fitness Zone",
      rangeLabel: "20.0 - 22.0",
      minBmi: 20.0,
      maxBmi: 21.99,
      color: const Color(0xFF2DD4BF), // Teal
      healthStatus: "Prime metabolic and athletic range with optimal energy levels and cardiovascular resilience.",
      concerns: [],
      recommendations: [
        "Maintain training consistency and habit tracking",
        "Improve athletic fitness and benchmark performance",
        "Continue balanced nutrition with whole fruits and vegetables",
      ],
      motivation: "Excellence is achieved through consistency, not perfection.",
    ),
    BmiZone(
      index: 5,
      title: "Optimal Health Zone",
      rangeLabel: "22.0 - 24.9",
      minBmi: 22.0,
      maxBmi: 24.99,
      color: const Color(0xFF10B981), // Emerald Green
      healthStatus: "Benchmark health zone associated with lowest statistical risk of chronic metabolic disorders.",
      concerns: [],
      recommendations: [
        "Maintain current lifestyle and fitness routine",
        "Prioritize post-workout recovery and stretching",
        "Stay active and hydrated throughout academic days",
      ],
      motivation: "You are in an excellent position. Protect the habits that brought you here.",
    ),
    BmiZone(
      index: 6,
      title: "Slightly Above Optimal",
      rangeLabel: "25.0 - 27.0",
      minBmi: 25.0,
      maxBmi: 26.99,
      color: const Color(0xFFA3E635), // Lime
      healthStatus: "Slight elevation above optimal benchmark; easily adjusted through daily movement increases.",
      concerns: [
        "Mild metabolic strain if sedentary",
        "Early joint stress if carrying unconditioned mass",
      ],
      recommendations: [
        "Increase daily non-exercise physical activity (NEAT)",
        "Improve food choices: cut refined sugars and processed snacks",
        "Reduce uninterrupted sedentary sitting time between study sessions",
      ],
      motivation: "Small daily improvements create powerful long-term results.",
    ),
    BmiZone(
      index: 7,
      title: "Early Weight Management Zone",
      rangeLabel: "27.0 - 30.0",
      minBmi: 27.0,
      maxBmi: 29.99,
      color: const Color(0xFFF59E0B), // Amber-Orange
      healthStatus: "Weight management recommended to mitigate cardiovascular and metabolic resistance risks.",
      concerns: [
        "Elevated blood pressure predisposition",
        "Reduced stamina and breathlessness during intense tasks",
        "Sluggish recovery",
      ],
      recommendations: [
        "Follow structured 30-45 min workout sessions 4x weekly",
        "Create calorie awareness and prioritize low-calorie dense meals",
        "Increase daily brisk walking to 8,000-10,000 steps",
      ],
      motivation: "Progress starts when consistency becomes a habit.",
    ),
    BmiZone(
      index: 8,
      title: "High Risk Weight Zone",
      rangeLabel: "30.0 - 35.0",
      minBmi: 30.0,
      maxBmi: 34.99,
      color: const Color(0xFFF97316), // Deep Orange
      healthStatus: "Elevated risk profile; proactive lifestyle adaptations will yield rapid health benefits.",
      concerns: [
        "Increased risk of insulin resistance",
        "Joint and spinal load during locomotion",
        "Sub-optimal sleep apnea or snoring",
      ],
      recommendations: [
        "Adopt low-impact regular exercise (walking, swimming, cycling)",
        "Strict nutrition monitoring and portion control",
        "Improve sleep quality and stress management",
        "Focus on sustainable 0.5 kg/week weight reduction",
      ],
      motivation: "Every healthy choice today creates a healthier future.",
    ),
    BmiZone(
      index: 9,
      title: "Critical Health Improvement Zone",
      rangeLabel: "> 35.0",
      minBmi: 35.0,
      maxBmi: 100.0,
      color: const Color(0xFFDC2626), // Dark Red
      healthStatus: "High priority health improvement zone; structured habit evolution will transform vitality.",
      concerns: [
        "Cardiovascular, joint, and metabolic complications",
        "High inflammation markers",
        "Chronic fatigue",
      ],
      recommendations: [
        "Implement gradual, sustainable lifestyle modifications",
        "Follow structured beginner-friendly workout plans",
        "Set consistent daily activity and step goals",
        "Seek medical or registered dietitian consultation if needed",
      ],
      motivation: "The journey may be longer, but every step still moves you forward.",
    ),
  ];

  @override
  void initState() {
    super.initState();
    final dayOfYear = int.tryParse(DateFormat('D').format(DateTime.now())) ?? 1;
    _quoteIndex = dayOfYear % _dailyQuotes.length;

    _initializeUserData();
  }

  Future<void> _initializeUserData() async {
    if (widget.userId == null) {
      // Default sample values for standalone use
      heightController.text = "175";
      weightController.text = "70";
      _calculateLocalBMI();
      return;
    }

    setState(() {
      _isLoadingHistory = true;
    });

    try {
      final results = await Future.wait([
        ApiService.getUser(widget.userId!),
        ApiService.getProfile(widget.userId!),
        ApiService.getBmiHistory(widget.userId!),
      ]);

      final user = results[0] as Map<String, dynamic>?;
      final profile = results[1] as Map<String, dynamic>?;
      final historyList = (results[2] as List<dynamic>?) ?? [];

      if (!mounted) return;

      if (user != null) {
        if (user['height'] != null && (user['height'] as num) > 0) {
          heightController.text = user['height'].toString();
        }
        if (user['weight'] != null && (user['weight'] as num) > 0) {
          weightController.text = user['weight'].toString();
        }
      }

      if (profile != null && profile['fitnessGoal'] != null) {
        selectedGoal = profile['fitnessGoal'].toString();
      }

      _bmiHistory = historyList.map((e) => Map<String, dynamic>.from(e as Map)).toList();

      if (heightController.text.isNotEmpty && weightController.text.isNotEmpty) {
        _calculateLocalBMI();
      }
    } catch (_) {
      // Fallback defaults
      if (heightController.text.isEmpty) heightController.text = "175";
      if (weightController.text.isEmpty) weightController.text = "70";
      _calculateLocalBMI();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
        });
      }
    }
  }

  void _calculateLocalBMI() {
    final double h = double.tryParse(heightController.text.trim()) ?? 0.0;
    final double w = double.tryParse(weightController.text.trim()) ?? 0.0;

    if (h > 0 && w > 0) {
      final double hMeters = h / 100.0;
      final double val = w / (hMeters * hMeters);
      final double rounded = double.parse(val.toStringAsFixed(1));

      int zoneIdx = _findZoneIndex(rounded);

      setState(() {
        bmi = rounded;
        categoryName = _bmiZones[zoneIdx].title;
        selectedCategoryIndex = zoneIdx;
      });
    }
  }

  int _findZoneIndex(double b) {
    for (int i = 0; i < _bmiZones.length; i++) {
      if (b >= _bmiZones[i].minBmi && b <= _bmiZones[i].maxBmi) {
        return i;
      }
    }
    return _bmiZones.length - 1;
  }

  Future<void> _saveBmiRecord() async {
    final double h = double.tryParse(heightController.text.trim()) ?? 0.0;
    final double w = double.tryParse(weightController.text.trim()) ?? 0.0;

    if (h <= 0 || w <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter valid height and weight values."),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _calculateLocalBMI();

    if (widget.userId == null) {
      // Local addition
      final record = {
        "recordId": DateTime.now().millisecondsSinceEpoch,
        "height": h,
        "weight": w,
        "bmi": bmi,
        "category": categoryName,
        "healthScore": _computeHealthScore(bmi)['score'],
        "recordedAt": DateTime.now().toIso8601String(),
      };
      setState(() {
        _bmiHistory.insert(0, record);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Measurement logged successfully!"),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSavingRecord = true;
    });

    try {
      final saved = await ApiService.logBmiRecord(widget.userId!, h, w);
      if (saved != null) {
        final history = await ApiService.getBmiHistory(widget.userId!);
        if (!mounted) return;
        setState(() {
          _bmiHistory = history.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("BMI record saved to Health Dashboard!"),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to save: $e"),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingRecord = false;
        });
      }
    }
  }

  Future<void> _deleteHistoryItem(int recordId) async {
    try {
      if (widget.userId != null) {
        await ApiService.deleteBmiRecord(recordId);
      }
      setState(() {
        _bmiHistory.removeWhere((item) => item['recordId'] == recordId);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Record removed."),
          backgroundColor: Color(0xFF64748B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {}
  }

  // ==========================================
  // HEALTH SCORE ESTIMATION
  // ==========================================
  Map<String, dynamic> _computeHealthScore(double b) {
    if (b <= 0) return {"score": 0, "status": "N/A", "color": Colors.grey};

    int score = 50;
    if (b >= 21.0 && b <= 23.5) {
      score = 96;
    } else if ((b >= 20.0 && b < 21.0) || (b > 23.5 && b <= 24.9)) {
      score = 90;
    } else if (b >= 18.5 && b < 20.0) {
      score = 85;
    } else if (b >= 25.0 && b <= 26.9) {
      score = 80;
    } else if (b >= 17.0 && b < 18.5) {
      score = 72;
    } else if (b >= 27.0 && b <= 29.9) {
      score = 68;
    } else if (b >= 16.0 && b < 17.0) {
      score = 58;
    } else if (b >= 30.0 && b <= 34.9) {
      score = 54;
    } else {
      score = 42;
    }

    String status = "Good";
    Color color = const Color(0xFF10B981);

    if (score >= 92) {
      status = "Excellent";
      color = const Color(0xFF10B981);
    } else if (score >= 80) {
      status = "Very Good";
      color = const Color(0xFF38BDF8);
    } else if (score >= 65) {
      status = "Good";
      color = const Color(0xFF2DD4BF);
    } else if (score >= 50) {
      status = "Needs Improvement";
      color = const Color(0xFFF59E0B);
    } else {
      status = "High Priority Improvement";
      color = const Color(0xFFEF4444);
    }

    return {"score": score, "status": status, "color": color};
  }

  // ==========================================
  // IDEAL WEIGHT & CALORIES
  // ==========================================
  Map<String, dynamic> _computeWeightAndCalories() {
    final double h = double.tryParse(heightController.text.trim()) ?? 0.0;
    final double w = double.tryParse(weightController.text.trim()) ?? 0.0;

    if (h <= 0 || w <= 0) {
      return {
        "minWeight": 0.0,
        "maxWeight": 0.0,
        "diff": 0.0,
        "goal": "Enter valid height and weight",
        "maintenanceCal": 0,
        "weightLossCal": 0,
        "muscleGainCal": 0,
      };
    }

    final double hM = h / 100.0;
    final double minW = double.parse((18.5 * hM * hM).toStringAsFixed(1));
    final double maxW = double.parse((24.9 * hM * hM).toStringAsFixed(1));

    String goalText = "";
    double diff = 0.0;

    if (w < minW) {
      diff = double.parse((minW - w).toStringAsFixed(1));
      goalText = "Gain $diff kg";
    } else if (w > maxW) {
      diff = double.parse((w - maxW).toStringAsFixed(1));
      goalText = "Lose $diff kg";
    } else {
      diff = 0.0;
      goalText = "Maintain Healthy Range";
    }

    // Basal Metabolic Rate estimation (Mifflin-St Jeor formula)
    final double bmr = (10 * w) + (6.25 * h) - (5 * 21) + 5;
    final int maintenance = (bmr * 1.45).round(); // moderate activity factor
    final int weightLoss = maintenance - 450;
    final int muscleGain = maintenance + 350;

    return {
      "minWeight": minW,
      "maxWeight": maxW,
      "diff": diff,
      "goal": goalText,
      "maintenanceCal": maintenance,
      "weightLossCal": weightLoss,
      "muscleGainCal": muscleGain,
    };
  }

  // ==========================================
  // REUSABLE NEAT SECTION HEADER
  // ==========================================
  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    String? tag,
    Widget? trailing,
    Color accentColor = const Color(0xFF38BDF8),
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accentColor.withValues(alpha: 0.35)),
          ),
          child: Icon(icon, color: accentColor, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15.5,
                  letterSpacing: 0.3,
                ),
              ),
              if (tag != null && tag.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  tag,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeZone = selectedCategoryIndex >= 0 && selectedCategoryIndex < _bmiZones.length
        ? _bmiZones[selectedCategoryIndex]
        : (_bmiZones[_findZoneIndex(bmi > 0 ? bmi : 22.0)]);

    final healthScoreData = _computeHealthScore(bmi);
    final stats = _computeWeightAndCalories();

    // Weekly focus
    final weekOfYear = (int.tryParse(DateFormat('D').format(DateTime.now())) ?? 1) ~/ 7;
    final weeklyFocus = _weeklyFocusOptions[weekOfYear % _weeklyFocusOptions.length];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.monitor_heart, color: Color(0xFF38BDF8), size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              "Health Insights & BMI",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 19,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 1,
        actions: [
          IconButton(
            tooltip: "Reset & Refresh",
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _initializeUserData,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 1. Daily Motivation Ribbon
          _buildDailyMotivationCard(),
          const SizedBox(height: 16),

          // 2. Weekly Health Focus
          _buildWeeklyFocusCard(weeklyFocus),
          const SizedBox(height: 16),

          // 3. Measurement Input & Calculate Card
          _buildMeasurementInputCard(),
          const SizedBox(height: 16),

          // 4. Primary Health Insights KPI Grid
          _buildPrimaryInsightsCard(activeZone, healthScoreData, stats),
          const SizedBox(height: 16),

          // 5. Visual BMI Gauge / 10-Tier Scale
          _buildBmiMeterCard(activeZone),
          const SizedBox(height: 16),

          // 6. Intelligent Category Analysis (Zones 1-10)
          _buildIntelligentAnalysisCard(activeZone),
          const SizedBox(height: 16),

          // 7. Ideal Weight & Calorie Guidance
          _buildWeightAndCalorieGuidanceCard(stats),
          const SizedBox(height: 16),

          // 8. Goal-Based Personalized Recommendations
          _buildPersonalizedRecommendationsCard(),
          const SizedBox(height: 16),

          // 9. Health Score Breakdown
          _buildHealthScoreBreakdownCard(healthScoreData),
          const SizedBox(height: 16),

          // 10. BMI History & Trend Graph
          _buildBmiHistoryCard(),
          const SizedBox(height: 16),

          // 11. Medical Disclaimer
          _buildDisclaimerCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ==========================================
  // 1. DAILY MOTIVATION ENGINE
  // ==========================================
  Widget _buildDailyMotivationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF312E81), Color(0xFF1E1B4B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4338CA).withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.format_quote,
            title: "DAILY MOTIVATION",
            tag: "CampusFit Mindset",
            accentColor: const Color(0xFFA5B4FC),
            trailing: IconButton(
              tooltip: "Shuffle Inspiration",
              icon: const Icon(Icons.shuffle, color: Color(0xFFA5B4FC), size: 20),
              onPressed: () {
                setState(() {
                  _quoteIndex = (_quoteIndex + 1) % _dailyQuotes.length;
                });
              },
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
            ),
            child: Text(
              "\"${_dailyQuotes[_quoteIndex]}\"",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 2. WEEKLY HEALTH FOCUS
  // ==========================================
  Widget _buildWeeklyFocusCard(Map<String, String> focus) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.track_changes,
            title: "THIS WEEK'S HEALTH FOCUS",
            tag: focus['tag'] ?? "Habit Optimizer",
            accentColor: const Color(0xFF38BDF8),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  focus['title'] ?? "",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  focus['desc'] ?? "",
                  style: const TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 3. MEASUREMENT INPUT CARD
  // ==========================================
  Widget _buildMeasurementInputCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.straighten,
            title: "Biometric Input",
            tag: "Height & Weight Parameters",
            accentColor: const Color(0xFF38BDF8),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: heightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: "Height",
                    suffixText: "cm",
                    suffixStyle: const TextStyle(color: Color(0xFF94A3B8)),
                    labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    prefixIcon: const Icon(Icons.height, color: Color(0xFF38BDF8), size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF334155)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF334155)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF38BDF8)),
                    ),
                  ),
                  onChanged: (_) => _calculateLocalBMI(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: "Weight",
                    suffixText: "kg",
                    suffixStyle: const TextStyle(color: Color(0xFF94A3B8)),
                    labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    prefixIcon: const Icon(Icons.monitor_weight_outlined, color: Color(0xFF38BDF8), size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF334155)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF334155)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF38BDF8)),
                    ),
                  ),
                  onChanged: (_) => _calculateLocalBMI(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38BDF8),
                    foregroundColor: const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: _calculateLocalBMI,
                  icon: const Icon(Icons.calculate, size: 18),
                  label: const Text("Recalculate"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: _isSavingRecord ? null : _saveBmiRecord,
                  icon: _isSavingRecord
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.bookmark_add, size: 18),
                  label: Text(_isSavingRecord ? "Saving..." : "Log to History"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 4. PRIMARY HEALTH INSIGHTS DASHBOARD CARD
  // ==========================================
  Widget _buildPrimaryInsightsCard(
    BmiZone activeZone,
    Map<String, dynamic> healthScore,
    Map<String, dynamic> stats,
  ) {
    final double h = double.tryParse(heightController.text) ?? 0.0;
    final double w = double.tryParse(weightController.text) ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: activeZone.color.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: activeZone.color.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSectionHeader(
            icon: Icons.speed,
            title: "Health Scorecard",
            tag: "Real-Time Biometric Analysis",
            accentColor: activeZone.color,
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "BMI SCORE",
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          bmi > 0 ? bmi.toStringAsFixed(1) : "--",
                          style: TextStyle(
                            color: activeZone.color,
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "kg/m²",
                          style: TextStyle(color: activeZone.color.withValues(alpha: 0.8), fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: activeZone.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: activeZone.color),
                      ),
                      child: Text(
                        activeZone.title,
                        style: TextStyle(
                          color: activeZone.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Health Score Radial Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Column(
                  children: [
                    const Text(
                      "HEALTH SCORE",
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "${healthScore['score']}",
                          style: TextStyle(
                            color: healthScore['color'] as Color,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Text(
                          "/100",
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      healthScore['status'] as String,
                      style: TextStyle(
                        color: healthScore['color'] as Color,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          const Divider(color: Color(0xFF334155), height: 1),
          const SizedBox(height: 14),

          // Secondary Biometrics Row
          Row(
            children: [
              _buildMetricPill("Height", "${h.toStringAsFixed(0)} cm", Icons.height),
              _buildMetricPill("Weight", "${w.toStringAsFixed(1)} kg", Icons.scale),
              _buildMetricPill(
                "Healthy Range",
                "${stats['minWeight']} - ${stats['maxWeight']} kg",
                Icons.favorite_outline,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF38BDF8), size: 18),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 5. BMI METER / 10-ZONE GAUGE
  // ==========================================
  Widget _buildBmiMeterCard(BmiZone activeZone) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.linear_scale,
            title: "Visual BMI Gauge",
            tag: "Continuous 10-Tier Scale",
            accentColor: const Color(0xFF38BDF8),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: activeZone.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: activeZone.color.withValues(alpha: 0.4)),
              ),
              child: Text(
                "10 Health Zones",
                style: TextStyle(color: activeZone.color, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Tap any zone below to inspect clinical health considerations, actionable recommendations, and motivation.",
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
          ),
          const SizedBox(height: 16),

          // Custom Painted Gauge Bar
          SizedBox(
            height: 48,
            width: double.infinity,
            child: CustomPaint(
              painter: BmiGaugePainter(
                currentBmi: bmi,
                zones: _bmiZones,
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Horizontal scrollable zone selector pills
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _bmiZones.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final z = _bmiZones[i];
                final isSelected = selectedCategoryIndex == i;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCategoryIndex = i;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? z.color.withValues(alpha: 0.25) : const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? z.color : const Color(0xFF334155),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: z.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          z.title,
                          style: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 6. INTELLIGENT CATEGORY ANALYSIS CARD
  // ==========================================
  Widget _buildIntelligentAnalysisCard(BmiZone zone) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: zone.color.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.analytics_outlined,
            title: zone.title,
            tag: "Clinical Analysis • Range: ${zone.rangeLabel}",
            accentColor: zone.color,
          ),
          const SizedBox(height: 14),

          // Health Status
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF38BDF8), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    zone.healthStatus,
                    style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 12.5, height: 1.35),
                  ),
                ),
              ],
            ),
          ),

          // Potential Concerns (if applicable)
          if (zone.concerns.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              "Potential Concerns",
              style: TextStyle(
                color: Color(0xFFFCA5A5),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            ...zone.concerns.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        c,
                        style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Recommendations
          const SizedBox(height: 14),
          const Text(
            "Actionable Recommendations",
            style: TextStyle(
              color: Color(0xFF38BDF8),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          ...zone.recommendations.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      r,
                      style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Motivation Quote for this Zone
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: zone.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: zone.color.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.bolt, color: zone.color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "\"${zone.motivation}\"",
                    style: TextStyle(
                      color: zone.color,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 7. IDEAL WEIGHT & CALORIE GUIDANCE (OVERFLOW FIXED)
  // ==========================================
  Widget _buildWeightAndCalorieGuidanceCard(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.scale_rounded,
            title: "Ideal Weight Estimator & Calories",
            tag: "Metabolic Expenditure & Targets",
            accentColor: const Color(0xFF38BDF8),
          ),
          const SizedBox(height: 14),

          // Weight Delta Banner (Carefully constrained to prevent ANY overflow)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "SUGGESTED BODY WEIGHT GOAL",
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 3),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "${stats['goal']}",
                          style: const TextStyle(
                            color: Color(0xFF38BDF8),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "Target: ${stats['minWeight']} - ${stats['maxWeight']} kg",
                        style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Text(
            "Estimated Daily Calorie Targets (TDEE)",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),

          // 3 Calorie Cards (Maintenance, Weight Loss, Muscle Gain)
          Row(
            children: [
              _buildCalorieCard(
                "Maintenance",
                "${stats['maintenanceCal']} kcal",
                "Keep steady",
                const Color(0xFF38BDF8),
              ),
              const SizedBox(width: 8),
              _buildCalorieCard(
                "Weight Loss",
                "${stats['weightLossCal']} kcal",
                "-450 kcal deficit",
                const Color(0xFFF59E0B),
              ),
              const SizedBox(width: 8),
              _buildCalorieCard(
                "Muscle Gain",
                "${stats['muscleGainCal']} kcal",
                "+350 kcal surplus",
                const Color(0xFF10B981),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieCard(String title, String cals, String sub, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                cals,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                ),
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                sub,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 8. GOAL-BASED PERSONALIZED RECOMMENDATIONS
  // ==========================================
  Widget _buildPersonalizedRecommendationsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.flag_outlined,
            title: "Goal-Oriented Recommendations",
            tag: "Personalized Action Plan",
            accentColor: const Color(0xFFA855F7),
          ),
          const SizedBox(height: 12),

          // Goal selection chips
          Row(
            children: [
              _buildGoalChip("Weight Loss"),
              const SizedBox(width: 8),
              _buildGoalChip("Muscle Gain"),
              const SizedBox(width: 8),
              _buildGoalChip("General Fitness"),
            ],
          ),

          const SizedBox(height: 14),

          // Content according to goal
          ..._getRecommendationsForGoal(selectedGoal).map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.arrow_right, color: Color(0xFF38BDF8), size: 20),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12.5, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalChip(String goal) {
    final isSelected = selectedGoal.toLowerCase() == goal.toLowerCase();
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedGoal = goal;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF334155),
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                goal,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<String> _getRecommendationsForGoal(String goal) {
    if (goal.toLowerCase().contains("weight loss")) {
      return [
        "Prioritize 3-4 weekly sessions of cardiovascular training and HIIT.",
        "Eliminate liquid sugars and high-calorie processed beverages.",
        "Maintain a mild caloric deficit (-400 kcal) and track daily intake.",
        "Increase dietary fiber intake (oats, vegetables, chia seeds) to suppress hunger.",
      ];
    } else if (goal.toLowerCase().contains("muscle gain")) {
      return [
        "Consume 1.8-2.2g of protein per kg of body mass distributed over 3-4 meals.",
        "Emphasize progressive resistance training with progressive overload.",
        "Maintain a mild caloric surplus (+300 to +400 kcal) to support hypertrophy.",
        "Ensure at least 48 hours of recovery between the same muscle groups.",
      ];
    } else {
      return [
        "Balance your plate with equal portions of lean protein, complex carbs, and green veggies.",
        "Incorporate regular moderate exercise (150+ minutes weekly).",
        "Drink at least 2.5 liters of clean water throughout your academic day.",
        "Practice mindful stress management and sleep for 7-8 hours nightly.",
      ];
    }
  }

  // ==========================================
  // 9. HEALTH SCORE BREAKDOWN
  // ==========================================
  Widget _buildHealthScoreBreakdownCard(Map<String, dynamic> scoreData) {
    final int score = scoreData['score'] as int;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.shield_outlined,
            title: "Health Score Breakdown",
            tag: "Multi-Factor Quality Index",
            accentColor: const Color(0xFF10B981),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: (scoreData['color'] as Color).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: (scoreData['color'] as Color).withValues(alpha: 0.4)),
              ),
              child: Text(
                "$score / 100",
                style: TextStyle(
                  color: scoreData['color'] as Color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          _buildScoreBar(
            "BMI Optimization",
            bmi >= 20 && bmi <= 25 ? 38 : (bmi >= 18.5 && bmi < 27 ? 30 : 20),
            40,
            const Color(0xFF10B981),
          ),
          const SizedBox(height: 10),
          _buildScoreBar("Workout Completion", 22, 25, const Color(0xFF38BDF8)),
          const SizedBox(height: 10),
          _buildScoreBar("Nutrition & Hydration Tracking", 16, 20, const Color(0xFFA855F7)),
          const SizedBox(height: 10),
          _buildScoreBar("Active Academic Routine", 13, 15, const Color(0xFFF59E0B)),
        ],
      ),
    );
  }

  Widget _buildScoreBar(String label, int earned, int total, Color color) {
    final double pct = earned / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              "$earned / $total pts",
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: const Color(0xFF0F172A),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 10. BMI HISTORY & TREND CHART
  // ==========================================
  Widget _buildBmiHistoryCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.history,
            title: "BMI History & Trends",
            tag: "${_bmiHistory.length} Measurements Logged",
            accentColor: const Color(0xFF38BDF8),
            trailing: _isLoadingHistory
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF38BDF8)),
                  )
                : null,
          ),
          const SizedBox(height: 14),

          if (_bmiHistory.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              alignment: Alignment.center,
              child: const Text(
                "No previous records logged yet. Tap 'Log to History' above to begin tracking your biometric progress over time.",
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                textAlign: TextAlign.center,
              ),
            )
          else ...[
            // Trend Line Graph
            SizedBox(
              height: 140,
              width: double.infinity,
              child: CustomPaint(
                painter: BmiTrendPainter(history: _bmiHistory),
              ),
            ),
            const SizedBox(height: 16),

            // History Records List
            ..._bmiHistory.take(5).map((rec) {
              final id = (rec['recordId'] as num?)?.toInt() ?? 0;
              final b = (rec['bmi'] as num?)?.toDouble() ?? 0.0;
              final w = (rec['weight'] as num?)?.toDouble() ?? 0.0;
              final dateStr = rec['recordedAt']?.toString() ?? "";
              String formattedDate = "Recent";
              try {
                final parsed = DateTime.parse(dateStr);
                formattedDate = DateFormat('MMM dd, yyyy').format(parsed);
              } catch (_) {}

              final zoneIdx = _findZoneIndex(b);
              final zoneColor = _bmiZones[zoneIdx].color;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: zoneColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: Text(
                        formattedDate,
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "${w.toStringAsFixed(1)} kg",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.5),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: zoneColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "BMI ${b.toStringAsFixed(1)}",
                        style: TextStyle(color: zoneColor, fontWeight: FontWeight.bold, fontSize: 10.5),
                      ),
                    ),
                    if (id > 0) ...[
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () => _deleteHistoryItem(id),
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(Icons.delete_outline, color: Color(0xFF64748B), size: 16),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // 11. MEDICAL DISCLAIMER
  // ==========================================
  Widget _buildDisclaimerCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.health_and_safety, color: Color(0xFF38BDF8), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "IMPORTANT DISCLAIMER: This module provides educational health guidance, motivation, and fitness insights only. It is not a medical diagnosis or treatment system. Consult a healthcare professional before major dietary or physical training adjustments.",
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// DATA MODELS & PAINTERS
// ==========================================

class BmiZone {
  final int index;
  final String title;
  final String rangeLabel;
  final double minBmi;
  final double maxBmi;
  final Color color;
  final String healthStatus;
  final List<String> concerns;
  final List<String> recommendations;
  final String motivation;

  BmiZone({
    required this.index,
    required this.title,
    required this.rangeLabel,
    required this.minBmi,
    required this.maxBmi,
    required this.color,
    required this.healthStatus,
    required this.concerns,
    required this.recommendations,
    required this.motivation,
  });
}

class BmiGaugePainter extends CustomPainter {
  final double currentBmi;
  final List<BmiZone> zones;

  BmiGaugePainter({
    required this.currentBmi,
    required this.zones,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double barHeight = 12.0;
    final double barY = 8.0;
    final double totalWidth = size.width;

    // Draw the 10 zones proportionally along scale (range: 14 to 40)
    final double minScale = 14.0;
    final double maxScale = 40.0;
    final double scaleSpan = maxScale - minScale;

    final RRect clipRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, barY, totalWidth, barHeight),
      const Radius.circular(6),
    );
    canvas.save();
    canvas.clipRRect(clipRect);

    double currentX = 0.0;
    for (int i = 0; i < zones.length; i++) {
      final z = zones[i];
      double segMin = z.minBmi < minScale ? minScale : z.minBmi;
      double segMax = z.maxBmi > maxScale ? maxScale : z.maxBmi;
      if (segMax <= segMin) segMax = segMin + 1.0;

      double segWidth = ((segMax - segMin) / scaleSpan) * totalWidth;
      final Paint segPaint = Paint()..color = z.color;
      canvas.drawRect(Rect.fromLTWH(currentX, barY, segWidth, barHeight), segPaint);
      currentX += segWidth;
    }
    canvas.restore();

    // Draw current BMI pointer arrow
    if (currentBmi > 0) {
      double clampedBmi = currentBmi.clamp(minScale, maxScale);
      double pointerX = ((clampedBmi - minScale) / scaleSpan) * totalWidth;

      final Paint pointerPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      final Path trianglePath = Path();
      trianglePath.moveTo(pointerX, barY + barHeight + 2);
      trianglePath.lineTo(pointerX - 6, barY + barHeight + 12);
      trianglePath.lineTo(pointerX + 6, barY + barHeight + 12);
      trianglePath.close();
      canvas.drawPath(trianglePath, pointerPaint);

      // White outline circle on top of bar
      final Paint circlePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(Offset(pointerX, barY + (barHeight / 2)), 6, circlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant BmiGaugePainter oldDelegate) {
    return oldDelegate.currentBmi != currentBmi;
  }
}

class BmiTrendPainter extends CustomPainter {
  final List<Map<String, dynamic>> history;

  BmiTrendPainter({required this.history});

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty) return;

    final List<double> bmiPoints = history
        .map((e) => (e['bmi'] as num?)?.toDouble() ?? 22.0)
        .toList()
        .reversed
        .toList();

    double minVal = 16.0;
    double maxVal = 32.0;

    for (var b in bmiPoints) {
      if (b < minVal) minVal = b - 1;
      if (b > maxVal) maxVal = b + 1;
    }

    final double width = size.width;
    final double height = size.height;
    final double pad = 16.0;
    final double plotWidth = width - (pad * 2);
    final double plotHeight = height - (pad * 2);

    final Paint gridPaint = Paint()
      ..color = const Color(0xFF334155).withValues(alpha: 0.5)
      ..strokeWidth = 1.0;

    // Draw 3 reference horizontal gridlines
    canvas.drawLine(Offset(pad, pad), Offset(width - pad, pad), gridPaint);
    canvas.drawLine(Offset(pad, pad + plotHeight / 2), Offset(width - pad, pad + plotHeight / 2), gridPaint);
    canvas.drawLine(Offset(pad, height - pad), Offset(width - pad, height - pad), gridPaint);

    if (bmiPoints.length == 1) {
      // Single point
      final Offset center = Offset(width / 2, height / 2);
      final Paint dotPaint = Paint()..color = const Color(0xFF38BDF8);
      canvas.drawCircle(center, 5, dotPaint);
      return;
    }

    final double stepX = plotWidth / (bmiPoints.length - 1);
    final Path linePath = Path();
    final List<Offset> offsets = [];

    for (int i = 0; i < bmiPoints.length; i++) {
      final double x = pad + (i * stepX);
      final double normalized = (bmiPoints[i] - minVal) / (maxVal - minVal);
      final double y = height - pad - (normalized * plotHeight);
      offsets.add(Offset(x, y));
      if (i == 0) {
        linePath.moveTo(x, y);
      } else {
        linePath.lineTo(x, y);
      }
    }

    final Paint linePaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(linePath, linePaint);

    // Draw nodes
    final Paint dotPaint = Paint()..color = const Color(0xFF38BDF8);
    final Paint centerPaint = Paint()..color = const Color(0xFF0F172A);

    for (var off in offsets) {
      canvas.drawCircle(off, 4.5, dotPaint);
      canvas.drawCircle(off, 2.5, centerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant BmiTrendPainter oldDelegate) {
    return oldDelegate.history != history;
  }
}
