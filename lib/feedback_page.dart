import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'services/api_service.dart';

class FeedbackPage extends StatefulWidget {
  final int userId;

  const FeedbackPage({super.key, required this.userId});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  bool _isSubmitting = false;

  // Selected Mood
  String _selectedMood = 'Good';

  // 1-5 Star Ratings for the 4 key modules
  int _studyPlanRating = 5;
  int _replanRating = 5;
  int _workoutRating = 5;
  int _nutritionRating = 5;

  // Text inputs
  final TextEditingController _missedReasonController = TextEditingController();
  final TextEditingController _suggestionsController = TextEditingController();

  final List<Map<String, String>> _moodOptions = [
    {'label': 'Great', 'emoji': '🤩'},
    {'label': 'Good', 'emoji': '🙂'},
    {'label': 'Okay', 'emoji': '😐'},
    {'label': 'Stressed', 'emoji': '😰'},
    {'label': 'Exhausted', 'emoji': '😫'},
  ];

  @override
  void dispose() {
    _missedReasonController.dispose();
    _suggestionsController.dispose();
    super.dispose();
  }

  String _ratingLabel(int stars) {
    switch (stars) {
      case 5:
        return "Excellent (5/5)";
      case 4:
        return "Very Good (4/5)";
      case 3:
        return "Good (3/5)";
      case 2:
        return "Fair (2/5)";
      case 1:
        return "Needs Work (1/5)";
      default:
        return "$stars / 5";
    }
  }

  Future<void> _submitFeedback() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    final String missedReason = _missedReasonController.text.trim();
    final String suggestions = _suggestionsController.text.trim();

    // Map ratings so existing database columns and transient category fields receive all values
    final Map<String, dynamic> payload = {
      'userId': widget.userId,
      'mood': _selectedMood,
      // Standard columns in MySQL student_feedback
      'academicLoadScore': _studyPlanRating,
      'plannerSatisfactionScore': _replanRating,
      'workoutDifficultyScore': _workoutRating,
      'missedActivityReason': missedReason.isNotEmpty ? missedReason : "Nutrition: $_nutritionRating/5 stars",
      'improvementSuggestions': suggestions,
      // Explicit module scores
      'studyPlanScore': _studyPlanRating,
      'replanScore': _replanRating,
      'workoutScore': _workoutRating,
      'nutritionScore': _nutritionRating,
    };

