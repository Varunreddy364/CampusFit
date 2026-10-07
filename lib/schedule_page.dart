import 'package:flutter/material.dart';
import 'services/api_service.dart';

class SchedulePage extends StatefulWidget {
  final int userId;

  const SchedulePage({Key? key, required this.userId}) : super(key: key);

  @override
  _SchedulePageState createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  List<dynamic> scheduleItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSchedule();
  }

  Future<void> _fetchSchedule() async {
    final items = await ApiService.getUserSchedule(widget.userId);
    setState(() {
      scheduleItems = items;
      isLoading = false;
    });
  }

  Future<void> _markAsMissed(int itemId) async {
    await ApiService.updateScheduleStatus(itemId, "MISSED");
    _fetchSchedule(); // Refresh list, Adaptive system reschedules in backend
  }

  Future<void> _markAsCompleted(int itemId) async {
    await ApiService.updateScheduleStatus(itemId, "COMPLETED");
    _fetchSchedule();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Adaptive Schedule"),
        backgroundColor: const Color.fromARGB(255, 94, 46, 176),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : scheduleItems.isEmpty
              ? const Center(child: Text("No schedule items found."))
              : ListView.builder(
                  itemCount: scheduleItems.length,
                  itemBuilder: (context, index) {
                    final item = scheduleItems[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        leading: Icon(
                          item['taskType'] == 'WORKOUT' ? Icons.fitness_center :
                          item['taskType'] == 'CLASS' ? Icons.school :
                          Icons.task,
                          color: item['status'] == 'MISSED' ? Colors.red : Colors.blue,
                        ),
                        title: Text(item['title']),
                        subtitle: Text("${item['taskType']} - Priority: ${item['priority']}\nStatus: ${item['status']}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (item['status'] == 'PENDING') ...[
                              IconButton(
                                icon: const Icon(Icons.check, color: Colors.green),
                                onPressed: () => _markAsCompleted(item['id']),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () => _markAsMissed(item['id']),
                              ),
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 94, 46, 176),
        onPressed: () {
           // TODO: Navigate to Add Task Page
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
