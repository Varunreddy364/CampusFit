import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'services/api_service.dart';
import 'nutrition_page.dart';
import 'bmi_page.dart';
import 'profile_page.dart';
import 'view_profile_page.dart';
import 'login_page.dart';
import 'feedback_page.dart';
import 'academic_schedule_page.dart';
import 'weekly_timetable_page.dart';
import 'academic_tasks_page.dart';
import 'study_plan_page.dart';
import 'workout_plan_page.dart';

class DashboardPage extends StatefulWidget {
  final int userId;
  final String userName;

  const DashboardPage({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // --- CAROUSEL STATE ---
  final PageController _carouselController = PageController();
  int _currentCarouselIndex = 0;
  Timer? _carouselTimer;

  // --- BOTTOM NAV STATE ---
  int _currentBottomNavIndex = 0;

  // --- DASHBOARD DATA STATE ---
  bool _isLoading = true;
  String? _errorMessage;

  // Metrics
  double _calorieGoal = 2000.0;
  double _caloriesConsumed = 0.0;

  int _completedWorkouts = 0;
  int _plannedWorkouts = 1;
  Map<String, dynamic>? _todayWorkout;

  int _completedTasks = 0;
  int _totalTasks = 0;

  double _waterLiters = 1.5;
  final double _waterTarget = 2.5;

  int _streakDays = 4;
  final List<bool> _weeklyActivity = [true, true, true, true, false, false, false];

  double? _latestBmi;
  String _bmiCategory = "Normal";
  double _latestWeight = 70.0;
  double _latestHeight = 175.0;

  List<dynamic> _todaysMeals = [];
  List<dynamic> _todaysSchedule = [];

  // Motivational Quotes for Carousel
  final List<Map<String, dynamic>> _carouselItems = [
    {
      "tag": "Today's Motivation",
      "quote": "Stay consistent.\nResults will follow.",
      "subtext": "You're doing great! 💪",
      "badge": "1/5",
      "gradient": const [Color(0xFF6A11CB), Color(0xFF2575FC)],
      "icon": Icons.local_fire_department_rounded,
    },
    {
      "tag": "Healthy Eating",
      "quote": "A healthy mind fuels\npeak performance.",
      "subtext": "Fuel your mind! 🥗",
      "badge": "2/5",
      "gradient": const [Color(0xFF0D9488), Color(0xFF10B981)],
      "icon": Icons.restaurant_rounded,
    },
    {
      "tag": "Academic Focus",
      "quote": "Progress is built one\nfocused study slot at a time.",
      "subtext": "Beat procrastination! 📚",
      "badge": "3/5",
      "gradient": const [Color(0xFF4338CA), Color(0xFF6366F1)],
      "icon": Icons.menu_book_rounded,
    },
    {
      "tag": "Daily Movement",
      "quote": "Small steps today.\nStronger habits tomorrow.",
      "subtext": "Every workout counts! 🏃",
      "badge": "4/5",
      "gradient": const [Color(0xFFEA580C), Color(0xFFF97316)],
      "icon": Icons.fitness_center_rounded,
    },
    {
      "tag": "Rest & Recovery",
      "quote": "Make time for rest,\neven on busy campus days.",
      "subtext": "Recharge to thrive! 🌙",
      "badge": "5/5",
      "gradient": const [Color(0xFF312E81), Color(0xFF4C1D95)],
      "icon": Icons.bedtime_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _startCarouselTimer();
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _carouselController.dispose();
    super.dispose();
  }

  void _startCarouselTimer() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (_carouselController.hasClients) {
        int nextIndex = (_currentCarouselIndex + 1) % _carouselItems.length;
        _carouselController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Fetch Profile for Calorie Targets & Weight
      final profile = await ApiService.getProfile(widget.userId);
      if (profile != null) {
        if (profile["dailyCalories"] != null && (profile["dailyCalories"] as num) > 0) {
          _calorieGoal = (profile["dailyCalories"] as num).toDouble();
        }
        if (profile["weight"] != null) {
          _latestWeight = (profile["weight"] as num).toDouble();
        }
        if (profile["height"] != null) {
          _latestHeight = (profile["height"] as num).toDouble();
        }
      }

      // 2. Fetch Today's Meals
      final meals = await ApiService.getTodaysMeals(widget.userId);
      _todaysMeals = meals;
      double consumed = 0;
      for (var m in meals) {
        if (m is Map && m["calories"] != null) {
          consumed += (m["calories"] as num).toDouble();
        }
      }
      _caloriesConsumed = consumed;

      // 3. Fetch Workout Plan & History
      final todayWorkout = await ApiService.getTodayWorkout(widget.userId);
      _todayWorkout = todayWorkout;
      if (todayWorkout != null) {
        _plannedWorkouts = 1;
        _completedWorkouts = (todayWorkout["isCompleted"] == true || todayWorkout["status"] == "COMPLETED") ? 1 : 0;
      } else {
        _plannedWorkouts = 1;
        _completedWorkouts = 0;
      }

      final workoutHistory = await ApiService.getWorkoutHistory(widget.userId);
      if (workoutHistory != null && workoutHistory["streak"] != null) {
        _streakDays = (workoutHistory["streak"] as num).toInt();
        if (_streakDays < 1 && (_completedWorkouts > 0 || _todaysMeals.isNotEmpty)) {
          _streakDays = 1;
        }
      }

      // 4. Fetch Academic Tasks
      final tasks = await ApiService.fetchAcademicTasks(widget.userId);
      _totalTasks = tasks.length;
      _completedTasks = tasks.where((t) => t is Map && (t["status"] == "COMPLETED" || t["completed"] == true)).length;

      // 5. Fetch Today's Academic Schedule
      final now = DateTime.now();
      final currentWeekday = DateFormat('EEEE').format(now).toUpperCase();
      final scheduleList = await ApiService.getAcademicSchedule(widget.userId);
      _todaysSchedule = scheduleList.where((item) {
        if (item is Map && item["dayOfWeek"] != null) {
          return item["dayOfWeek"].toString().toUpperCase() == currentWeekday;
        }
        return false;
      }).toList();

      // 6. Fetch Latest BMI
      final bmiRecord = await ApiService.getLatestBmi(widget.userId);
      if (bmiRecord != null) {
        if (bmiRecord["bmi"] != null) {
          _latestBmi = (bmiRecord["bmi"] as num).toDouble();
        }
        if (bmiRecord["category"] != null) {
          _bmiCategory = bmiRecord["category"].toString();
        }
        if (bmiRecord["weight"] != null) {
          _latestWeight = (bmiRecord["weight"] as num).toDouble();
        }
        if (bmiRecord["height"] != null) {
          _latestHeight = (bmiRecord["height"] as num).toDouble();
        }
      } else if (_latestHeight > 0 && _latestWeight > 0) {
        final heightM = _latestHeight / 100.0;
        _latestBmi = _latestWeight / (heightM * heightM);
        if (_latestBmi! < 18.5) {
          _bmiCategory = "Underweight";
        } else if (_latestBmi! < 25.0) {
          _bmiCategory = "Normal";
        } else if (_latestBmi! < 30.0) {
          _bmiCategory = "Overweight";
        } else {
          _bmiCategory = "Obese";
        }
      }

      // 7. Calculate weekly active dots
      _calculateWeeklyActivity();

    } catch (e) {
      _errorMessage = "Some dashboard data could not be refreshed.";
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _calculateWeeklyActivity() {
    final weekdayIndex = DateTime.now().weekday; // 1 = Mon ... 7 = Sun
    for (int i = 0; i < 7; i++) {
      if (i < weekdayIndex - 1) {
        _weeklyActivity[i] = true;
      } else if (i == weekdayIndex - 1) {
        _weeklyActivity[i] = (_todaysMeals.isNotEmpty || _completedWorkouts > 0 || _completedTasks > 0);
      } else {
        _weeklyActivity[i] = false;
      }
    }
  }

  Future<void> _navigateTo(Widget page) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
    _loadDashboardData();
  }

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning,";
    if (hour < 17) return "Good Afternoon,";
    return "Good Evening,";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        color: const Color(0xFF5E35B1),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Personalized Greeting Banner
              _buildGreetingHeader(),

              const SizedBox(height: 16),

              // 2. Motivational Carousel
              _buildMotivationCarousel(),

              const SizedBox(height: 20),

              // 3. Today's Progress Section
              _buildSectionHeader(
                title: "Today's Progress",
                actionLabel: "See Details",
                onActionTap: () => _navigateTo(NutritionPage(userId: widget.userId)),
              ),
              const SizedBox(height: 12),
              _buildProgressCardsRow(),

              const SizedBox(height: 22),

              // 4. Daily Challenges & Streak / Health Snapshot Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Daily Challenges
                    Expanded(
                      flex: 11,
                      child: _buildDailyChallengesCard(),
                    ),
                    const SizedBox(width: 12),
                    // Right Column: Streak & Health Snapshot
                    Expanded(
                      flex: 10,
                      child: Column(
                        children: [
                          _buildStreakCard(),
                          const SizedBox(height: 12),
                          _buildHealthSnapshotCard(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // 5. Quick Actions Section
              _buildSectionHeader(
                title: "Quick Actions",
                actionLabel: "Explore",
                onActionTap: () {},
              ),
              const SizedBox(height: 12),
              _buildQuickActionsGrid(),

              const SizedBox(height: 22),

              // 6. Today's Meals & Today's Schedule Side-by-Side
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildTodaysMealsCard()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTodaysScheduleCard()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ==========================================
  // APP BAR
  // ==========================================
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF5E35B1),
      elevation: 0,
      centerTitle: true,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: const Text(
        "CampusFit",
        style: TextStyle(
          color: Colors.white,
          fontSize: 21,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        // Notification Icon with Badge
        IconButton(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_rounded, color: Colors.white, size: 24),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5252),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          onPressed: _showNotificationsDialog,
        ),
        // User Profile Avatar
        Padding(
          padding: const EdgeInsets.only(right: 14, left: 4),
          child: GestureDetector(
            onTap: () => _navigateTo(ViewProfilePage(userId: widget.userId)),
            child: CircleAvatar(
              radius: 17,
              backgroundColor: Colors.white.withOpacity(0.25),
              child: Text(
                widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : "U",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 1. GREETING HEADER
  // ==========================================
  Widget _buildGreetingHeader() {
    final dateStr = DateFormat('EEE, d MMM yyyy').format(DateTime.now());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5E35B1), Color(0xFF3949AB)],
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTimeGreeting(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${widget.userName} 👋",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              // Date Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.28)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 13, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "“Small steps every day lead to big results.”",
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
              fontStyle: FontStyle.italic,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 2. MOTIVATIONAL CAROUSEL
  // ==========================================
  Widget _buildMotivationCarousel() {
    return Column(
      children: [
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _carouselController,
            itemCount: _carouselItems.length,
            onPageChanged: (index) {
              setState(() => _currentCarouselIndex = index);
            },
            itemBuilder: (context, index) {
              final item = _carouselItems[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: item["gradient"] as List<Color>,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: (item["gradient"][0] as Color).withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Background decorative motif
                      Positioned(
                        right: -10,
                        bottom: -15,
                        child: Icon(
                          item["icon"] as IconData,
                          size: 110,
                          color: Colors.white.withOpacity(0.14),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 3,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                item["tag"] as String,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item["quote"] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item["subtext"] as String,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      // Slide badge (e.g. 1/5)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            item["badge"] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        // Dots indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_carouselItems.length, (index) {
            final isActive = _currentCarouselIndex == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF5E35B1) : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ==========================================
  // 3. TODAY'S PROGRESS OVERVIEW
  // ==========================================
  Widget _buildProgressCardsRow() {
    final calorieRatio = (_calorieGoal > 0) ? (_caloriesConsumed / _calorieGoal).clamp(0.0, 1.0) : 0.0;
    final workoutRatio = (_plannedWorkouts > 0) ? (_completedWorkouts / _plannedWorkouts).clamp(0.0, 1.0) : 0.0;
    final taskRatio = (_totalTasks > 0) ? (_completedTasks / _totalTasks).clamp(0.0, 1.0) : 0.0;
    final waterRatio = (_waterTarget > 0) ? (_waterLiters / _waterTarget).clamp(0.0, 1.0) : 0.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // 1. Calories Card
          _buildProgressCard(
            title: "Calories",
            metricValue: "${_caloriesConsumed.toInt()} / ${_calorieGoal.toInt()} kcal",
            ratio: calorieRatio,
            percentLabel: "${(calorieRatio * 100).toInt()}%",
            color: const Color(0xFF00C853),
            bgColor: const Color(0xFFE8F5E9),
            icon: Icons.local_fire_department_rounded,
            onTap: () => _navigateTo(NutritionPage(userId: widget.userId)),
          ),
          const SizedBox(width: 10),

          // 2. Workout Card
          _buildProgressCard(
            title: "Workout",
            metricValue: "$_completedWorkouts / $_plannedWorkouts completed",
            ratio: workoutRatio,
            percentLabel: "${(workoutRatio * 100).toInt()}%",
            color: const Color(0xFFAB47BC),
            bgColor: const Color(0xFFF3E5F5),
            icon: Icons.fitness_center_rounded,
            onTap: () => _navigateTo(WorkoutPlanPage(userId: widget.userId)),
          ),
          const SizedBox(width: 10),

          // 3. Study Tasks Card
          _buildProgressCard(
            title: "Study Tasks",
            metricValue: "$_completedTasks / $_totalTasks completed",
            ratio: taskRatio,
            percentLabel: "${(taskRatio * 100).toInt()}%",
            color: const Color(0xFF29B6F6),
            bgColor: const Color(0xFFE1F5FE),
            icon: Icons.menu_book_rounded,
            onTap: () => _navigateTo(AcademicTasksPage(userId: widget.userId)),
          ),
          const SizedBox(width: 10),

          // 4. Water Intake Card
          _buildProgressCard(
            title: "Water Intake",
            metricValue: "${_waterLiters.toStringAsFixed(1)} / $_waterTarget L",
            ratio: waterRatio,
            percentLabel: "${(waterRatio * 100).toInt()}%",
            color: const Color(0xFFFF7043),
            bgColor: const Color(0xFFFFF3E0),
            icon: Icons.water_drop_rounded,
            onTap: _showWaterTrackerDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard({
    required String title,
    required String metricValue,
    required double ratio,
    required String percentLabel,
    required Color color,
    required Color bgColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 132,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon in colored circle
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1B4B),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              metricValue,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            // Progress bar & percentage
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 5,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  percentLabel,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 4. DAILY CHALLENGES & STREAK / HEALTH GRID
  // ==========================================
  Widget _buildDailyChallengesCard() {
    final bool workoutDone = _completedWorkouts > 0;
    final bool mealsLogged = _todaysMeals.length >= 3;
    final bool tasksDone = _completedTasks >= 2;
    final bool waterGoal = _waterLiters >= _waterTarget;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Daily Challenges",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1B4B),
                ),
              ),
              GestureColorText(
                label: "See All →",
                onTap: () => _navigateTo(WorkoutPlanPage(userId: widget.userId)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildChallengeRow(
            icon: Icons.directions_run_rounded,
            iconBg: const Color(0xFFFFF3E0),
            iconColor: const Color(0xFFF57C00),
            title: "Complete 20m exercise",
            isDone: workoutDone,
            onTap: () => _navigateTo(WorkoutPlanPage(userId: widget.userId)),
          ),
          const Divider(height: 14, thickness: 0.5),
          _buildChallengeRow(
            icon: Icons.restaurant_menu_rounded,
            iconBg: const Color(0xFFE8F5E9),
            iconColor: const Color(0xFF43A047),
            title: "Log at least 3 meals",
            isDone: mealsLogged,
            onTap: () => _navigateTo(NutritionPage(userId: widget.userId)),
          ),
          const Divider(height: 14, thickness: 0.5),
          _buildChallengeRow(
            icon: Icons.menu_book_rounded,
            iconBg: const Color(0xFFE1F5FE),
            iconColor: const Color(0xFF039BE5),
            title: "Complete 2 study tasks",
            isDone: tasksDone,
            onTap: () => _navigateTo(AcademicTasksPage(userId: widget.userId)),
          ),
          const Divider(height: 14, thickness: 0.5),
          _buildChallengeRow(
            icon: Icons.water_drop_rounded,
            iconBg: const Color(0xFFEDE7F6),
            iconColor: const Color(0xFF5E35B1),
            title: "Drink 2.5 L of water",
            isDone: waterGoal,
            onTap: _showWaterTrackerDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required bool isDone,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 14, color: iconColor),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDone ? Colors.grey.shade500 : const Color(0xFF1E1B4B),
                  decoration: isDone ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              size: 17,
              color: isDone ? const Color(0xFF00C853) : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  // --- STREAK CARD ---
  Widget _buildStreakCard() {
    final days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEDE8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  size: 20,
                  color: Color(0xFFFF5722),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "$_streakDays",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E1B4B),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        "Days",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
                      ),
                    ],
                  ),
                  const Text(
                    "Keep going!",
                    style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Weekday active dots
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final active = _weeklyActivity[i];
              return Column(
                children: [
                  Icon(
                    active ? Icons.check_circle_rounded : Icons.circle_outlined,
                    size: 14,
                    color: active ? const Color(0xFF00C853) : Colors.grey.shade300,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    days[i],
                    style: TextStyle(fontSize: 8, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  // --- HEALTH SNAPSHOT CARD ---
  Widget _buildHealthSnapshotCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Health Snapshot",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1B4B),
                ),
              ),
              GestureColorText(
                label: "View →",
                onTap: () => _navigateTo(BMIPage(userId: widget.userId)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // BMI
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F8E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      const Text("BMI", style: TextStyle(fontSize: 9, color: Colors.black54)),
                      Text(
                        _latestBmi != null ? _latestBmi!.toStringAsFixed(1) : "--",
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                      ),
                      Text(
                        _bmiCategory,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 8, color: Color(0xFF388E3C), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Weight
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E5F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      const Text("Weight", style: TextStyle(fontSize: 9, color: Colors.black54)),
                      Text(
                        "${_latestWeight.toInt()} kg",
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF6A1B9A)),
                      ),
                      const Text("Recorded", style: TextStyle(fontSize: 8, color: Color(0xFF7B1FA2), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Height
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1F5FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      const Text("Height", style: TextStyle(fontSize: 9, color: Colors.black54)),
                      Text(
                        "${_latestHeight.toInt()} cm",
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0277BD)),
                      ),
                      const Text("Profile", style: TextStyle(fontSize: 8, color: Color(0xFF0288D1), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 5. QUICK ACTIONS GRID
  // ==========================================
  Widget _buildQuickActionsGrid() {
    final actions = [
      {
        "title": "Log a Meal",
        "icon": Icons.restaurant_rounded,
        "color": const Color(0xFFE91E63),
        "bg": const Color(0xFFFFF0F3),
        "page": NutritionPage(userId: widget.userId),
      },
      {
        "title": "Workout Plan",
        "icon": Icons.fitness_center_rounded,
        "color": const Color(0xFF8E24AA),
        "bg": const Color(0xFFF3E8FF),
        "page": WorkoutPlanPage(userId: widget.userId),
      },
      {
        "title": "Study Plan",
        "icon": Icons.psychology_rounded,
        "color": const Color(0xFF0288D1),
        "bg": const Color(0xFFE0F2FE),
        "page": StudyPlanPage(userId: widget.userId),
      },
      {
        "title": "Academic Schedule",
        "icon": Icons.calendar_month_rounded,
        "color": const Color(0xFFF57C00),
        "bg": const Color(0xFFFEF3C7),
        "page": AcademicSchedulePage(userId: widget.userId),
      },
      {
        "title": "View Profile",
        "icon": Icons.person_rounded,
        "color": const Color(0xFF00897B),
        "bg": const Color(0xFFECFDF5),
        "page": ViewProfilePage(userId: widget.userId),
      },
      {
        "title": "Health & BMI",
        "icon": Icons.monitor_heart_rounded,
        "color": const Color(0xFFE53935),
        "bg": const Color(0xFFFFE4E6),
        "page": BMIPage(userId: widget.userId),
      },
      {
        "title": "Academic Tasks",
        "icon": Icons.task_alt_rounded,
        "color": const Color(0xFF5E35B1),
        "bg": const Color(0xFFEDE9FE),
        "page": AcademicTasksPage(userId: widget.userId),
      },
      {
        "title": "Feedback",
        "icon": Icons.star_rounded,
        "color": const Color(0xFF1E88E5),
        "bg": const Color(0xFFE0F2FE),
        "page": FeedbackPage(userId: widget.userId),
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: actions.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.88,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemBuilder: (context, index) {
          final a = actions[index];
          return InkWell(
            onTap: () => _navigateTo(a["page"] as Widget),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: a["bg"] as Color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: (a["color"] as Color).withOpacity(0.12)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(a["icon"] as IconData, size: 22, color: a["color"] as Color),
                  const SizedBox(height: 6),
                  Text(
                    a["title"] as String,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: a["color"] as Color,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // 6. TODAY'S MEALS & SCHEDULE SIDE BY SIDE
  // ==========================================
  Widget _buildTodaysMealsCard() {
    final hasMeals = _todaysMeals.isNotEmpty;
    final Map<String, dynamic>? latestMeal = hasMeals ? (_todaysMeals.last as Map<String, dynamic>) : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Today's Meals",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1B4B),
                ),
              ),
              GestureColorText(
                label: "See All →",
                onTap: () => _navigateTo(NutritionPage(userId: widget.userId)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (hasMeals && latestMeal != null) ...[
            Row(
              children: [
                // Food Bowl container
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text("🥗", style: TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        latestMeal["mealType"] ?? "Meal",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E1B4B),
                        ),
                      ),
                      Text(
                        latestMeal["foodName"] ?? "Food item",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "${(latestMeal["calories"] as num?)?.toInt() ?? 0} kcal",
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE65100),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "P: ${(latestMeal["protein"] as num?)?.toInt() ?? 0}g  C: ${(latestMeal["carbs"] as num?)?.toInt() ?? 0}g  F: ${(latestMeal["fat"] as num?)?.toInt() ?? 0}g",
              style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w600),
            ),
          ] else ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  children: [
                    const Text("🥣", style: TextStyle(fontSize: 26)),
                    const SizedBox(height: 4),
                    const Text(
                      "No meals logged yet",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => _navigateTo(NutritionPage(userId: widget.userId)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE7F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "+ Log Meal",
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF5E35B1)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTodaysScheduleCard() {
    final hasClasses = _todaysSchedule.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Today's Schedule",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1B4B),
                ),
              ),
              GestureColorText(
                label: "See All →",
                onTap: () => _navigateTo(WeeklyTimetablePage(userId: widget.userId)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (hasClasses) ...[
            ..._todaysSchedule.take(2).map((item) {
              final subject = item["subject"] ?? "Class";
              final startTime = item["startTime"] ?? "09:00";
              final location = item["location"] ?? "Campus";
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      startTime,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      margin: const EdgeInsets.only(top: 3),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF5E35B1),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B)),
                          ),
                          Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 9, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ] else ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  children: [
                    const Text("🎉", style: TextStyle(fontSize: 26)),
                    const SizedBox(height: 4),
                    const Text(
                      "No classes today!",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => _navigateTo(WeeklyTimetablePage(userId: widget.userId)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "View Week",
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // SECTION HEADER HELPER
  // ==========================================
  Widget _buildSectionHeader({
    required String title,
    required String actionLabel,
    required VoidCallback onActionTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E1B4B),
              letterSpacing: -0.3,
            ),
          ),
          GestureColorText(
            label: "$actionLabel →",
            onTap: onActionTap,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // WATER TRACKER DIALOG
  // ==========================================
  void _showWaterTrackerDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Track Water Intake 💧",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "${_waterLiters.toStringAsFixed(1)} / $_waterTarget L",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0288D1),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text("Optimal hydration enhances focus and workout recovery!"),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE1F5FE),
                          foregroundColor: const Color(0xFF0288D1),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text("+250 ml"),
                        onPressed: () {
                          setState(() {
                            _waterLiters = (_waterLiters + 0.25).clamp(0.0, 5.0);
                          });
                          setModalState(() {});
                        },
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0288D1),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text("+500 ml"),
                        onPressed: () {
                          setState(() {
                            _waterLiters = (_waterLiters + 0.5).clamp(0.0, 5.0);
                          });
                          setModalState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showNotificationsDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.notifications_active_rounded, color: Color(0xFF5E35B1)),
                  SizedBox(width: 8),
                  Text(
                    "CampusFit Updates",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildNotificationItem(
                title: "Hydration Reminder",
                body: "Drink a glass of water before your next academic study block.",
                time: "10m ago",
              ),
              const Divider(height: 20),
              _buildNotificationItem(
                title: "Workout Recommendation",
                body: "Evening slots between 4:00 PM and 7:00 PM are free for today's routine.",
                time: "1h ago",
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationItem({
    required String title,
    required String body,
    required String time,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFF5E35B1),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B)),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  // ==========================================
  // BOTTOM NAVIGATION BAR
  // ==========================================
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentBottomNavIndex,
        onTap: (index) {
          setState(() => _currentBottomNavIndex = index);
          switch (index) {
            case 0:
              // Home - Already here
              break;
            case 1:
              _navigateTo(WeeklyTimetablePage(userId: widget.userId));
              break;
            case 2:
              _navigateTo(WorkoutPlanPage(userId: widget.userId));
              break;
            case 3:
              _navigateTo(NutritionPage(userId: widget.userId));
              break;
            case 4:
              _navigateTo(BMIPage(userId: widget.userId));
              break;
            case 5:
              _navigateTo(ViewProfilePage(userId: widget.userId));
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF5E35B1),
        unselectedItemColor: Colors.grey.shade500,
        selectedFontSize: 11,
        unselectedFontSize: 10,
        backgroundColor: Colors.white,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_rounded),
            label: "Planner",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center_rounded),
            label: "Fitness",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_rounded),
            label: "Nutrition",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            label: "Analytics",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: "Profile",
          ),
        ],
      ),
    );
  }

  // ==========================================
  // DRAWER
  // ==========================================
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF5E35B1), Color(0xFF3949AB)],
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : "U",
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5E35B1),
                ),
              ),
            ),
            accountName: Text(
              widget.userName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            accountEmail: const Text("CampusFit Student Member"),
          ),

          // --- GENERAL ---
          ListTile(
            leading: const Icon(Icons.home_rounded, color: Color(0xFF5E35B1)),
            title: const Text("Dashboard"),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.person_rounded),
            title: const Text("Profile Settings"),
            onTap: () {
              Navigator.pop(context);
              _navigateTo(ProfilePage(userId: widget.userId));
            },
          ),
          ListTile(
            leading: const Icon(Icons.visibility_rounded),
            title: const Text("View Profile"),
            onTap: () {
              Navigator.pop(context);
              _navigateTo(ViewProfilePage(userId: widget.userId));
            },
          ),

          const Divider(height: 20, thickness: 1),
          _buildDrawerSectionHeader("ACADEMIC PLANNING"),

          ListTile(
            leading: const Icon(Icons.table_chart_rounded),
            title: const Text("Weekly Timetable"),
            onTap: () {
              Navigator.pop(context);
              _navigateTo(WeeklyTimetablePage(userId: widget.userId));
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month_rounded),
            title: const Text("Academic Schedule"),
            onTap: () {
              Navigator.pop(context);
              _navigateTo(AcademicSchedulePage(userId: widget.userId));
            },
          ),
          ListTile(
            leading: const Icon(Icons.task_alt_rounded),
            title: const Text("Academic Tasks"),
            onTap: () {
              Navigator.pop(context);
              _navigateTo(AcademicTasksPage(userId: widget.userId));
            },
          ),
          ListTile(
            leading: const Icon(Icons.psychology_rounded),
            title: const Text("Study Plan"),
            onTap: () {
              Navigator.pop(context);
              _navigateTo(StudyPlanPage(userId: widget.userId));
            },
          ),

          const Divider(height: 20, thickness: 1),
          _buildDrawerSectionHeader("FITNESS & WELLNESS"),

          ListTile(
            leading: const Icon(Icons.fitness_center_rounded),
            title: const Text("Workout Plan"),
            onTap: () {
              Navigator.pop(context);
              _navigateTo(WorkoutPlanPage(userId: widget.userId));
            },
          ),
          ListTile(
            leading: const Icon(Icons.restaurant_rounded),
            title: const Text("Nutrition Tracker"),
            onTap: () {
              Navigator.pop(context);
              _navigateTo(NutritionPage(userId: widget.userId));
            },
          ),
          ListTile(
            leading: const Icon(Icons.monitor_heart_rounded),
            title: const Text("Health & BMI"),
            onTap: () {
              Navigator.pop(context);
              _navigateTo(BMIPage(userId: widget.userId));
            },
          ),

          const Divider(height: 20, thickness: 1),
          _buildDrawerSectionHeader("ACCOUNT & FEEDBACK"),

          ListTile(
            leading: const Icon(Icons.feedback_rounded),
            title: const Text("Feedback Experience"),
            onTap: () {
              Navigator.pop(context);
              _navigateTo(FeedbackPage(userId: widget.userId));
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text("Logout", style: TextStyle(color: Colors.redAccent)),
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => LoginPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: Colors.grey.shade500,
        ),
      ),
    );
  }
}

// Simple helper widget for clickable colored text like "See All →"
class GestureColorText extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const GestureColorText({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5E35B1),
          ),
        ),
      ),
    );
  }
}
