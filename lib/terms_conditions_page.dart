import 'package:flutter/material.dart';
import 'login_page_v2.dart';
import 'settings_page.dart';
import 'app_theme.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.black : AppTheme.lightGrey;
    final primaryTextColor = isDark ? AppTheme.white : AppTheme.darkGrey;
    final secondaryTextColor = isDark ? AppTheme.withOpacity(AppTheme.white, 0.7) : AppTheme.withOpacity(AppTheme.darkGrey, 0.87);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlue,
        title: const Text('Terms & Conditions', style: TextStyle(color: AppTheme.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.white),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const SettingsPage()),
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Scrollbar(
          thickness: 4,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Last Updated: April 7, 2025',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                ),
                const SizedBox(height: 15),
                Text(
                  'Welcome to JUST STORE, a mobile application designed specifically for university students to buy, sell, and exchange educational and academic products easily and securely.',
                  style: TextStyle(color: secondaryTextColor),
                ),
                const SizedBox(height: 15),
                _buildSectionTitle('1. Definitions', primaryTextColor),
                _buildParagraph(
                  '"App": Refers to the JUST STORE mobile application.\n'
                  '"User": Any student using the app after registering with a valid university email address.\n'
                  '"Products": Includes books, slides, smart devices, scrubs, graduation robes, lab coats, dental tools, architecture tools, and other permitted educational items.',
                  secondaryTextColor,
                ),
                _buildSectionTitle('2. Registration Requirements', primaryTextColor),
                _buildParagraph(
                  'To use the app, the user must be a university student with a valid university email address.\n'
                  'During registration, the user must provide:\n'
                  '- A valid university email address\n'
                  '- A secure password\n'
                  '- A username\n'
                  'The user is responsible for maintaining the confidentiality of their account credentials.',
                  secondaryTextColor,
                ),
                _buildSectionTitle('3. Use of the App', primaryTextColor),
                _buildParagraph(
                  'It is strictly prohibited to use the app for any illegal or fraudulent activities.\n'
                  'Listing products that are unethical, unlawful, or unrelated to an educational environment is not allowed.\n'
                  'The user bears full responsibility for the quality and accuracy of the products listed.',
                  secondaryTextColor,
                ),
                _buildSectionTitle('4. App Disclaimer', primaryTextColor),
                _buildParagraph(
                  'JUST STORE operates solely as a platform connecting buyers and sellers and does not guarantee the completion of any transaction.\n'
                  'Users are encouraged to communicate with caution and verify the credibility of the other party before making any payments or exchanges.\n'
                  'The app is not liable for any damages or losses resulting from a sale or purchase.',
                  secondaryTextColor,
                ),
                _buildSectionTitle('5. Content', primaryTextColor),
                _buildParagraph(
                  'Users are allowed to upload product images and descriptions only.\n'
                  'Comments or any additional textual content are not permitted.',
                  secondaryTextColor,
                ),
                _buildSectionTitle('6. Intellectual Property', primaryTextColor),
                _buildParagraph(
                  'All intellectual property rights related to the app are reserved by JUST STORE.\n'
                  'No part of the app may be copied or reused without prior written permission.',
                  secondaryTextColor,
                ),
                _buildSectionTitle('7. Modifications', primaryTextColor),
                _buildParagraph(
                  'JUST STORE reserves the right to update or modify these terms at any time.\n'
                  'Users will be notified of any changes, and continued use of the app constitutes implied acceptance of the updated terms.',
                  secondaryTextColor,
                ),
                _buildSectionTitle('8. Support', primaryTextColor),
                _buildParagraph(
                  'For any inquiries or technical support, please contact us at:\nJust_store@gmail.com',
                  secondaryTextColor,
                ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("✅ THANK YOU")),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      ),
                      child: const Text('Accept'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) =>  const LoginPageV2()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      ),
                      child: const Text('Decline'),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          color: color,
          height: 1.5,
        ),
      ),
    );
  }
}
