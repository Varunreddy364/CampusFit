import 'dart:convert';

void main() {
  List<dynamic> classes = jsonDecode('''[
    {
      "id": 1,
      "userId": 1,
      "subjectName": "daa",
      "dayOfWeek": "THURSDAY",
      "startTime": "09:00:00",
      "endTime": "10:00:00",
      "classType": "THEORY"
    }
  ]''');

  DateTime now = DateTime.now();
  int currentDayOfWeek = now.weekday; // 1 = Monday, 7 = Sunday
  DateTime startOfWeek = now.subtract(Duration(days: currentDayOfWeek - 1));

  for (var c in classes) {
    int dayIndex = 3; // THURSDAY = 3
    DateTime targetDate = startOfWeek.add(Duration(days: dayIndex));

    var startVal = c['startTime'];
    var endVal = c['endTime'];

    int startHour = 0, startMin = 0;
    int endHour = 0, endMin = 0;

    if (startVal is String) {
      List<String> startParts = startVal.split(':');
      startHour = int.parse(startParts[0]);
      startMin = int.parse(startParts[1]);
      List<String> endParts = (endVal as String).split(':');
      endHour = int.parse(endParts[0]);
      endMin = int.parse(endParts[1]);
    }

    DateTime startTime = DateTime(
      targetDate.year, targetDate.month, targetDate.day,
      startHour, startMin
    );

    DateTime endTime = DateTime(
      targetDate.year, targetDate.month, targetDate.day,
      endHour, endMin
    );

    if (endTime.isBefore(startTime)) {
      endTime = endTime.add(Duration(days: 1));
    }

    print("TargetDate: $targetDate");
    print("StartTime: $startTime");
    print("EndTime: $endTime");
    print("Duration: ${endTime.difference(startTime).inMinutes}");
  }
}