    final bool success = await ApiService.submitFeedback(payload);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      _showSuccessDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text("Failed to submit feedback. Please check your network and try again."),
              ),
            ],
          ),
          backgroundColor: Colors.redAccent.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          action: SnackBarAction(
            label: "Retry",
            textColor: Colors.white,
            onPressed: _submitFeedback,
          ),
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 56,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Thank You!",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Your feedback has been saved successfully. Our scheduling and wellness engine will use your input to keep improving your daily balance.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop(); // dismiss dialog
                  Navigator.of(context).pop(true); // exit feedback page
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: const Text(
                  "Done",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPastFeedbackSheet() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return FutureBuilder<List<dynamic>>(
              future: ApiService.getUserFeedback(widget.userId),
              builder: (context, snapshot) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.history_rounded, color: Colors.deepPurple),
                              SizedBox(width: 8),
                              Text(
                                "Your Past Feedback",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(sheetContext),
                          ),
                        ],
                      ),
                      const Divider(),
                      Expanded(
                        child: snapshot.connectionState == ConnectionState.waiting
                            ? const Center(
                                child: CircularProgressIndicator(color: Colors.deepPurple),
                              )
                            : snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.rate_review_outlined, size: 54, color: Colors.grey.shade400),
                                        const SizedBox(height: 12),
                                        Text(
                                          "No feedback submitted yet.",
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    controller: scrollController,
                                    itemCount: snapshot.data!.length,
                                    itemBuilder: (context, index) {
                                      final item = snapshot.data![index] as Map<String, dynamic>;
                                      final mood = item['mood'] ?? 'Okay';
                                      final createdAt = item['createdAt']?.toString() ?? '';
                                      final studyScore = item['academicLoadScore'] ?? 5;
                                      final replanScore = item['plannerSatisfactionScore'] ?? 5;
                                      final workoutScore = item['workoutDifficultyScore'] ?? 5;
                                      final suggestions = item['improvementSuggestions']?.toString() ?? '';

                                      String dateFormatted = "Recent";
                                      if (createdAt.isNotEmpty) {
                                        try {
                                          final dt = DateTime.parse(createdAt);
                                          dateFormatted = DateFormat('MMM d, yyyy • h:mm a').format(dt);
                                        } catch (_) {}
                                      }

                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: Colors.grey.shade200),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.deepPurple.shade50,
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: Text(
                                                    "Mood: $mood",
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 12,
                                                      color: Colors.deepPurple.shade700,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  dateFormatted,
                                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            Wrap(
                                              spacing: 12,
                                              runSpacing: 6,
                                              children: [
                                                _buildPastScoreBadge("Study", studyScore),
                                                _buildPastScoreBadge("Replan", replanScore),
                                                _buildPastScoreBadge("Workout", workoutScore),
                                              ],
                                            ),
                                            if (suggestions.isNotEmpty) ...[
                                              const SizedBox(height: 8),
                                              Text(
                                                "“$suggestions”",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontStyle: FontStyle.italic,
                                                  color: Colors.grey.shade700,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPastScoreBadge(String title, dynamic score) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "$title: ",
          style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w600),
        ),
        const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
        const SizedBox(width: 2),
        Text(
          "$score/5",
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ],
    );
  }

  // Header Banner Card
  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.shade700,
            Colors.deepPurple.shade500,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Your Voice Matters 💜",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Help CampusFit adapt to your lifestyle",
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Rate your experience across our key features. Your ratings directly guide our heuristic scheduling algorithms for realistic study breaks and fitness routines.",
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  // Section 1: Mood Selection
  Widget _buildMoodSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.sentiment_satisfied_alt_rounded, color: Colors.deepPurple, size: 20),
              SizedBox(width: 8),
              Text(
                "Daily Mood & Energy",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "How did you feel balancing studies and fitness today?",
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _moodOptions.map((m) {
              final isSelected = _selectedMood == m['label'];
              return GestureDetector(
                onTap: () => setState(() => _selectedMood = m['label']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.deepPurple.shade50 : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: Colors.deepPurple.withValues(alpha: 0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(m['emoji']!, style: const TextStyle(fontSize: 26)),
                      const SizedBox(height: 4),
                      Text(
                        m['label']!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.deepPurple : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Section 2: Star Rating Card for each module
  Widget _buildStarRatingCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required int rating,
    required ValueChanged<int> onRatingChanged,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 5 Star Buttons
              Row(
                children: List.generate(5, (index) {
                  final starNumber = index + 1;
                  final isFilled = starNumber <= rating;
                  return InkWell(
                    onTap: () => onRatingChanged(starNumber),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                      child: Icon(
                        isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 32,
                        color: isFilled ? Colors.amber.shade600 : Colors.grey.shade400,
                      ),
                    ),
                  );
                }),
              ),
              // Rating Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _ratingLabel(rating),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Section 3: Missed Activities Note
  Widget _buildMissedActivitiesSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.event_busy_rounded, color: Colors.deepOrange, size: 20),
              SizedBox(width: 8),
              Text(
                "Missed Any Activities Today? (Optional)",
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "Share why a class, study session, or workout was missed so replanning can better adapt.",
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _missedReasonController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: "e.g. Lab went overtime, transit delay, needed extra rest...",
              hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.deepPurple, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Section 4: Suggestions Box
  Widget _buildSuggestionsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, color: Colors.amber, size: 20),
              SizedBox(width: 8),
              Text(
                "Suggestions & Ideas (Optional)",
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "What new features or improvements would make CampusFit better for you?",
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _suggestionsController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Share any thoughts, feature requests, or improvements...",
              hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.deepPurple, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Section 5: Submit Button
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _submitFeedback,
        icon: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
              )
            : const Icon(Icons.send_rounded, size: 20),
        label: Text(
          _isSubmitting ? "Submitting Feedback..." : "Submit Feedback",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          "Student Feedback",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: "Back",
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: "Past Feedback",
            onPressed: _openPastFeedbackSheet,
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: "Close",
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroBanner(),
              const SizedBox(height: 18),
              _buildMoodSection(),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Row(
                  children: [
                    const Icon(Icons.star_half_rounded, color: Colors.deepPurple, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      "Module Experience Ratings",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      "1 to 5 Stars",
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _buildStarRatingCard(
                title: "Study Planning",
                subtitle: "Automated slot generation, class buffers & breaks",
                icon: Icons.menu_book_rounded,
                iconColor: Colors.deepPurple,
                rating: _studyPlanRating,
                onRatingChanged: (val) => setState(() => _studyPlanRating = val),
              ),
              _buildStarRatingCard(
                title: "Schedule Replanning",
                subtitle: "Missed interval recovery & break protection",
                icon: Icons.published_with_changes_rounded,
                iconColor: Colors.indigo,
                rating: _replanRating,
                onRatingChanged: (val) => setState(() => _replanRating = val),
              ),
              _buildStarRatingCard(
                title: "Workout Planning",
                subtitle: "Dynamic 20-60m sizing & evening slot selection",
                icon: Icons.fitness_center_rounded,
                iconColor: Colors.deepOrange,
                rating: _workoutRating,
                onRatingChanged: (val) => setState(() => _workoutRating = val),
              ),
              _buildStarRatingCard(
                title: "Nutrition & Meals",
                subtitle: "Meal logging, calories, macros & daily targets",
                icon: Icons.restaurant_rounded,
                iconColor: Colors.teal,
                rating: _nutritionRating,
                onRatingChanged: (val) => setState(() => _nutritionRating = val),
              ),
              const SizedBox(height: 14),
              _buildMissedActivitiesSection(),
              const SizedBox(height: 14),
              _buildSuggestionsSection(),
              const SizedBox(height: 24),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }
}
