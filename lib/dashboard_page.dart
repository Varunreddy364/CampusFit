import 'package:flutter/material.dart';

import 'bmi_page.dart';
import 'profile_page.dart';
import 'view_profile_page.dart';
import 'login_page.dart';

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

            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Dashboard"),
              onTap: () {
                Navigator.pop(context);
              },
            ),

            ListTile(
              leading: const Icon(Icons.person),
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
              leading: const Icon(Icons.visibility),
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

            ListTile(
              leading: const Icon(Icons.fitness_center),
              title: const Text("Workout Plan"),
              onTap: () {},
            ),

            ListTile(
              leading: const Icon(Icons.restaurant),
              title: const Text("Nutrition"),
              onTap: () {},
            ),

            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text("Health"),
              onTap: () {},
            ),

            ListTile(
              leading: const Icon(Icons.feedback),
              title: const Text("Feedback"),
              onTap: () {},
            ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
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
                    onPressed: () {},
                    icon: const Icon(Icons.fitness_center),
                    label: const Text("Workout Plan"),
                  ),

                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BMIPage()),
                      );
                    },
                    icon: const Icon(Icons.monitor_weight),
                    label: const Text("BMI Calculator"),
                  ),

                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.restaurant),
                    label: const Text("Nutrition"),
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

  static Widget _buildCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.deepPurple),

          const SizedBox(height: 10),

          Text(title, textAlign: TextAlign.center),

          const SizedBox(height: 5),

          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
