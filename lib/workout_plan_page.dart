import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'services/api_service.dart';
import 'academic_schedule_page.dart';
import 'study_plan_page.dart';
import 'profile_page.dart';

class WorkoutPlanPage extends StatefulWidget {
  final int userId;

  const WorkoutPlanPage({
    super.key,
    required this.userId,
  });

  @override
  State<WorkoutPlanPage> createState() => _WorkoutPlanPageState();
}

class _WorkoutPlanPageState extends State<WorkoutPlanPage> {
  bool _isLoading = true;
  bool _isGenerating = false;
  String? _errorMessage;
  String? _validationPrompt;

  Map<String, dynamic>? _todayWorkout;
  Map<String, dynamic>? _workoutHistory;

  // Active workout execution tracking
  bool _isWorkoutActive = false;
  final Set<String> _completedExercises = {};

  @override
  void initState() {
    super.initState();
    _loadWorkoutData();
  }

  Future<void> _loadWorkoutData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _validationPrompt = null;
    });

    try {
      final results = await Future.wait([
        ApiService.getTodayWorkout(widget.userId),
        ApiService.getWorkoutHistory(widget.userId),
      ]);

      final today = results[0];
      final history = results[1];

      if (!mounted) return;
      setState(() {
        _todayWorkout = today;
        _workoutHistory = history;
        _isLoading = false;
        if (today != null && today['status'] == 'COMPLETED') {
          _isWorkoutActive = false;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "Failed to load workout data: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _generateOrReplanWorkout() async {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _validationPrompt = null;
    });

    try {
      final result = await ApiService.generateWorkoutPlan(widget.userId);

      if (!mounted) return;

      if (result['success'] == true && result['data'] != null) {
        setState(() {
          _todayWorkout = result['data'];
          _completedExercises.clear();
          _isWorkoutActive = false;
        });

        // Refresh history as well
        final history = await ApiService.getWorkoutHistory(widget.userId);
        if (!mounted) return;
        setState(() {
          _workoutHistory = history;
        });

        final reason = _todayWorkout?['adjustmentReason'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(reason != null && reason.isNotEmpty
                ? reason
                : "Personalized workout plan generated successfully!"),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final err = result['error']?.toString() ?? "Failed to generate workout plan.";
        _handleValidationError(err);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "An unexpected error occurred: $e";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  void _handleValidationError(String err) {
    setState(() {
      _validationPrompt = err;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(err),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _markWorkoutCompleted() async {
    if (_todayWorkout == null || _todayWorkout!['workoutId'] == null) return;

    final workoutId = (_todayWorkout!['workoutId'] as num).toInt();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.emoji_events, color: Color(0xFFF59E0B)),
            SizedBox(width: 8),
            Text("Complete Workout?"),
          ],
        ),
        content: const Text(
          "Great job! Mark this workout as completed and update your fitness streak?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Not yet"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Yes, Completed!"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final success = await ApiService.markWorkoutCompleted(workoutId);
      if (success) {
        setState(() {
          if (_todayWorkout != null) {
            _todayWorkout!['status'] = 'COMPLETED';
          }
          _isWorkoutActive = false;
        });

        final history = await ApiService.getWorkoutHistory(widget.userId);
        if (mounted) {
          setState(() {
            _workoutHistory = history;
          });
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Workout marked as completed! Streak updated! 🔥"),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to update workout status."),
            backgroundColor: Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Map<String, dynamic>? _parseWorkoutDetails(dynamic rawDetails) {
    if (rawDetails == null) return null;
    if (rawDetails is Map<String, dynamic>) return rawDetails;
    if (rawDetails is String) {
      try {
        return jsonDecode(rawDetails) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  String _formatDateTime(dynamic timeVal) {
    if (timeVal == null) return "--:--";
    try {
      final dt = DateTime.parse(timeVal.toString());
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return timeVal.toString();
    }
  }

  int _countTotalExercises(Map<String, dynamic>? details) {
    if (details == null) return 0;
    int count = 0;
    if (details['warmup'] is List) count += (details['warmup'] as List).length;
    if (details['mainWorkout'] is List) count += (details['mainWorkout'] as List).length;
    if (details['cooldown'] is List) count += (details['cooldown'] as List).length;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.fitness_center, color: Color(0xFF38BDF8), size: 24),
            SizedBox(width: 8),
            Text(
              "Workout Plan",
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: "Refresh Workout & History",
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadWorkoutData,
          ),
          if (_todayWorkout != null)
            IconButton(
              tooltip: "Recalculate / Re-adapt Workout",
              icon: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.auto_awesome, color: Color(0xFFF59E0B)),
              onPressed: _isGenerating ? null : _generateOrReplanWorkout,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF38BDF8)),
            SizedBox(height: 16),
            Text(
              "Analyzing Academic Schedule & Free Slots...",
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadWorkoutData,
      color: const Color(0xFF38BDF8),
      backgroundColor: const Color(0xFF1E293B),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        children: [
          // 1. History & Streak Metric Cards
          _buildHistoryRibbon(),
          const SizedBox(height: 16),

          // 2. Validation / Error states if any
          if (_validationPrompt != null) ...[
            _buildValidationCard(_validationPrompt!),
            const SizedBox(height: 16),
          ],

          if (_errorMessage != null && _validationPrompt == null) ...[
            _buildErrorCard(_errorMessage!),
            const SizedBox(height: 16),
          ],

          // 3. Today's Workout Section or Prompt to Generate
          if (_todayWorkout == null)
            _buildEmptyTodayWorkout()
          else
            _buildTodayWorkoutDetails(),
        ],
      ),
    );
  }

  // ==========================================
  // HISTORY & STREAK RIBBON
  // ==========================================
  Widget _buildHistoryRibbon() {
    final streak = _workoutHistory?['workoutStreak'] ?? 0;
    final thisWeek = _workoutHistory?['completedThisWeek'] ?? 0;
    final totalCompleted = _workoutHistory?['totalWorkoutsCompleted'] ?? 0;
    final pct = _workoutHistory?['completionPercentage'] ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.insights, color: Color(0xFF38BDF8), size: 20),
              SizedBox(width: 8),
              Text(
                "Workout Consistency & History",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildStatItem("Streak", "$streak Days", Icons.local_fire_department, const Color(0xFFF97316)),
              _buildStatItem("This Week", "$thisWeek Done", Icons.calendar_today, const Color(0xFF38BDF8)),
              _buildStatItem("Total", "$totalCompleted Done", Icons.check_circle_outline, const Color(0xFF10B981)),
              _buildStatItem("Rate", "$pct%", Icons.pie_chart, const Color(0xFFA855F7)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // VALIDATION & ERROR HANDLERS
  // ==========================================
  Widget _buildValidationCard(String prompt) {
    IconData icon = Icons.info_outline;
    String buttonText = "Resolve";
    VoidCallback? onAction;

    if (prompt.contains("academic schedule")) {
      icon = Icons.calendar_month;
      buttonText = "Add Academic Schedule";
      onAction = () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AcademicSchedulePage(userId: widget.userId)),
        ).then((_) => _loadWorkoutData());
      };
    } else if (prompt.contains("study plan")) {
      icon = Icons.psychology;
      buttonText = "Generate Study Plan";
      onAction = () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => StudyPlanPage(userId: widget.userId)),
        ).then((_) => _loadWorkoutData());
      };
    } else if (prompt.contains("fitness profile")) {
      icon = Icons.person;
      buttonText = "Complete Fitness Profile";
      onAction = () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProfilePage(userId: widget.userId)),
        ).then((_) => _loadWorkoutData());
      };
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF451A1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFEF4444), size: 22),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Prerequisite Required",
                  style: TextStyle(
                    color: Color(0xFFFCA5A5),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            prompt,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          if (onAction != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: onAction,
                icon: const Icon(Icons.arrow_forward, size: 14),
                label: Text(buttonText),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF332020),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // EMPTY STATE / GENERATE CTA
  // ==========================================
  Widget _buildEmptyTodayWorkout() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.fitness_center,
              size: 48,
              color: Color(0xFF38BDF8),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "No Workout Generated for Today",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Our intelligent planner generates personalized workouts fitting purely into your remaining free time after classes and study sessions.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF38BDF8),
              foregroundColor: const Color(0xFF0F172A),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            onPressed: _isGenerating ? null : _generateOrReplanWorkout,
            icon: _isGenerating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F172A)),
                  )
                : const Icon(Icons.flash_on),
            label: Text(_isGenerating ? "Analyzing Schedules..." : "Generate Today's Workout Plan"),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TODAY'S WORKOUT VIEW
  // ==========================================
  Widget _buildTodayWorkoutDetails() {
    final workout = _todayWorkout!;
    final title = workout['workoutTitle'] ?? "Workout Routine";
    final goal = workout['workoutGoal'] ?? "General Fitness";
    final focus = workout['workoutFocus'] ?? "Full Body";
    final level = workout['fitnessLevel'] ?? "Beginner";
    final duration = workout['duration'] ?? 45;
    final calories = workout['caloriesEstimated'] ?? 250;
    final startTimeStr = _formatDateTime(workout['startTime']);
    final endTimeStr = _formatDateTime(workout['endTime']);
    final isCompleted = workout['status'] == 'COMPLETED';
    final adjustmentReason = workout['adjustmentReason'];

    final details = _parseWorkoutDetails(workout['workoutDetails']);
    final totalExercises = _countTotalExercises(details);
    final completedCount = _completedExercises.length;
    final progress = totalExercises > 0 ? (completedCount / totalExercises) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Adaptive Notice Banner if readjustment occurred
        if (adjustmentReason != null && adjustmentReason.toString().isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF854D0E), Color(0xFF713F12)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEAB308).withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFFFDE047), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Adaptive Schedule Adjustment",
                        style: TextStyle(
                          color: Color(0xFFFEF08A),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        adjustmentReason.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Main Header Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isCompleted ? const Color(0xFF10B981) : const Color(0xFF38BDF8).withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (isCompleted ? const Color(0xFF10B981) : const Color(0xFF38BDF8)).withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Today's Routine • $level Level",
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? const Color(0xFF10B981).withValues(alpha: 0.18)
                          : const Color(0xFFF59E0B).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isCompleted ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isCompleted ? Icons.check_circle : Icons.schedule,
                          color: isCompleted ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isCompleted ? "COMPLETED" : "PENDING",
                          style: TextStyle(
                            color: isCompleted ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Metrics Grid
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildMetricTile(Icons.flag, "Goal", goal, const Color(0xFF38BDF8)),
                        _buildMetricTile(Icons.category, "Focus", focus, const Color(0xFFA855F7)),
                      ],
                    ),
                    const Divider(color: Color(0xFF334155), height: 16),
                    Row(
                      children: [
                        _buildMetricTile(Icons.timer, "Duration", "$duration Mins", const Color(0xFFF59E0B)),
                        _buildMetricTile(Icons.local_fire_department, "Calories", "$calories kcal", const Color(0xFFEF4444)),
                      ],
                    ),
                    const Divider(color: Color(0xFF334155), height: 16),
                    Row(
                      children: [
                        _buildMetricTile(
                          Icons.access_time_filled,
                          "Allocated Slot",
                          "$startTimeStr - $endTimeStr",
                          const Color(0xFF10B981),
                          isFullWidth: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Action Buttons: Start Workout & Complete Workout
              Row(
                children: [
                  if (!isCompleted) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isWorkoutActive
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFF38BDF8),
                          foregroundColor: const Color(0xFF0F172A),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        onPressed: () {
                          setState(() {
                            _isWorkoutActive = !_isWorkoutActive;
                          });
                        },
                        icon: Icon(_isWorkoutActive ? Icons.pause : Icons.play_arrow),
                        label: Text(_isWorkoutActive ? "Tracking Active" : "Start Workout"),
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
                          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        onPressed: _markWorkoutCompleted,
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text("Finish Workout"),
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF10B981)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.emoji_events, color: Color(0xFF10B981), size: 20),
                            SizedBox(width: 8),
                            Text(
                              "Completed Today's Routine!",
                              style: TextStyle(
                                color: Color(0xFF10B981),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Active Session Progress Tracker
        if (_isWorkoutActive || completedCount > 0) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Session Progress",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      "Exercises Completed: $completedCount / $totalExercises",
                      style: const TextStyle(
                        color: Color(0xFF38BDF8),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: const Color(0xFF334155),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Exercise Sections: Warmup, Main, Cooldown
        _buildExerciseSections(details),

        const SizedBox(height: 24),

        // Adaptive Re-plan Action Card
        _buildReplanningCard(),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildMetricTile(IconData icon, String label, String value, Color color, {bool isFullWidth = false}) {
    return Expanded(
      flex: isFullWidth ? 2 : 1,
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // EXERCISE SECTIONS & EXPANDABLE CARDS
  // ==========================================
  Widget _buildExerciseSections(Map<String, dynamic>? details) {
    if (details == null) {
      return const Center(
        child: Text(
          "No exercise details available.",
          style: TextStyle(color: Color(0xFF94A3B8)),
        ),
      );
    }

    final warmup = (details['warmup'] as List?) ?? [];
    final main = (details['mainWorkout'] as List?) ?? [];
    final cooldown = (details['cooldown'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (warmup.isNotEmpty)
          _buildCategoryGroup(
            "1. Warmup (3–5 Minutes)",
            "Prepare your body and activate cardiovascular system",
            Icons.nature_people,
            const Color(0xFFF59E0B),
            warmup,
          ),
        const SizedBox(height: 16),
        if (main.isNotEmpty)
          _buildCategoryGroup(
            "2. Main Workout",
            "Tailored exercises matching your goal, focus & fitness level",
            Icons.fitness_center,
            const Color(0xFF38BDF8),
            main,
          ),
        const SizedBox(height: 16),
        if (cooldown.isNotEmpty)
          _buildCategoryGroup(
            "3. Cooldown (3–5 Minutes)",
            "Static stretching, parasympathetic recovery and lower heart rate",
            Icons.self_improvement,
            const Color(0xFF10B981),
            cooldown,
          ),
      ],
    );
  }

  Widget _buildCategoryGroup(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    List<dynamic> exercises,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...exercises.map((item) => _buildExpandableExerciseCard(item as Map<String, dynamic>)),
      ],
    );
  }

  Widget _buildExpandableExerciseCard(Map<String, dynamic> ex) {
    final name = ex['name']?.toString() ?? "Exercise";
    final sets = ex['sets']?.toString() ?? "-";
    final reps = ex['reps']?.toString() ?? "-";
    final howTo = ex['howToPerform']?.toString() ?? "";
    final benefits = ex['benefits']?.toString() ?? "";
    final mistakes = ex['commonMistakes']?.toString() ?? "";

    final isDone = _completedExercises.contains(name);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDone ? const Color(0xFF10B981).withValues(alpha: 0.6) : const Color(0xFF334155),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          collapsedIconColor: const Color(0xFF94A3B8),
          iconColor: const Color(0xFF38BDF8),
          leading: IconButton(
            tooltip: isDone ? "Mark as Pending" : "Mark Complete",
            icon: Icon(
              isDone ? Icons.check_circle : Icons.circle_outlined,
              color: isDone ? const Color(0xFF10B981) : const Color(0xFF64748B),
              size: 24,
            ),
            onPressed: () {
              setState(() {
                if (isDone) {
                  _completedExercises.remove(name);
                } else {
                  _completedExercises.add(name);
                }
              });
            },
          ),
          title: Text(
            name,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 15,
              decoration: isDone ? TextDecoration.lineThrough : null,
              decorationColor: const Color(0xFF10B981),
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "Sets: $sets",
                    style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA855F7).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "Reps: $reps",
                    style: const TextStyle(color: Color(0xFFA855F7), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // How to perform
                  if (howTo.isNotEmpty) ...[
                    const Row(
                      children: [
                        Icon(Icons.format_list_numbered, color: Color(0xFF38BDF8), size: 16),
                        SizedBox(width: 6),
                        Text(
                          "How To Perform",
                          style: TextStyle(
                            color: Color(0xFF38BDF8),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      howTo,
                      style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 12.5, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Benefits
                  if (benefits.isNotEmpty) ...[
                    const Row(
                      children: [
                        Icon(Icons.workspace_premium, color: Color(0xFF10B981), size: 16),
                        SizedBox(width: 6),
                        Text(
                          "Benefits",
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: benefits
                          .split(RegExp(r'[,|]'))
                          .map((b) => b.trim())
                          .where((b) => b.isNotEmpty)
                          .map((b) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  b,
                                  style: const TextStyle(color: Color(0xFF34D399), fontSize: 11),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Common Mistakes
                  if (mistakes.isNotEmpty) ...[
                    const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 16),
                        SizedBox(width: 6),
                        Text(
                          "Common Mistakes",
                          style: TextStyle(
                            color: Color(0xFFF59E0B),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      mistakes,
                      style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12.5, height: 1.3),
                    ),
                  ],

                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: isDone ? const Color(0xFF64748B) : const Color(0xFF10B981),
                      ),
                      onPressed: () {
                        setState(() {
                          if (isDone) {
                            _completedExercises.remove(name);
                          } else {
                            _completedExercises.add(name);
                          }
                        });
                      },
                      icon: Icon(isDone ? Icons.undo : Icons.check, size: 16),
                      label: Text(isDone ? "Undo Complete" : "Mark Exercise Complete"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // ADAPTIVE RE-PLANNING CARD
  // ==========================================
  Widget _buildReplanningCard() {
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
          const Row(
            children: [
              Icon(Icons.sync_alt, color: Color(0xFF38BDF8), size: 20),
              SizedBox(width: 8),
              Text(
                "Adaptive Replanning Engine",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Did your timetable or study workload change? Our engine recalculates remaining free slots without conflicting with your academic priority.",
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5, height: 1.35),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF38BDF8),
                side: const BorderSide(color: Color(0xFF38BDF8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _isGenerating ? null : _generateOrReplanWorkout,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF38BDF8)),
                    )
                  : const Icon(Icons.refresh, size: 18),
              label: Text(_isGenerating ? "Recalculating Plan..." : "Recalculate & Re-adapt Workout"),
            ),
          ),
        ],
      ),
    );
  }
}
