import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:convert';
import 'settings_page.dart';
import 'app_theme.dart';

class RateAppPage extends StatefulWidget {
  const RateAppPage({super.key});

  @override
  State<RateAppPage> createState() => _RateAppPageState();
}

class _RateAppPageState extends State<RateAppPage> {
  String? selectedEmoji;
  double? rating;
  final TextEditingController feedbackController = TextEditingController();

  void _selectEmoji(String emojiKey) {
    setState(() {
      selectedEmoji = emojiKey;
      switch (emojiKey) {
        case 'bad':
          rating = 0.5;
          break;
        case 'ok':
          rating = 0.7;
          break;
        case 'good':
          rating = 0.9;
          break;
        case 'amazing':
          rating = 1.0;
          break;
      }
    });
  }

  Future<void> _submitFeedback() async {
    if (rating != null) {
      final prefs = await SharedPreferences.getInstance();
      final newRating = {
        'rating': rating,
        'feedback': feedbackController.text,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final String? ratingsJson = prefs.getString('app_ratings');
      List<Map<String, dynamic>> allRatings = [];

      if (ratingsJson != null) {
        allRatings = List<Map<String, dynamic>>.from(
          (json.decode(ratingsJson) as List).map((x) => Map<String, dynamic>.from(x)),
        );
      }

      allRatings.add(newRating);
      await prefs.setString('app_ratings', json.encode(allRatings));

      if (!mounted) return;

      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.feedbackSubmitted)),
      );

      setState(() {
        selectedEmoji = null;
        rating = null;
        feedbackController.clear();
      });
    }
  }

  void _cancel() {
    setState(() {
      selectedEmoji = null;
      rating = null;
      feedbackController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            );
          },
        ),
        title: Text(l10n.rateApp, style: const TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Image.asset('assets/bag_icon.png', height: 90),
                  const SizedBox(width: 12),
                  Text(
                    l10n.helloFriends,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                      fontFamily: 'AgentOrange',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: RichText(
                text: TextSpan(
                  text: l10n.whatDoYouThink,
                  style: TextStyle(color: textColor, fontSize: 16),
                  children: [
                    TextSpan(
                      text: ' Just Store',
                      style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: l10n.appQuestion),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildEmojiWithLabel('bad', 'assets/emoji_bad.png', l10n.bad),
                  _buildEmojiWithLabel('ok', 'assets/emoji_ok.png', l10n.ok),
                  _buildEmojiWithLabel('good', 'assets/emoji_good.png', l10n.good),
                  _buildEmojiWithLabel('amazing', 'assets/emoji_amazing.png', l10n.amazing),
                ],
              ),
            ),

            const SizedBox(height: 25),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.letUsKnow,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: feedbackController,
                maxLines: 3,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark ? AppTheme.darkGrey : AppTheme.white,
                  hintText: l10n.typeHere,
                  hintStyle: TextStyle(color: AppTheme.mediumGrey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _submitFeedback,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    ),
                    child: Text(l10n.submit, style: const TextStyle(color: Colors.white)),
                  ),
                  ElevatedButton(
                    onPressed: _cancel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    ),
                    child: Text(l10n.cancel, style: const TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomAppBar(
        color: AppTheme.primaryBlue,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Icon(Icons.home, color: Colors.white),
              Icon(Icons.chat, color: Colors.white),
              Icon(Icons.person, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmojiWithLabel(String key, String assetPath, String label) {
    final isSelected = selectedEmoji == key;
    return Column(
      children: [
        GestureDetector(
          onTap: () => _selectEmoji(key),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryBlue.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(assetPath, height: 40),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.primaryBlue : AppTheme.mediumGrey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}