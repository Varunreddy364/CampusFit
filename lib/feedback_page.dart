import 'package:flutter/material.dart';
import 'services/api_service.dart';

class FeedbackPage extends StatefulWidget {
  final int userId;

  const FeedbackPage({super.key, required this.userId});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isSubmitting = false;

  String _mood = 'Okay';
  double _academicLoad = 5;
  double _workoutDifficulty = 5;
  double _plannerSatisfaction = 5;
  String _missedReason = '';
  String _suggestions = '';

  final List<Map<String, String>> _moods = [
    {'label': 'Exhausted', 'emoji': '😫'},
    {'label': 'Stressed', 'emoji': '😰'},
    {'label': 'Okay', 'emoji': '😐'},
    {'label': 'Good', 'emoji': '🙂'},
    {'label': 'Great', 'emoji': '🤩'},
  ];

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitFeedback();
    }
  }

  void _submitFeedback() async {
    setState(() => _isSubmitting = true);

    final Map<String, dynamic> data = {
      'userId': widget.userId,
      'mood': _mood,
      'academicLoadScore': _academicLoad.toInt(),
      'workoutDifficultyScore': _workoutDifficulty.toInt(),
      'plannerSatisfactionScore': _plannerSatisfaction.toInt(),
      'missedActivityReason': _missedReason.trim(),
      'improvementSuggestions': _suggestions.trim(),
    };

    final bool success = await ApiService.submitFeedback(data);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      // Transition to celebration screen
      _pageController.animateToPage(
        4,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeIn,
      );
      // Wait briefly then close page and return to dashboard
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit feedback. Please check server connection.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildMoodCheckIn() {
    return _buildCardWrapper(
      title: "Daily Mood Check-in",
      subtitle: "How are you feeling today?",
      child: Wrap(
        alignment: WrapAlignment.spaceEvenly,
        spacing: 10,
        runSpacing: 10,
        children: _moods.map((m) {
          bool isSelected = _mood == m['label'];
          return GestureDetector(
            onTap: () => setState(() => _mood = m['label']!),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.deepPurple.shade100 : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? Colors.deepPurple : Colors.transparent, width: 2),
                boxShadow: [
                  if (!isSelected)
                    BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
                ],
              ),
              child: Column(
                children: [
                  Text(m['emoji']!, style: TextStyle(fontSize: 32)),
                  SizedBox(height: 8),
                  Text(m['label']!, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.deepPurple : Colors.black54)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSliders() {
    return _buildCardWrapper(
      title: "Activity Feedback",
      subtitle: "Rate your experience out of 10",
      child: Column(
        children: [
          _buildCustomSlider("Academic Load (1 = Very Light, 10 = Very Heavy)", _academicLoad, (v) => setState(() => _academicLoad = v)),
          SizedBox(height: 20),
          _buildCustomSlider("Workout Difficulty (1 = Too Easy, 10 = Too Hard)", _workoutDifficulty, (v) => setState(() => _workoutDifficulty = v)),
          SizedBox(height: 20),
          _buildCustomSlider("Planner Satisfaction (1 = Poor, 10 = Perfect)", _plannerSatisfaction, (v) => setState(() => _plannerSatisfaction = v)),
        ],
      ),
    );
  }

  Widget _buildCustomSlider(String label, double value, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple.shade700)),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: Colors.deepPurple,
            inactiveTrackColor: Colors.deepPurple.shade100,
            thumbColor: Colors.deepPurpleAccent,
            valueIndicatorColor: Colors.deepPurple,
          ),
          child: Slider(
            value: value,
            min: 1,
            max: 10,
            divisions: 9,
            label: value.round().toString(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildTextInputs() {
    return _buildCardWrapper(
      title: "Deep Dive",
      subtitle: "Help CampusFit adapt to your needs",
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              labelText: "Why did you miss any activities today?",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
            maxLines: 3,
            onChanged: (v) => _missedReason = v,
          ),
          SizedBox(height: 20),
          TextField(
            decoration: InputDecoration(
              labelText: "Any suggestions to improve the planner?",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
            maxLines: 3,
            onChanged: (v) => _suggestions = v,
          ),
        ],
      ),
    );
  }

  Widget _buildAIInsight() {
    return _buildCardWrapper(
      title: "AI Insight Analysis",
      subtitle: "CampusFit has analyzed your week",
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200)
        ),
        child: Column(
          children: [
            Icon(Icons.auto_awesome, color: Colors.blue, size: 40),
            SizedBox(height: 10),
            Text(
              "Based on your recent missed tasks, we recommend allocating smaller 30-minute study blocks instead of large 2-hour blocks to improve completion rates. Your feedback helps us tune these blocks perfectly for you!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.blue.shade900),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCelebration() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 90),
            const SizedBox(height: 20),
            const Text(
              "Feedback Saved!",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            const Text(
              "Redirecting to dashboard...",
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                if (mounted) Navigator.of(context).pop(true);
              },
              icon: const Icon(Icons.dashboard_rounded, color: Colors.deepPurple),
              label: const Text(
                "Go to Dashboard",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.deepPurple),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardWrapper({required String title, required String subtitle, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(fontSize: 16, color: Colors.white70)),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 8))],
            ),
            child: child,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade800, Colors.deepPurpleAccent.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        ),
        child: SafeArea(
          child: Stack(
            children: [
              if (_currentPage < 4)
                Positioned(
                  top: 20,
                  right: 20,
                  child: IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              PageView(
                controller: _pageController,
                physics: NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _buildMoodCheckIn(),
                  _buildSliders(),
                  _buildTextInputs(),
                  _buildAIInsight(),
                  _buildCelebration(),
                ],
              ),
              if (_currentPage < 4)
                Positioned(
                  bottom: 40,
                  left: 20,
                  right: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: List.generate(4, (index) => Container(
                          margin: EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: _currentPage == index ? 24 : 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index ? Colors.white : Colors.white54,
                            borderRadius: BorderRadius.circular(4)
                          ),
                        )),
                      ),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.deepPurple,
                          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
                        ),
                        child: _isSubmitting 
                            ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(_currentPage == 3 ? "Submit" : "Next", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      )
                    ],
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}
