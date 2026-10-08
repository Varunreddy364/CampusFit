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
    final id = plan['planId'] ?? plan['id'] ?? 0;
    final currentStatus = (plan['status'] ?? 'PENDING').toString().toUpperCase();
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
    final completedCount = _studyPlans
        .where((p) => (p['status'] ?? '').toString().toUpperCase() == 'COMPLETED')
        .length;
    final totalCount = _studyPlans.length;

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
    final isCompleted = status == 'COMPLETED';
    final timeSlotStr = _formatTimeSlot(session['startTime'], session['endTime']);
    final durationStr = _formatDuration(session['startTime'], session['endTime']);
    final subjectColor = _getColorForTitle(title);

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
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green : subjectColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: (isCompleted ? Colors.green : subjectColor).withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : null,
                ),
                // Connector Line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: Colors.grey.shade300,
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
                color: isCompleted ? const Color(0xFFF9FAFB) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isCompleted
                      ? Colors.grey.shade300
                      : subjectColor.withValues(alpha: 0.35),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isCompleted ? 0.02 : 0.05),
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
                          color: subjectColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time, size: 13, color: subjectColor),
                            const SizedBox(width: 4),
                            Text(
                              timeSlotStr,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: subjectColor,
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
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                        tooltip: "Remove session",
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _deleteSession(id as int, title),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Title + Status Checkbox
                  Row(
                    children: [
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
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isCompleted ? Colors.grey.shade500 : Colors.black87,
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? Colors.green.shade50
                              : Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isCompleted
                                ? Colors.green.shade300
                                : Colors.amber.shade300,
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isCompleted
                                ? Colors.green.shade800
                                : Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // "Why this plan was generated" Explanation Badge
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
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              size: 14,
                              color: Color(0xFF6366F1),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    const TextSpan(
                                      text: "Why generated: ",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF334155),
                                      ),
                                    ),
                                    TextSpan(
                                      text: explanation.trim(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF475569),
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
}
