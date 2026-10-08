import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'services/api_service.dart';

class AcademicTasksPage extends StatefulWidget {
  final int userId;

  const AcademicTasksPage({
    super.key,
    required this.userId,
  });

  @override
  State<AcademicTasksPage> createState() => _AcademicTasksPageState();
}

class _AcademicTasksPageState extends State<AcademicTasksPage> {
  static const List<String> _taskTypes = ['ASSIGNMENT', 'EXAM', 'PROJECT', 'LAB'];

  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _tasks = [];
  String _selectedTypeFilter = 'ALL';
  String _selectedStatusFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await ApiService.fetchAcademicTasks(widget.userId);
      if (!mounted) return;
      setState(() {
        _tasks = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "Failed to load tasks: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleTaskCompletion(Map<String, dynamic> task) async {
    final id = task['taskId'] ?? task['id'] ?? 0;
    final currentStatus = (task['status'] ?? 'PENDING').toString().toUpperCase();
    final newStatus = currentStatus == 'COMPLETED' ? 'PENDING' : 'COMPLETED';

    bool success;
    if (newStatus == 'COMPLETED') {
      success = await ApiService.markAcademicTaskCompleted(id as int);
    } else {
      success = await ApiService.toggleAcademicTaskStatus(id as int, newStatus);
    }

    if (!mounted) return;

    if (success) {
      // Optimistic update
      setState(() {
        task['status'] = newStatus;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus == 'COMPLETED'
              ? "Marked '${task['title']}' as completed!"
              : "Reopened '${task['title']}'"),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to update task status"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteTask(int taskId, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Task"),
        content: Text("Are you sure you want to delete '$title'?"),
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
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await ApiService.deleteAcademicTaskItem(taskId);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Deleted '$title'"),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadTasks();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to delete task"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openAddTaskModal({String? preselectedType}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddTaskModal(
        userId: widget.userId,
        initialTaskType: preselectedType ?? 'ASSIGNMENT',
        onTaskAdded: () {
          _loadTasks();
        },
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toUpperCase()) {
      case 'ASSIGNMENT':
        return const Color(0xFF3B82F6); // Blue
      case 'EXAM':
        return const Color(0xFFEF4444); // Red
      case 'PROJECT':
        return const Color(0xFF8B5CF6); // Purple
      case 'LAB':
        return const Color(0xFF10B981); // Emerald
      default:
        return Colors.deepPurple;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toUpperCase()) {
      case 'ASSIGNMENT':
        return Icons.assignment_outlined;
      case 'EXAM':
        return Icons.school_outlined;
      case 'PROJECT':
        return Icons.folder_special_outlined;
      case 'LAB':
        return Icons.science_outlined;
      default:
        return Icons.task_outlined;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case 'HIGH':
        return const Color(0xFFEF4444);
      case 'MEDIUM':
        return const Color(0xFFF59E0B);
      case 'LOW':
        return const Color(0xFF10B981);
      default:
        return Colors.grey;
    }
  }

  String _formatDeadline(dynamic deadlineVal) {
    if (deadlineVal == null) return 'No deadline';
    try {
      final dt = DateTime.parse(deadlineVal.toString());
      return DateFormat('MMM dd, yyyy • hh:mm a').format(dt);
    } catch (_) {
      return deadlineVal.toString();
    }
  }

  List<dynamic> _getFilteredTasks() {
    return _tasks.where((t) {
      final type = (t['taskType'] ?? '').toString().toUpperCase();
      final status = (t['status'] ?? 'PENDING').toString().toUpperCase();

      final matchesType = _selectedTypeFilter == 'ALL' || type == _selectedTypeFilter;
      final matchesStatus = _selectedStatusFilter == 'ALL' || status == _selectedStatusFilter;

      return matchesType && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _getFilteredTasks();
    final completedCount = _tasks.where((t) => (t['status'] ?? '').toString().toUpperCase() == 'COMPLETED').length;
    final totalCount = _tasks.length;
    final progress = totalCount == 0 ? 0.0 : (completedCount / totalCount);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          "Academic Tasks",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh Tasks",
            onPressed: _loadTasks,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddTaskModal(),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Add Task", style: TextStyle(fontWeight: FontWeight.bold)),
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
                        const Icon(Icons.error_outline, size: 52, color: Colors.redAccent),
                        const SizedBox(height: 14),
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 18),
                        ElevatedButton(
                          onPressed: _loadTasks,
                          child: const Text("Retry"),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: Colors.deepPurple,
                  onRefresh: _loadTasks,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    children: [
                      // Header Summary Card
                      _buildSummaryCard(totalCount, completedCount, progress),

                      const SizedBox(height: 16),

                      // Dedicated Feature Buttons: Add Assignment, Add Exam, Add Project, Add Lab
                      _buildQuickAddButtons(),

                      const SizedBox(height: 16),

                      // Filters: Type & Status
                      _buildFilterRow(),

                      const SizedBox(height: 16),

                      // Task List Cards
                      if (filteredTasks.isEmpty)
                        _buildEmptyState()
                      else
                        ...filteredTasks.map((t) => _buildTaskCard(t as Map<String, dynamic>)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummaryCard(int total, int completed, double progress) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Task Progress",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "$completed / $total Done",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            total == 0
                ? "No academic tasks yet. Tap a button below to get started!"
                : "${(progress * 100).toInt()}% of your academic tasks completed",
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAddButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Quick Add",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildAddActionChip(
                label: "Add Assignment",
                type: "ASSIGNMENT",
                icon: Icons.assignment_outlined,
                color: const Color(0xFF3B82F6),
              ),
              _buildAddActionChip(
                label: "Add Exam",
                type: "EXAM",
                icon: Icons.school_outlined,
                color: const Color(0xFFEF4444),
              ),
              _buildAddActionChip(
                label: "Add Project",
                type: "PROJECT",
                icon: Icons.folder_special_outlined,
                color: const Color(0xFF8B5CF6),
              ),
              _buildAddActionChip(
                label: "Add Lab Task",
                type: "LAB",
                icon: Icons.science_outlined,
                color: const Color(0xFF10B981),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddActionChip({
    required String label,
    required String type,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ElevatedButton.icon(
        onPressed: () => _openAddTaskModal(preselectedType: type),
        icon: Icon(icon, size: 16, color: color),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.1),
          foregroundColor: color,
          elevation: 0,
          side: BorderSide(color: color.withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Type filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildTypeChip("ALL", "All Types"),
              ..._taskTypes.map((t) => _buildTypeChip(t, t[0] + t.substring(1).toLowerCase())),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Status filter chips
        Row(
          children: [
            _buildStatusChip("ALL", "All"),
            _buildStatusChip("PENDING", "Pending"),
            _buildStatusChip("COMPLETED", "Completed"),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeChip(String type, String label) {
    final isSelected = _selectedTypeFilter == type;
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) {
          setState(() {
            _selectedTypeFilter = type;
          });
        },
        selectedColor: Colors.deepPurple,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: isSelected ? Colors.deepPurple : Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, String label) {
    final isSelected = _selectedStatusFilter == status;
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) {
          if (val) {
            setState(() {
              _selectedStatusFilter = status;
            });
          }
        },
        selectedColor: Colors.deepPurple.shade100,
        labelStyle: TextStyle(
          color: isSelected ? Colors.deepPurple : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        backgroundColor: Colors.white,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
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
          Icon(Icons.check_circle_outline, size: 60, color: Colors.deepPurple.shade300),
          const SizedBox(height: 14),
          const Text(
            "No Academic Tasks",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "No tasks found for the selected filter. Tap 'Add Task' to create an assignment, exam, project, or lab task.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () => _openAddTaskModal(),
            icon: const Icon(Icons.add),
            label: const Text("Add New Task"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final id = task['taskId'] ?? task['id'] ?? 0;
    final title = (task['title'] ?? '').toString();
    final type = (task['taskType'] ?? 'ASSIGNMENT').toString().toUpperCase();
    final priority = (task['priority'] ?? 'MEDIUM').toString().toUpperCase();
    final status = (task['status'] ?? 'PENDING').toString().toUpperCase();
    final isCompleted = status == 'COMPLETED';
    final estimatedHours = task['estimatedHours'] != null
        ? "${task['estimatedHours']} hrs"
        : "1 hr";
    final deadlineStr = _formatDeadline(task['deadline']);

    final typeColor = _getTypeColor(type);
    final priorityColor = _getPriorityColor(priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFFF9FAFB) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted ? Colors.grey.shade300 : typeColor.withValues(alpha: 0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isCompleted ? 0.02 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Type Badge + Priority Badge + Delete Button
            Row(
              children: [
                // Type Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getTypeIcon(type), size: 14, color: typeColor),
                      const SizedBox(width: 4),
                      Text(
                        type,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: typeColor,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Priority Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flag, size: 12, color: priorityColor),
                      const SizedBox(width: 3),
                      Text(
                        priority,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: priorityColor,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Delete button
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                  tooltip: "Delete task",
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _deleteTask(id as int, title),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Middle: Checkbox + Title (Struck through if completed)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checkbox toggle
                Transform.scale(
                  scale: 1.1,
                  child: Checkbox(
                    value: isCompleted,
                    activeColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: (_) => _toggleTaskCompletion(task),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? Colors.grey.shade500 : Colors.black87,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        decorationThickness: 2.0,
                        decorationColor: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Bottom Info: Deadline, Estimated Hours, Status Badge
            Padding(
              padding: const EdgeInsets.only(left: 46.0),
              child: Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  // Deadline
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_outlined, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        deadlineStr,
                        style: TextStyle(
                          fontSize: 12,
                          color: isCompleted ? Colors.grey.shade500 : Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  // Estimated Hours
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        estimatedHours,
                        style: TextStyle(
                          fontSize: 12,
                          color: isCompleted ? Colors.grey.shade500 : Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  // Status
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isCompleted
                            ? Colors.green.shade800
                            : Colors.amber.shade900,
                      ),
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
}

class _AddTaskModal extends StatefulWidget {
  final int userId;
  final String initialTaskType;
  final VoidCallback onTaskAdded;

  const _AddTaskModal({
    required this.userId,
    required this.initialTaskType,
    required this.onTaskAdded,
  });

  @override
  State<_AddTaskModal> createState() => _AddTaskModalState();
}

class _AddTaskModalState extends State<_AddTaskModal> {
  static const List<String> _types = ['ASSIGNMENT', 'EXAM', 'PROJECT', 'LAB'];
  static const List<String> _priorities = ['HIGH', 'MEDIUM', 'LOW'];

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _hoursController = TextEditingController(text: "2.0");

  late String _selectedType;
  String _selectedPriority = 'MEDIUM';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 2));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 23, minute: 59);

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialTaskType;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final deadlineDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final hours = double.tryParse(_hoursController.text.trim()) ?? 1.0;

    // ISO format: yyyy-MM-ddTHH:mm:ss
    final deadlineIso = DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(deadlineDateTime);

    final taskData = {
      "userId": widget.userId,
      "title": _titleController.text.trim(),
      "taskType": _selectedType,
      "deadline": deadlineIso,
      "estimatedHours": hours,
      "priority": _selectedPriority,
      "status": "PENDING",
    };

    final result = await ApiService.addAcademicTaskItem(taskData);
    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (result['success'] == true) {
      Navigator.pop(context);
      widget.onTaskAdded();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Added '${_titleController.text.trim()}' successfully"),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final err = result['error'] ?? "Failed to add task";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err.toString()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
              // Drag Indicator
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Add $_selectedType",
                    style: const TextStyle(
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

              const SizedBox(height: 16),

              // Title Field
              const Text(
                "Title",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: "e.g., DBMS Assignment 2, Midterm Exam, AI Project",
                  prefixIcon: const Icon(Icons.title, color: Colors.deepPurple),
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
                    return "Task title is required";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Task Type Dropdown
              const Text(
                "Task Type",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.category, color: Colors.deepPurple),
                  filled: true,
                  fillColor: const Color(0xFFF7F9FC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                items: _types.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedType = val;
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              // Deadline (Date & Time pickers)
              const Text(
                "Deadline",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F9FC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 18, color: Colors.deepPurple),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('MMM dd, yyyy').format(_selectedDate),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: _pickTime,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F9FC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, size: 18, color: Colors.deepPurple),
                            const SizedBox(width: 8),
                            Text(
                              _selectedTime.format(context),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Row: Estimated Hours & Priority
              Row(
                children: [
                  // Estimated Hours
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Est. Hours",
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _hoursController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            hintText: "e.g. 2.5",
                            prefixIcon: const Icon(Icons.timer_outlined, color: Colors.deepPurple),
                            filled: true,
                            fillColor: const Color(0xFFF7F9FC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          validator: (val) {
                            if (val != null && val.isNotEmpty) {
                              final d = double.tryParse(val);
                              if (d == null || d < 0) {
                                return "Invalid hours";
                              }
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Priority
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Priority",
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedPriority,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.flag_outlined, color: Colors.deepPurple),
                            filled: true,
                            fillColor: const Color(0xFFF7F9FC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          items: _priorities.map((p) {
                            return DropdownMenuItem(
                              value: p,
                              child: Text(p),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedPriority = val;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveTask,
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
                          "Save Task",
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
