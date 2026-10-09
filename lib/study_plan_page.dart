import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'services/api_service.dart';

class StudyPlanPage extends StatefulWidget {
  final int userId;

  const StudyPlanPage({
    super.key,
    required this.userId,
  });

  @override
  State<StudyPlanPage> createState() => _StudyPlanPageState();
}

class _StudyPlanPageState extends State<StudyPlanPage> {
  bool _isLoading = true;
  bool _isGenerating = false;
  String? _errorMessage;
  List<dynamic> _studyPlans = [];

  // Deterministic color palette for distinct subjects/tasks
  static final List<Color> _palette = [
    const Color(0xFF3B82F6), // Blue
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFF10B981), // Emerald
    const Color(0xFFF59E0B), // Amber
    const Color(0xFF06B6D4), // Cyan
    const Color(0xFFEC4899), // Pink
    const Color(0xFF6366F1), // Indigo
    const Color(0xFFF97316), // Orange
  ];

  @override
  void initState() {
    super.initState();
    _loadStudyPlans();
  }

  Future<void> _loadStudyPlans() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await ApiService.fetchStudyPlans(widget.userId);
      if (!mounted) return;
      setState(() {
        _studyPlans = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "Failed to load study plan: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _generatePlan() async {
    setState(() {
      _isGenerating = true;
    });

    final result = await ApiService.generateStudyPlanForUser(widget.userId);
    if (!mounted) return;

    setState(() {
      _isGenerating = false;
    });

    if (result['success'] == true) {
      final List<dynamic> generated = result['data'] is List ? result['data'] : [];
      setState(() {
        _studyPlans = generated;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(generated.isEmpty
              ? "No pending tasks or free slots found to schedule."
              : "Successfully generated ${generated.length} study sessions!"),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final err = result['error'] ?? "Failed to generate plan";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err.toString()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _togglePlanStatus(Map<String, dynamic> plan) async {
    final currentStatus = (plan['status'] ?? 'PENDING').toString().toUpperCase();
    final title = (plan['title'] ?? '').toString().toLowerCase();
    if (currentStatus == 'BREAK' || title.startsWith('break')) {
      return; // Breaks are restorative intervals and cannot be marked as completed tasks
    }
    final id = plan['planId'] ?? plan['id'] ?? 0;
    final newStatus = currentStatus == 'COMPLETED' ? 'PENDING' : 'COMPLETED';

    bool success;
    if (newStatus == 'COMPLETED') {
      success = await ApiService.markStudyPlanCompleted(id as int);
    } else {
      success = await ApiService.toggleStudyPlanStatus(id as int, newStatus);
    }

    if (!mounted) return;

    if (success) {
      setState(() {
        plan['status'] = newStatus;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus == 'COMPLETED'
              ? "Completed study session: ${plan['title']}"
              : "Reopened study session: ${plan['title']}"),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to update status"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteSession(int planId, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Remove Session"),
        content: Text("Remove '$title' from your study plan?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Remove"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await ApiService.deleteStudyPlanItem(planId);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Removed '$title'"),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadStudyPlans();
    }
  }

  Color _getColorForTitle(String title) {
    if (title.isEmpty) return _palette[0];
    int hash = 0;
    final normalized = title.trim().toLowerCase();
    for (int i = 0; i < normalized.length; i++) {
      hash = normalized.codeUnitAt(i) + ((hash << 5) - hash);
    }
    final index = hash.abs() % _palette.length;
    return _palette[index];
  }

  // Groups sessions by Date (e.g., "2026-10-12")
  Map<String, List<dynamic>> _groupSessionsByDate() {
    final Map<String, List<dynamic>> grouped = {};
    for (final s in _studyPlans) {
      final startRaw = s['startTime'];
      String dateKey = 'Upcoming';
      if (startRaw != null) {
        try {
          final dt = DateTime.parse(startRaw.toString());
          dateKey = DateFormat('yyyy-MM-dd').format(dt);
        } catch (_) {}
      }
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(s);
    }

    // Sort each day's sessions by start time
    for (final key in grouped.keys) {
      grouped[key]!.sort((a, b) {
        final startA = (a['startTime'] ?? '').toString();
        final startB = (b['startTime'] ?? '').toString();
        return startA.compareTo(startB);
      });
    }

    return grouped;
  }

  String _formatDateHeader(String dateKey) {
    try {
      final dt = DateTime.parse(dateKey);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final sessionDate = DateTime(dt.year, dt.month, dt.day);
      final diff = sessionDate.difference(today).inDays;

      if (diff == 0) {
        return "Today • ${DateFormat('EEEE, MMM d').format(dt)}";
      } else if (diff == 1) {
        return "Tomorrow • ${DateFormat('EEEE, MMM d').format(dt)}";
      } else {
        return DateFormat('EEEE, MMM d').format(dt);
      }
    } catch (_) {
      return dateKey;
    }
  }

  String _formatTimeSlot(dynamic startVal, dynamic endVal) {
    try {
      final s = DateTime.parse(startVal.toString());
      final e = DateTime.parse(endVal.toString());
      final startFmt = DateFormat('hh:mm a').format(s);
      final endFmt = DateFormat('hh:mm a').format(e);
      return "$startFmt - $endFmt";
    } catch (_) {
      return "$startVal - $endVal";
    }
  }

  String _formatDuration(dynamic startVal, dynamic endVal) {
    try {
      final s = DateTime.parse(startVal.toString());
      final e = DateTime.parse(endVal.toString());
      final mins = e.difference(s).inMinutes;
      if (mins >= 60) {
        final hours = (mins / 60.0).toStringAsFixed(1).replaceAll('.0', '');
        return "$hours hr session";
      }
      return "$mins min session";
    } catch (_) {
      return "1 hr session";
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupedSessions = _groupSessionsByDate();
    final academicTasks = _studyPlans.where((p) {
      final st = (p['status'] ?? '').toString().toUpperCase();
      final ti = (p['title'] ?? '').toString().toLowerCase();
      return st != 'BREAK' && !ti.startsWith('break');
    }).toList();
    final completedCount = academicTasks
        .where((p) => (p['status'] ?? '').toString().toUpperCase() == 'COMPLETED')
        .length;
    final totalCount = academicTasks.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          "Study Plan",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh Study Plan",
            onPressed: _loadStudyPlans,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 54, color: Colors.redAccent),
                        const SizedBox(height: 14),
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadStudyPlans,
                          child: const Text("Retry"),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: Colors.deepPurple,
                  onRefresh: _loadStudyPlans,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                    children: [
                      // Header Card with "Generate Plan" action
                      _buildHeaderBanner(totalCount, completedCount),

                      const SizedBox(height: 20),

                      // Content: Timeline or Empty State
                      if (_studyPlans.isEmpty)
                        _buildEmptyState()
                      else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Generated Study Timeline",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "$completedCount of $totalCount completed",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ..._buildTimelineGroups(groupedSessions),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeaderBanner(int total, int completed) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332575FC),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Study Plan Engine",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Automated timetable-aware slot scheduling",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Prominent "Generate Plan" Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generatePlan,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.deepPurple,
                        strokeWidth: 2.2,
                      ),
                    )
                  : const Icon(Icons.bolt, size: 22),
              label: Text(
                _isGenerating ? "Analyzing Timetable & Free Slots..." : "Generate Study Plan",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.deepPurple,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // "Couldn't Follow Your Plan? Replan" Button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: _openReplanModal,
              icon: const Icon(Icons.published_with_changes_rounded, size: 20),
              label: const Text(
                "Couldn't Follow Your Plan? Replan",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white70, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.calendar_month_outlined, size: 64, color: Colors.deepPurple.shade300),
          const SizedBox(height: 16),
          const Text(
            "No Study Plan Yet",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "The Study Plan engine reads your fixed weekly classes, locates your free hours between 8 AM and 8 PM, and intelligently schedules your pending academic tasks before their deadlines.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
          ),
          const SizedBox(height: 22),
          ElevatedButton.icon(
            onPressed: _isGenerating ? null : _generatePlan,
            icon: const Icon(Icons.bolt),
            label: const Text("Generate Plan Now"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTimelineGroups(Map<String, List<dynamic>> groupedSessions) {
    final List<Widget> widgets = [];

    final sortedDates = groupedSessions.keys.toList()..sort();

    for (final dateKey in sortedDates) {
      final sessions = groupedSessions[dateKey] ?? [];

      // Date Header Pill
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 14.0, bottom: 12.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade700,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      _formatDateHeader(dateKey),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 1.5,
                  color: Colors.deepPurple.shade100,
                ),
              ),
            ],
          ),
        ),
      );

      // Timeline Items
      for (int i = 0; i < sessions.length; i++) {
        final session = sessions[i] as Map<String, dynamic>;
        final isLast = i == sessions.length - 1;
        widgets.add(_buildTimelineItem(session, isLast));
      }
    }

    return widgets;
  }

  Widget _buildTimelineItem(Map<String, dynamic> session, bool isLast) {
    final id = session['planId'] ?? session['id'] ?? 0;
    final title = (session['title'] ?? 'Study Session').toString();
    final status = (session['status'] ?? 'PENDING').toString().toUpperCase();
    final isBreak = status == 'BREAK' || title.toLowerCase().startsWith('break');
    final isCompleted = status == 'COMPLETED';
    final timeSlotStr = _formatTimeSlot(session['startTime'], session['endTime']);
    final durationStr = _formatDuration(session['startTime'], session['endTime']);
    final subjectColor = _getColorForTitle(title);
    final isLunchMeal = title.toLowerCase().contains('lunch') || title.toLowerCase().contains('meal');
    final breakThemeColor = isLunchMeal ? Colors.amber.shade800 : Colors.teal.shade700;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline Node & Connecting Line
          SizedBox(
            width: 32,
            child: Column(
              children: [
                // Node
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isBreak
                        ? (isLunchMeal ? const Color(0xFFFEF3C7) : const Color(0xFFCCFBF1))
                        : (isCompleted ? Colors.green : subjectColor),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isBreak
                          ? breakThemeColor
                          : Colors.white,
                      width: isBreak ? 2 : 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isBreak ? breakThemeColor : (isCompleted ? Colors.green : subjectColor)).withValues(alpha: 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isBreak
                      ? Icon(
                          isLunchMeal ? Icons.restaurant_rounded : Icons.coffee_rounded,
                          size: 11,
                          color: breakThemeColor,
                        )
                      : (isCompleted
                          ? const Icon(Icons.check, size: 12, color: Colors.white)
                          : null),
                ),
                // Connector Line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isBreak ? Colors.teal.shade100 : Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Timeline Content Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isBreak
                    ? (isLunchMeal ? const Color(0xFFFFFBEB) : const Color(0xFFF0FDF4))
                    : (isCompleted ? const Color(0xFFF9FAFB) : Colors.white),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isBreak
                      ? (isLunchMeal ? Colors.amber.shade300 : Colors.teal.shade300)
                      : (isCompleted
                          ? Colors.grey.shade300
                          : subjectColor.withValues(alpha: 0.35)),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isBreak
                        ? breakThemeColor.withValues(alpha: 0.04)
                        : Colors.black.withValues(alpha: isCompleted ? 0.02 : 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time slot badge + Actions
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (isBreak ? breakThemeColor : subjectColor).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isBreak ? Icons.schedule_rounded : Icons.access_time,
                              size: 13,
                              color: isBreak ? breakThemeColor : subjectColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              timeSlotStr,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isBreak ? breakThemeColor : subjectColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        durationStr,
                        style: TextStyle(
                          fontSize: 11,
                          color: isBreak ? breakThemeColor.withValues(alpha: 0.8) : Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                        tooltip: isBreak ? "Dismiss break" : "Remove session",
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _deleteSession(id as int, title),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Title + Status (Academic vs Break)
                  Row(
                    children: [
                      if (isBreak) ...[
                        Container(
                          padding: const EdgeInsets.all(5),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: breakThemeColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isLunchMeal ? Icons.restaurant_rounded : Icons.self_improvement_rounded,
                            size: 16,
                            color: breakThemeColor,
                          ),
                        ),
                      ] else ...[
                        Transform.scale(
                          scale: 1.05,
                          child: Checkbox(
                            value: isCompleted,
                            activeColor: Colors.green,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            onChanged: (_) => _togglePlanStatus(session),
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isBreak
                                ? (isLunchMeal ? Colors.amber.shade900 : Colors.teal.shade900)
                                : (isCompleted ? Colors.grey.shade500 : Colors.black87),
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isBreak
                              ? breakThemeColor.withValues(alpha: 0.1)
                              : (isCompleted ? Colors.green.shade50 : Colors.amber.shade50),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isBreak
                                ? breakThemeColor.withValues(alpha: 0.3)
                                : (isCompleted ? Colors.green.shade300 : Colors.amber.shade300),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          isBreak
                              ? (isLunchMeal ? "MEAL BREAK" : "REST BREAK")
                              : status,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isBreak
                                ? breakThemeColor
                                : (isCompleted ? Colors.green.shade800 : Colors.amber.shade900),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // "Why this plan was generated" / Break Explanation Badge
                  Builder(
                    builder: (context) {
                      final explanation = session['explanation']?.toString();
                      if (explanation == null || explanation.trim().isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Container(
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: isBreak ? Colors.white.withValues(alpha: 0.8) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isBreak
                                ? breakThemeColor.withValues(alpha: 0.25)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              isBreak ? Icons.spa_rounded : Icons.auto_awesome,
                              size: 14,
                              color: isBreak ? breakThemeColor : const Color(0xFF6366F1),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: isBreak ? "Break Purpose: " : "Why generated: ",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isBreak ? breakThemeColor : const Color(0xFF334155),
                                      ),
                                    ),
                                    TextSpan(
                                      text: explanation.trim(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isBreak ? const Color(0xFF1E293B) : const Color(0xFF475569),
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // REPLANNING FEATURE (MISSED TIME INTERVAL INPUT & PREVIEW)
  // ==========================================================

  void _openReplanModal() {
    DateTime selectedDate = DateTime.now();
    TimeOfDay startTime = const TimeOfDay(hour: 10, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 12, minute: 0);
    bool isAnalyzing = false;
    String? modalError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (modalStateContext, setModalState) {
            final overlapping = _getOverlappingSessions(selectedDate, startTime, endTime);

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.published_with_changes_rounded, color: Colors.deepPurple),
                            SizedBox(width: 8),
                            Text(
                              "Replan Missed Study Interval",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Enter the exact time interval you were unable to follow from your study plan. We'll identify what was missed and find replacement slots.",
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.3),
                    ),
                    const SizedBox(height: 18),

                    // Date selector
                    const Text("Date of Missed Plan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 30)),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                        );
                        if (picked != null) {
                          setModalState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 18, color: Colors.deepPurple),
                            const SizedBox(width: 10),
                            Text(
                              DateFormat('EEEE, MMM d, yyyy').format(selectedDate),
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Time Interval: Start & End pickers
                    const Text("Missed Time Interval", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(context: context, initialTime: startTime);
                              if (picked != null) {
                                setModalState(() {
                                  startTime = picked;
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Missed From", style: TextStyle(fontSize: 10, color: Colors.grey)),
                                  const SizedBox(height: 2),
                                  Text(
                                    startTime.format(context),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.arrow_forward_rounded, color: Colors.grey, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(context: context, initialTime: endTime);
                              if (picked != null) {
                                setModalState(() {
                                  endTime = picked;
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Missed Until", style: TextStyle(fontSize: 10, color: Colors.grey)),
                                  const SizedBox(height: 2),
                                  Text(
                                    endTime.format(context),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Live Overlapping Sessions Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: overlapping.isNotEmpty ? const Color(0xFFEDE7F6) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: overlapping.isNotEmpty ? const Color(0xFFD1C4E9) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                overlapping.isNotEmpty ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
                                size: 16,
                                color: overlapping.isNotEmpty ? Colors.deepPurple : Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                overlapping.isNotEmpty
                                    ? "Affected Sessions in this Interval (${overlapping.length})"
                                    : "No sessions currently overlap this interval",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: overlapping.isNotEmpty ? Colors.deepPurple.shade900 : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          if (overlapping.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            ...overlapping.map((s) {
                              final t = s['title'] ?? 'Session';
                              final sFmt = _formatTimeSlot(s['startTime'], s['endTime']);
                              final status = s['status'] ?? 'PENDING';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  "• $t ($sFmt) - $status",
                                  style: const TextStyle(fontSize: 11, color: Colors.black87),
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    ),

                    if (modalError != null) ...[
                      const SizedBox(height: 10),
                      Text(modalError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                    ],

                    const SizedBox(height: 20),

                    // Submit Preview Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: isAnalyzing
                            ? null
                            : () async {
                                final sMinutes = startTime.hour * 60 + startTime.minute;
                                final eMinutes = endTime.hour * 60 + endTime.minute;
                                if (sMinutes >= eMinutes) {
                                  setModalState(() {
                                    modalError = "Missed start time must be before end time.";
                                  });
                                  return;
                                }

                                setModalState(() {
                                  isAnalyzing = true;
                                  modalError = null;
                                });

                                final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
                                final startStr = "${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}";
                                final endStr = "${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}";

                                final req = {
                                  "missedDate": dateStr,
                                  "missedStartTime": startStr,
                                  "missedEndTime": endStr,
                                };

                                final res = await ApiService.previewReplan(widget.userId, req);

                                if (!mounted) return;

                                setModalState(() {
                                  isAnalyzing = false;
                                });

                                if (res['success'] == true && res['data'] != null) {
                                  final Map<String, dynamic> previewData = res['data'];
                                  if (previewData['success'] == false) {
                                    setModalState(() {
                                      modalError = previewData['message'] ?? "No study sessions found in this interval.";
                                    });
                                    return;
                                  }

                                  if (!sheetContext.mounted) return;
                                  Navigator.pop(sheetContext); // Close input sheet
                                  _showReplanPreviewDialog(req, previewData);
                                } else {
                                  setModalState(() {
                                    modalError = res['error'] ?? "Failed to analyze missed interval.";
                                  });
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: isAnalyzing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.analytics_rounded, size: 20),
                        label: Text(
                          isAnalyzing ? "Analyzing Feasible Slots..." : "Analyze & Preview Replanning",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
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

  void _showReplanPreviewDialog(Map<String, dynamic> requestData, Map<String, dynamic> previewData) {
    final List<dynamic> affected = previewData['affectedSessions'] ?? [];
    final List<dynamic> proposed = previewData['proposedReplacements'] ?? [];
    final List<dynamic> unscheduled = previewData['unscheduledTasks'] ?? [];
    bool isApplying = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              title: const Row(
                children: [
                  Icon(Icons.rule_folder_rounded, color: Colors.deepPurple, size: 26),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Proposed Plan Revision",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        previewData['message'] ?? "Review the proposed replacement schedule below:",
                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                      ),
                      const SizedBox(height: 14),

                      // Section 1: Missed Sessions
                      const Text(
                        "1. Affected Missed Work",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E1B4B)),
                      ),
                      const SizedBox(height: 6),
                      ...affected.map((item) {
                        final title = item['taskTitle'] ?? 'Session';
                        final missedHrs = item['missedDurationHours'] ?? 0;
                        final isDone = item['completed'] == true;
                        final origStart = item['originalStart'] != null ? DateFormat('MMM d, hh:mm a').format(DateTime.parse(item['originalStart'].toString())) : '';
                        final origEnd = item['originalEnd'] != null ? DateFormat('hh:mm a').format(DateTime.parse(item['originalEnd'].toString())) : '';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDone ? Colors.green.shade50 : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isDone ? Colors.green.shade200 : Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isDone ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                size: 18,
                                color: isDone ? Colors.green : Colors.redAccent,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    Text("$origStart - $origEnd (${missedHrs}h missed)", style: const TextStyle(fontSize: 11, color: Colors.black54)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isDone ? "Preserved" : "To Replace",
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDone ? Colors.green : Colors.redAccent),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 14),

                      // Section 2: Proposed Replacements
                      const Text(
                        "2. Proposed Replacements (Future Slots)",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E1B4B)),
                      ),
                      const SizedBox(height: 6),
                      if (proposed.isEmpty)
                        const Text("No replacement sessions needed or available.", style: TextStyle(fontSize: 12, color: Colors.grey))
                      else
                        ...proposed.map((item) {
                          final title = item['taskTitle'] ?? 'Session';
                          final duration = item['durationHours'] ?? 1.0;
                          final priority = item['priority'] ?? 'NORMAL';
                          final reason = item['reason'] ?? '';
                          String timeStr = '';
                          if (item['newStartTime'] != null && item['newEndTime'] != null) {
                            final s = DateTime.parse(item['newStartTime'].toString());
                            final e = DateTime.parse(item['newEndTime'].toString());
                            timeStr = "${DateFormat('EEE, MMM d • hh:mm a').format(s)} - ${DateFormat('hh:mm a').format(e)}";
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF86EFAC)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF14532D)),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        "$priority • ${duration}h",
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF15803D)),
                                    const SizedBox(width: 4),
                                    Text(timeStr, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF166534))),
                                  ],
                                ),
                                if (reason.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    reason,
                                    style: const TextStyle(fontSize: 10, color: Color(0xFF14532D), fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),

                      // Section 3: Unscheduled Tasks (if any)
                      if (unscheduled.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text(
                          "3. Unscheduled Work Warnings",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.deepOrange),
                        ),
                        const SizedBox(height: 6),
                        ...unscheduled.map((u) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFFDBA74)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  u['taskTitle'] ?? 'Task',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF9A3412)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  u['reason'] ?? '',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFFC2410C)),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              actions: [
                TextButton(
                  onPressed: isApplying ? null : () => Navigator.pop(ctx),
                  child: const Text("Cancel (Keep Current Plan)", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton.icon(
                  onPressed: (isApplying || proposed.isEmpty)
                      ? null
                      : () async {
                          setDialogState(() {
                            isApplying = true;
                          });

                          final applyRes = await ApiService.applyReplan(widget.userId, requestData);

                          if (!mounted) return;

                          setDialogState(() {
                            isApplying = false;
                          });

                          if (applyRes['success'] == true) {
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            final List<dynamic> updatedList = applyRes['data'] is List ? applyRes['data'] : [];
                            setState(() {
                              _studyPlans = updatedList;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Successfully applied revised study plan (${proposed.length} replacement sessions saved)!"),
                                backgroundColor: Colors.green.shade700,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(applyRes['error'] ?? "Failed to save revised study plan."),
                                backgroundColor: Colors.redAccent,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: isApplying
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded, size: 18),
                  label: Text(isApplying ? "Applying..." : "Accept & Apply"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<dynamic> _getOverlappingSessions(DateTime date, TimeOfDay start, TimeOfDay end) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final startMins = start.hour * 60 + start.minute;
    final endMins = end.hour * 60 + end.minute;

    final List<dynamic> matches = [];
    for (final s in _studyPlans) {
      final startRaw = s['startTime'];
      final endRaw = s['endTime'];
      if (startRaw != null && endRaw != null) {
        try {
          final sDt = DateTime.parse(startRaw.toString());
          final eDt = DateTime.parse(endRaw.toString());
          final sDateStr = DateFormat('yyyy-MM-dd').format(sDt);

          if (sDateStr == dateStr) {
            final sPlanMins = sDt.hour * 60 + sDt.minute;
            final ePlanMins = eDt.hour * 60 + eDt.minute;

            if (sPlanMins < endMins && ePlanMins > startMins) {
              matches.add(s);
            }
          }
        } catch (_) {}
      }
    }
    return matches;
  }
}
