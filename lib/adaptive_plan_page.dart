import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'services/api_service.dart';

class AdaptivePlanPage extends StatefulWidget {
  final int userId;

  const AdaptivePlanPage({Key? key, required this.userId}) : super(key: key);

  @override
  _AdaptivePlanPageState createState() => _AdaptivePlanPageState();
}

class _AdaptivePlanPageState extends State<AdaptivePlanPage> {
  Map<String, dynamic>? _studyPlan;
  bool _isLoading = true;
  String _selectedDay = 'MONDAY';

  final List<String> _daysOfWeek = [
    'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = _daysOfWeek[DateTime.now().weekday - 1]; // Default to today
    _fetchAdaptivePlan();
  }

  Future<void> _fetchAdaptivePlan() async {
    setState(() {
      _isLoading = true;
    });
    final plan = await ApiService.generateAdaptivePlan(widget.userId, _selectedDay);
    setState(() {
      _studyPlan = plan;
      _isLoading = false;
    });
  }

  String _formatTime(String isoString) {
    try {
      DateTime dt = DateTime.parse(isoString);
      return DateFormat('hh:mm a').format(dt);
    } catch (e) {
      return isoString;
    }
  }

  Widget _buildScheduleItem(Map<String, dynamic> item) {
    IconData icon;
    Color color;

    switch (item['taskType']) {
      case 'CLASS':
        icon = Icons.school;
        color = Colors.blue;
        break;
      case 'STUDY':
        icon = Icons.menu_book;
        color = Colors.orange;
        break;
      case 'WORKOUT':
        icon = Icons.fitness_center;
        color = Colors.green;
        break;
      default:
        icon = Icons.event;
        color = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      elevation: 3,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(
          item['title'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${_formatTime(item['startTime'])} - ${_formatTime(item['endTime'])}"),
            if (item['description'] != null && item['description'].toString().isNotEmpty)
              Text(
                item['description'],
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutRecommendation(Map<String, dynamic> workout) {
    if (workout['durationMinutes'] == 0) {
      return Card(
        color: Colors.red.shade50,
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.warning, color: Colors.red),
                  SizedBox(width: 10),
                  Text("Workout Skipped", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 10),
              Text(workout['reason']),
            ],
          ),
        ),
      );
    }

    return Card(
      color: Colors.green.shade50,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.fitness_center, color: Colors.green),
                const SizedBox(width: 10),
                Text(workout['workoutType'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            Text("Duration: ${workout['durationMinutes']} Minutes", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("Exercises:", style: TextStyle(fontWeight: FontWeight.bold)),
            for (String exercise in workout['exercises']) Text("• $exercise"),
            const SizedBox(height: 10),
            Text("Rest: ${workout['restDescription']}"),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.white,
              child: Text(
                "Note: ${workout['reason']}",
                style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.blueGrey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Adaptive Plan"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.deepPurple.shade50,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedDay,
                icon: const Icon(Icons.calendar_month, color: Colors.deepPurple),
                style: const TextStyle(fontSize: 18, color: Colors.deepPurple, fontWeight: FontWeight.bold),
                items: _daysOfWeek.map((String day) {
                  return DropdownMenuItem<String>(
                    value: day,
                    child: Text(day),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null && newValue != _selectedDay) {
                    setState(() {
                      _selectedDay = newValue;
                    });
                    _fetchAdaptivePlan();
                  }
                },
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _studyPlan == null
                    ? const Center(child: Text("Failed to generate plan."))
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                "Personalized Workout Plan",
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ),
                            _buildWorkoutRecommendation(_studyPlan!['workoutRecommendation']),
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                "Optimized Daily Schedule",
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (_studyPlan!['dailySchedule'].isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text("No schedule items for this day."),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _studyPlan!['dailySchedule'].length,
                                itemBuilder: (context, index) {
                                  return _buildScheduleItem(_studyPlan!['dailySchedule'][index]);
                                },
                              ),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
