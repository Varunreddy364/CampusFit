import 'package:flutter/material.dart';
import 'services/api_service.dart';

class WeeklyTimetablePage extends StatefulWidget {
  final int userId;

  const WeeklyTimetablePage({
    super.key,
    required this.userId,
  });

  @override
  State<WeeklyTimetablePage> createState() => _WeeklyTimetablePageState();
}

class _WeeklyTimetablePageState extends State<WeeklyTimetablePage> {
  static const List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const int _startHour = 8; // 8 AM
  static const int _endHour = 20; // 8 PM (20:00)
  static const double _hourHeight = 65.0;
  static const double _dayColumnWidth = 110.0;
  static const double _timeColumnWidth = 62.0;

  final ScrollController _horizontalHeaderController = ScrollController();
  final ScrollController _horizontalGridController = ScrollController();
  final ScrollController _verticalTimeController = ScrollController();
  final ScrollController _verticalGridController = ScrollController();

  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _classes = [];

  // Consistent color palette for different subjects
  static final List<Color> _palette = [
    const Color(0xFF3B82F6), // Blue
    const Color(0xFF10B981), // Emerald
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFFF59E0B), // Amber
    const Color(0xFFEF4444), // Rose
    const Color(0xFF06B6D4), // Cyan
    const Color(0xFFEC4899), // Pink
    const Color(0xFF6366F1), // Indigo
    const Color(0xFF14B8A6), // Teal
    const Color(0xFFF97316), // Orange
  ];

  @override
  void initState() {
    super.initState();

    // Synchronize horizontal scrolling between day headers and timetable grid
    _horizontalGridController.addListener(() {
      if (_horizontalHeaderController.hasClients &&
          _horizontalHeaderController.offset != _horizontalGridController.offset) {
        _horizontalHeaderController.jumpTo(_horizontalGridController.offset);
      }
    });

    _horizontalHeaderController.addListener(() {
      if (_horizontalGridController.hasClients &&
          _horizontalGridController.offset != _horizontalHeaderController.offset) {
        _horizontalGridController.jumpTo(_horizontalHeaderController.offset);
      }
    });

    // Synchronize vertical scrolling between left time column and timetable grid
    _verticalGridController.addListener(() {
      if (_verticalTimeController.hasClients &&
          _verticalTimeController.offset != _verticalGridController.offset) {
        _verticalTimeController.jumpTo(_verticalGridController.offset);
      }
    });

    _verticalTimeController.addListener(() {
      if (_verticalGridController.hasClients &&
          _verticalGridController.offset != _verticalTimeController.offset) {
        _verticalGridController.jumpTo(_verticalTimeController.offset);
      }
    });

    _fetchSchedule();
  }

  @override
  void dispose() {
    _horizontalHeaderController.dispose();
    _horizontalGridController.dispose();
    _verticalTimeController.dispose();
    _verticalGridController.dispose();
    super.dispose();
  }

  Future<void> _fetchSchedule() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await ApiService.getAcademicSchedule(widget.userId);
      if (!mounted) return;
      setState(() {
        _classes = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "Failed to load timetable: $e";
        _isLoading = false;
      });
    }
  }

  Color _getColorForSubject(String subject) {
    if (subject.isEmpty) return _palette[0];
    int hash = 0;
    final normalized = subject.trim().toLowerCase();
    for (int i = 0; i < normalized.length; i++) {
      hash = normalized.codeUnitAt(i) + ((hash << 5) - hash);
    }
    final index = hash.abs() % _palette.length;
    return _palette[index];
  }

  String _formatHourLabel(int hour) {
    if (hour == 0 || hour == 24) return "12 AM";
    if (hour == 12) return "12 PM";
    if (hour < 12) return "$hour AM";
    return "${hour - 12} PM";
  }

  void _showClassDetailsDialog(Map<String, dynamic> item) {
    final id = item['scheduleId'] ?? item['id'] ?? 0;
    final subject = (item['subjectName'] ?? 'Class').toString();
    final day = (item['dayOfWeek'] ?? '').toString();
    final start = (item['startTime'] ?? '').toString();
    final end = (item['endTime'] ?? '').toString();
    final color = _getColorForSubject(subject);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        title: Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                subject,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(Icons.calendar_today, "Day", day),
            const SizedBox(height: 10),
            _buildDetailRow(Icons.access_time, "Time", "$start - $end"),
            const SizedBox(height: 10),
            _buildDetailRow(
              Icons.school,
              "Type",
              "Fixed Academic Class",
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close"),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ApiService.deleteAcademicSchedule(id as int);
              if (!mounted) return;
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Removed '$subject' from schedule"),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                _fetchSchedule();
              }
            },
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.deepPurple),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  void _openAddClassModal({String? initialDay, int? initialHour}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddClassModal(
        userId: widget.userId,
        initialDay: initialDay,
        initialHour: initialHour,
        onClassAdded: () {
          _fetchSchedule();
        },
      ),
    );
  }

  // Parses "09:00" or "09:00:00" to minutes from midnight
  int? _timeStringToMinutes(dynamic val) {
    if (val == null) return null;
    final str = val.toString().trim();
    final parts = str.split(':');
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h != null && m != null) {
        return h * 60 + m;
      }
    }
    return null;
  }

  String _formatTimeString(dynamic val) {
    if (val == null) return '';
    final str = val.toString().trim();
    final parts = str.split(':');
    if (parts.length >= 2) {
      final h = parts[0].padLeft(2, '0');
      final m = parts[1].padLeft(2, '0');
      return "$h:$m";
    }
    return str;
  }

  @override
  Widget build(BuildContext context) {
    final totalHours = _endHour - _startHour;
    final totalGridHeight = totalHours * _hourHeight;
    final totalGridWidth = _daysOfWeek.length * _dayColumnWidth;

    // Distinct subject list for the legend
    final uniqueSubjects = <String>{};
    for (final c in _classes) {
      final s = (c['subjectName'] ?? '').toString().trim();
      if (s.isNotEmpty) uniqueSubjects.add(s);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text(
          "Weekly Timetable",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh Timetable",
            onPressed: _fetchSchedule,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddClassModal(),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Add Class", style: TextStyle(fontWeight: FontWeight.bold)),
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
                        const Icon(Icons.error_outline, size: 50, color: Colors.redAccent),
                        const SizedBox(height: 12),
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchSchedule,
                          child: const Text("Retry"),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Top Info & Subject Legend Bar
                    _buildTopLegendBar(uniqueSubjects),

                    // Timetable Grid Header (Fixed Day Column Headers)
                    _buildHeaderRow(),

                    // Timetable Grid Body (Time column on left + scrollable grid)
                    Expanded(
                      child: Row(
                        children: [
                          // Left Fixed Time Column
                          SizedBox(
                            width: _timeColumnWidth,
                            child: SingleChildScrollView(
                              controller: _verticalTimeController,
                              physics: const ClampingScrollPhysics(),
                              child: _buildTimeColumn(totalGridHeight),
                            ),
                          ),

                          // Main Scrollable Grid
                          Expanded(
                            child: SingleChildScrollView(
                              controller: _horizontalGridController,
                              scrollDirection: Axis.horizontal,
                              physics: const ClampingScrollPhysics(),
                              child: SizedBox(
                                width: totalGridWidth,
                                child: SingleChildScrollView(
                                  controller: _verticalGridController,
                                  physics: const ClampingScrollPhysics(),
                                  child: SizedBox(
                                    height: totalGridHeight,
                                    width: totalGridWidth,
                                    child: _buildGridBody(totalGridHeight, totalGridWidth),
                                  ),
                                ),
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

  Widget _buildTopLegendBar(Set<String> uniqueSubjects) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "College Timetable (8 AM - 8 PM)",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.deepPurple.shade900,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "${_classes.length} classes",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.deepPurple.shade700,
                  ),
                ),
              ),
            ],
          ),
          if (uniqueSubjects.isNotEmpty) ...[
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: uniqueSubjects.map((sub) {
                  final color = _getColorForSubject(sub);
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: color.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          sub,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFEDE9FE),
        border: Border(
          bottom: BorderSide(color: Colors.deepPurple.shade100, width: 1.5),
        ),
      ),
      child: Row(
        children: [
          // Corner cell (Time header)
          Container(
            width: _timeColumnWidth,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.deepPurple.shade100, width: 1.5),
              ),
            ),
            child: Text(
              "Time",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.deepPurple.shade800,
              ),
            ),
          ),

          // Synchronized Day Headers
          Expanded(
            child: SingleChildScrollView(
              controller: _horizontalHeaderController,
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              child: Row(
                children: _daysOfWeek.map((day) {
                  return Container(
                    width: _dayColumnWidth,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Colors.deepPurple.shade100, width: 1),
                      ),
                    ),
                    child: Text(
                      day,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.deepPurple.shade900,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeColumn(double totalGridHeight) {
    final totalHours = _endHour - _startHour;
    return Stack(
      children: [
        // Column background
        Container(
          width: _timeColumnWidth,
          height: totalGridHeight,
          color: const Color(0xFFFAFAFA),
        ),

        // Hour labels aligned with grid lines
        ...List.generate(totalHours + 1, (i) {
          final hour = _startHour + i;
          final top = i * _hourHeight;
          return Positioned(
            top: top - 8,
            left: 0,
            right: 0,
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                _formatHourLabel(hour),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          );
        }),

        // Vertical divider on right of time column
        Positioned(
          top: 0,
          bottom: 0,
          right: 0,
          child: Container(
            width: 1.5,
            color: Colors.grey.shade300,
          ),
        ),
      ],
    );
  }

  Widget _buildGridBody(double totalGridHeight, double totalGridWidth) {
    final totalHours = _endHour - _startHour;

    return Stack(
      children: [
        // Background white canvas
        Container(
          width: totalGridWidth,
          height: totalGridHeight,
          color: Colors.white,
        ),

        // Horizontal Hourly Grid Lines
        ...List.generate(totalHours + 1, (i) {
          final top = i * _hourHeight;
          return Positioned(
            top: top,
            left: 0,
            right: 0,
            child: Container(
              height: 1,
              color: Colors.grey.shade200,
            ),
          );
        }),

        // Vertical Day Separators & tap handlers
        ...List.generate(_daysOfWeek.length, (colIdx) {
          final day = _daysOfWeek[colIdx];
          final left = colIdx * _dayColumnWidth;
          return Positioned(
            left: left,
            top: 0,
            bottom: 0,
            width: _dayColumnWidth,
            child: InkWell(
              onTap: () {
                // Tapping on empty day column prompts adding a class on that day
                _openAddClassModal(initialDay: day);
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Colors.grey.shade200, width: 1),
                  ),
                ),
              ),
            ),
          );
        }),

        // Render Scheduled Class Blocks
        ..._buildClassBlocks(),
      ],
    );
  }

  List<Widget> _buildClassBlocks() {
    final List<Widget> blocks = [];
    final startMinutesBase = _startHour * 60; // 8 AM in minutes (480)
    final endMinutesBase = _endHour * 60; // 8 PM in minutes (1200)

    for (final c in _classes) {
      final rawDay = (c['dayOfWeek'] ?? '').toString().trim();
      final dayIndex = _daysOfWeek.indexWhere(
        (d) => d.toLowerCase() == rawDay.toLowerCase(),
      );

      if (dayIndex == -1) continue; // Unknown day

      final startMin = _timeStringToMinutes(c['startTime']);
      final endMin = _timeStringToMinutes(c['endTime']);

      if (startMin == null || endMin == null) continue;
      if (endMin <= startMin) continue;

      // Clamp within 8 AM - 8 PM
      final effectiveStart = startMin.clamp(startMinutesBase, endMinutesBase);
      final effectiveEnd = endMin.clamp(startMinutesBase, endMinutesBase);

      if (effectiveEnd <= effectiveStart) continue;

      final startMinutesFrom8AM = effectiveStart - startMinutesBase;
      final durationMinutes = effectiveEnd - effectiveStart;

      final top = (startMinutesFrom8AM / 60.0) * _hourHeight;
      final height = (durationMinutes / 60.0) * _hourHeight;
      final left = (dayIndex * _dayColumnWidth) + 3;
      final width = _dayColumnWidth - 6;

      final subject = (c['subjectName'] ?? 'Class').toString();
      final startStr = _formatTimeString(c['startTime']);
      final endStr = _formatTimeString(c['endTime']);
      final color = _getColorForSubject(subject);

      blocks.add(
        Positioned(
          left: left,
          top: top + 1,
          width: width,
          height: (height - 2).clamp(24.0, 9999.0),
          child: GestureDetector(
            onTap: () => _showClassDetailsDialog(c as Map<String, dynamic>),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    subject,
                    maxLines: height > 45 ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: color,
                    ),
                  ),
                  if (height > 35) ...[
                    const SizedBox(height: 2),
                    Text(
                      "$startStr - $endStr",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    return blocks;
  }
}

class _AddClassModal extends StatefulWidget {
  final int userId;
  final String? initialDay;
  final int? initialHour;
  final VoidCallback onClassAdded;

  const _AddClassModal({
    required this.userId,
    this.initialDay,
    this.initialHour,
    required this.onClassAdded,
  });

  @override
  State<_AddClassModal> createState() => _AddClassModalState();
}

class _AddClassModalState extends State<_AddClassModal> {
  static const List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  late String _selectedDay;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  bool _isSaving = false;
  String? _timeErrorMessage;
  String? _conflictErrorMessage;

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.initialDay ?? 'Monday';
    final startH = widget.initialHour ?? 9;
    _startTime = TimeOfDay(hour: startH, minute: 0);
    _endTime = TimeOfDay(hour: (startH + 1).clamp(1, 23), minute: 0);
  }

  @override
  void dispose() {
    _subjectController.dispose();
    super.dispose();
  }

  String _formatTimeOfDay24(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  int _timeToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  void _validateTimes() {
    final startMin = _timeToMinutes(_startTime);
    final endMin = _timeToMinutes(_endTime);
    if (endMin <= startMin) {
      setState(() {
        _timeErrorMessage = "End time must be after start time.";
      });
    } else {
      setState(() {
        _timeErrorMessage = null;
      });
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
        _conflictErrorMessage = null;
      });
      _validateTimes();
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null) {
      setState(() {
        _endTime = picked;
        _conflictErrorMessage = null;
      });
      _validateTimes();
    }
  }

  Future<void> _saveClass() async {
    _validateTimes();
    if (_timeErrorMessage != null) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final scheduleData = {
      "userId": widget.userId,
      "subjectName": _subjectController.text.trim(),
      "dayOfWeek": _selectedDay,
      "startTime": _formatTimeOfDay24(_startTime),
      "endTime": _formatTimeOfDay24(_endTime),
    };

    final result = await ApiService.addAcademicSchedule(scheduleData);
    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (result['success'] == true) {
      Navigator.pop(context);
      widget.onClassAdded();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Added '${_subjectController.text.trim()}' to timetable"),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final err = result['error']?.toString() ?? "Failed to add class";
      final isConflict = err.toLowerCase().contains("overlap") ||
          err.toLowerCase().contains("conflict");

      if (isConflict) {
        setState(() {
          _conflictErrorMessage = err;
        });

        if (!context.mounted) return;
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Schedule Conflict Detected",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  err,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.4),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.info_outline, size: 18, color: Colors.amber),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Classes ending exactly when another starts are allowed. Please choose another time.",
                          style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text("OK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Add Academic Class",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              if (_conflictErrorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF87171), width: 1.2),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Schedule Conflict Detected",
                              style: TextStyle(
                                color: Color(0xFF991B1B),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _conflictErrorMessage!,
                              style: const TextStyle(
                                color: Color(0xFFB91C1C),
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              const Text(
                "Subject Name",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(
                  hintText: "e.g., DBMS, OS, ML",
                  prefixIcon: const Icon(Icons.menu_book, color: Colors.deepPurple),
                  filled: true,
                  fillColor: const Color(0xFFF7F9FC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return "Subject Name is required";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              const Text(
                "Day of the Week",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedDay,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.calendar_today, color: Colors.deepPurple),
                  filled: true,
                  fillColor: const Color(0xFFF7F9FC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                items: _daysOfWeek.map((day) {
                  return DropdownMenuItem(
                    value: day,
                    child: Text(day),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedDay = val;
                      _conflictErrorMessage = null;
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Start Time",
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _pickStartTime,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F9FC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _conflictErrorMessage != null
                                    ? Colors.redAccent
                                    : Colors.grey.shade300,
                                width: _conflictErrorMessage != null ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  color: _conflictErrorMessage != null ? Colors.redAccent : Colors.deepPurple,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _startTime.format(context),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "End Time",
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _pickEndTime,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F9FC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: (_conflictErrorMessage != null || _timeErrorMessage != null)
                                    ? Colors.redAccent
                                    : Colors.grey.shade300,
                                width: (_conflictErrorMessage != null || _timeErrorMessage != null) ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time_filled,
                                  color: _conflictErrorMessage != null ? Colors.redAccent : Colors.deepPurple,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _endTime.format(context),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (_timeErrorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _timeErrorMessage!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                ),
              ],

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveClass,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          "Save Class",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
