import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'academic_task_entry_page.dart';

class TimetableEntryPage extends StatefulWidget {
  final int userId;

  const TimetableEntryPage({Key? key, required this.userId}) : super(key: key);

  @override
  _TimetableEntryPageState createState() => _TimetableEntryPageState();
}

class _TimetableEntryPageState extends State<TimetableEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  String _selectedDay = 'MONDAY';
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);

  final List<String> _daysOfWeek = [
    'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'
  ];

  List<dynamic> _addedClasses = [];

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  Future<void> _fetchClasses() async {
    final classes = await ApiService.getUserTimetable(widget.userId);
    setState(() {
      _addedClasses = classes.where((c) => c['dayOfWeek'] == _selectedDay).toList();
    });
  }

  Future<void> _deleteClass(int classId) async {
    bool success = await ApiService.deleteTimetableClass(classId);
    if (success) {
      _fetchClasses();
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _addClass() async {
    if (_formKey.currentState!.validate()) {
      // Format time as HH:mm:ss for backend
      String formatTime(TimeOfDay time) {
        final h = time.hour.toString().padLeft(2, '0');
        final m = time.minute.toString().padLeft(2, '0');
        return "$h:$m:00";
      }

      Map<String, dynamic> classData = {
        "userId": widget.userId,
        "subjectName": _subjectController.text,
        "dayOfWeek": _selectedDay,
        "startTime": formatTime(_startTime),
        "endTime": formatTime(_endTime),
      };

      bool success = await ApiService.addTimetableClass(classData);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Class added successfully!")),
        );
        _subjectController.clear();
        _fetchClasses();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to add class.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Weekly Timetable Entry"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Add Your Classes",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(
                  labelText: 'Subject Name',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _subjectController.clear(),
                  ),
                ),
                validator: (value) => value!.isEmpty ? 'Enter subject name' : null,
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: _selectedDay,
                decoration: const InputDecoration(
                  labelText: 'Day of Week',
                  border: OutlineInputBorder(),
                ),
                items: _daysOfWeek.map((day) {
                  return DropdownMenuItem(
                    value: day,
                    child: Text(day),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDay = value!;
                  });
                  _fetchClasses();
                },
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text("Start Time"),
                      subtitle: Text(_startTime.format(context)),
                      trailing: const Icon(Icons.access_time),
                      onTap: () => _selectTime(context, true),
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: Colors.grey),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ListTile(
                      title: const Text("End Time"),
                      subtitle: Text(_endTime.format(context)),
                      trailing: const Icon(Icons.access_time),
                      onTap: () => _selectTime(context, false),
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: Colors.grey),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _addClass,
                  icon: const Icon(Icons.add),
                  label: const Text("Add Class"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text("Classes for Selected Day:", style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: ListView.builder(
                  itemCount: _addedClasses.length,
                  itemBuilder: (context, index) {
                    final item = _addedClasses[index];
                    return Card(
                      child: ListTile(
                        title: Text(item['subjectName']),
                        subtitle: Text("${item['startTime']} - ${item['endTime']}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteClass(item['id']),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AcademicTaskEntryPage(userId: widget.userId, selectedDay: _selectedDay),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text(
                    "Analyze Timetable",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
