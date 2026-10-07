import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'services/api_service.dart';
import 'adaptive_plan_page.dart';

class AcademicTaskEntryPage extends StatefulWidget {
  final int userId;
  final String selectedDay;

  const AcademicTaskEntryPage({Key? key, required this.userId, required this.selectedDay}) : super(key: key);

  @override
  _AcademicTaskEntryPageState createState() => _AcademicTaskEntryPageState();
}

class _AcademicTaskEntryPageState extends State<AcademicTaskEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _durationController = TextEditingController();

  String _selectedTaskType = 'ASSIGNMENT';
  String _selectedPriority = 'HIGH';
  DateTime? _selectedDeadline;

  final List<String> _taskTypes = [
    'ASSIGNMENT', 'PROJECT', 'EXAM_PREP', 'STUDY_SESSION'
  ];

  final List<String> _priorities = [
    'HIGH', 'MEDIUM', 'LOW'
  ];

  Future<void> _selectDeadline(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDeadline = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _addTask() async {
    if (_formKey.currentState!.validate() && _selectedDeadline != null) {
      Map<String, dynamic> taskData = {
        "userId": widget.userId,
        "title": _titleController.text,
        "taskType": _selectedTaskType,
        "priority": _selectedPriority,
        // Send date in ISO 8601 format suitable for Spring Boot's LocalDateTime
        "deadline": _selectedDeadline!.toIso8601String(),
        "estimatedDuration": int.parse(_durationController.text),
      };

      bool success = await ApiService.addAcademicTask(taskData);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Task added successfully!")),
        );
        _titleController.clear();
        _durationController.clear();
        setState(() {
          _selectedDeadline = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to add task.")),
        );
      }
    } else if (_selectedDeadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a deadline.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Additional Academic Work"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Additional work for ${widget.selectedDay}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Task Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value!.isEmpty ? 'Enter task title' : null,
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: _selectedTaskType,
                  decoration: const InputDecoration(
                    labelText: 'Task Type',
                    border: OutlineInputBorder(),
                  ),
                  items: _taskTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTaskType = value!;
                    });
                  },
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: _selectedPriority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  items: _priorities.map((p) {
                    return DropdownMenuItem(
                      value: p,
                      child: Text(p),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPriority = value!;
                    });
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Estimated Duration (Minutes)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter duration in minutes';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                ListTile(
                  title: const Text("Select Deadline"),
                  subtitle: Text(_selectedDeadline == null
                      ? "No deadline selected"
                      : DateFormat('MMM dd, yyyy - hh:mm a').format(_selectedDeadline!)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDeadline(context),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Colors.grey),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _addTask,
                    icon: const Icon(Icons.add),
                    label: const Text("Add Academic Task"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdaptivePlanPage(userId: widget.userId),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text(
                      "Generate Personalized Plan",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
