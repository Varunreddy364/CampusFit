import 'package:flutter/material.dart';

import 'nutrition_page.dart';
import 'bmi_page.dart';
import 'profile_page.dart';
import 'view_profile_page.dart';
import 'login_page.dart';
import 'feedback_page.dart';
import 'academic_schedule_page.dart';
import 'weekly_timetable_page.dart';
import 'academic_tasks_page.dart';
import 'study_plan_page.dart';
import 'workout_plan_page.dart';

class DashboardPage extends StatelessWidget {
  final int userId;
  final String userName;

  const DashboardPage({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("CampusFit"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),

      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                ),
              ),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Colors.deepPurple),
              ),
              accountName: Text(
                userName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              accountEmail: const Text("CampusFit Member"),
            ),

            // --- GENERAL ---
            ListTile(
              leading: const Icon(Icons.home_rounded, color: Colors.deepPurple),
              title: const Text("Dashboard"),
              onTap: () {
                Navigator.pop(context);
              },
            ),

            ListTile(
              leading: const Icon(Icons.person_rounded),
              title: const Text("Profile"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfilePage(userId: userId),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.visibility_rounded),
              title: const Text("View Profile"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ViewProfilePage(userId: userId),
                  ),
                );
              },
            ),

            const Divider(height: 24, thickness: 1),
            _buildDrawerSectionHeader("ACADEMIC"),

            ListTile(
              leading: const Icon(Icons.table_chart_rounded),
              title: const Text("Weekly Timetable"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WeeklyTimetablePage(userId: userId),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.calendar_month_rounded),
              title: const Text("Academic Schedule"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AcademicSchedulePage(userId: userId),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.task_alt_rounded),
              title: const Text("Academic Tasks"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AcademicTasksPage(userId: userId),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.psychology_rounded),
              title: const Text("Study Plan"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StudyPlanPage(userId: userId),
                  ),
                );
              },
            ),

            const Divider(height: 24, thickness: 1),
            _buildDrawerSectionHeader("FITNESS & WELLNESS"),

            ListTile(
              leading: const Icon(Icons.fitness_center_rounded),
              title: const Text("Workout Plan"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WorkoutPlanPage(userId: userId),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.restaurant_rounded),
              title: const Text("Nutrition"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NutritionPage(userId: userId),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.monitor_heart_rounded),
              title: const Text("Health & BMI"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BMIPage(userId: userId),
                  ),
                );
              },
            ),

            const Divider(height: 24, thickness: 1),
            _buildDrawerSectionHeader("ACCOUNT & FEEDBACK"),

            ListTile(
              leading: const Icon(Icons.feedback_rounded),
              title: const Text("Feedback Experience"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => FeedbackPage(userId: userId)),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: const Text("Logout", style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => LoginPage()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),

      body: Container(
        color: const Color(0xFFF5F7FB),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome Back,",
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),

              Text(
                userName,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 25),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Motivation",
                      style: TextStyle(color: Colors.white70),
                    ),

                    SizedBox(height: 10),

                    Text(
                      "Stay Consistent.\nResults Will Follow.",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                "Quick Actions",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 15),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ViewProfilePage(userId: userId),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility),
                    label: const Text("View Profile"),
                  ),

                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfilePage(userId: userId),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text("Edit Profile"),
                  ),

                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WorkoutPlanPage(userId: userId),
                        ),
                      );
                    },
                    icon: const Icon(Icons.fitness_center),
                    label: const Text("Workout Plan"),
                  ),

                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => BMIPage(userId: userId)),
                      );
                    },
                    icon: const Icon(Icons.monitor_heart),
                    label: const Text("Health & BMI"),
                  ),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NutritionPage(userId: userId),
                        ),
                      );
                    },
                    child: const Text("Nutrition Tracker"),
                  ),


                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FeedbackPage(userId: userId),
                        ),
                      );
                    },
                    icon: const Icon(Icons.star),
                    label: const Text("Feedback Experience"),
                  ),

                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WeeklyTimetablePage(userId: userId),
                        ),
                      );
                    },
                    icon: const Icon(Icons.table_chart),
                    label: const Text("Weekly Timetable"),
                  ),

                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AcademicSchedulePage(userId: userId),
                        ),
                      );
                    },
                    icon: const Icon(Icons.calendar_month),
                    label: const Text("Academic Schedule"),
                  ),

                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AcademicTasksPage(userId: userId),
                        ),
                      );
                    },
                    icon: const Icon(Icons.task_alt),
                    label: const Text("Academic Tasks"),
                  ),

                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StudyPlanPage(userId: userId),
                        ),
                      );
                    },
                    icon: const Icon(Icons.psychology),
                    label: const Text("Study Plan"),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              const Text(
                "Motivation",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    "Consistency beats intensity. Keep going every day and success will follow.",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: Colors.grey.shade500,
        ),
      ),
    );
  }
}
