import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'app_theme.dart';

class ContactInfoPage extends StatefulWidget {
  const ContactInfoPage({super.key});

  @override
  State<ContactInfoPage> createState() => _ContactInfoPageState();
}

class _ContactInfoPageState extends State<ContactInfoPage> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController whatsappController = TextEditingController();
  bool remember = false;
  bool isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSavedInfo();
  }

  Future<void> _loadSavedInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      phoneController.text = prefs.getString('phone') ?? '';
      whatsappController.text = prefs.getString('whatsapp') ?? '';
      remember = prefs.getBool('remember_contact') ?? false;
      _updateButtonState();
    });
  }

  void _updateButtonState() {
    setState(() {
      isButtonEnabled = phoneController.text.isNotEmpty || whatsappController.text.isNotEmpty;
    });
  }

  Future<void> _saveInfo() async {
    if (remember) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('phone', phoneController.text);
      await prefs.setString('whatsapp', whatsappController.text);
      await prefs.setBool('remember_contact', true);
    }
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, bool isDark, String hint) {
    return TextField(
      controller: controller,
      onChanged: (_) => _updateButtonState(),
      style: TextStyle(color: isDark ? AppTheme.white : AppTheme.darkGrey),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppTheme.mediumGrey),
        filled: true,
        fillColor: isDark ? AppTheme.darkGrey : AppTheme.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.borderGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryBlue),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlue,
        centerTitle: true,
        title: Text(l10n.contactUs, style: const TextStyle(color: AppTheme.white)),
        iconTheme: const IconThemeData(color: AppTheme.white),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 25),
        child: ListView(
          children: [
            const SizedBox(height: 10),
            _buildSectionTitle(l10n.phone, isDark ? AppTheme.white : AppTheme.darkGrey),
            const SizedBox(height: 8),
            _buildTextField(phoneController, isDark, "+962-7xxx-xxxx"),
            const SizedBox(height: 20),
            _buildSectionTitle("WhatsApp ${l10n.phone}", isDark ? AppTheme.white : AppTheme.darkGrey),
            const SizedBox(height: 8),
            _buildTextField(whatsappController, isDark, "+962-7xxx-xxxx"),
            const SizedBox(height: 20),
            Row(
              children: [
                Checkbox(
                  value: remember,
                  activeColor: AppTheme.primaryBlue,
                  onChanged: (val) {
                    setState(() {
                      remember = val ?? false;
                      _updateButtonState();
                    });
                  },
                ),
                Text(
                  l10n.rememberMe,
                  style: TextStyle(color: isDark ? AppTheme.white : AppTheme.darkGrey),
                ),
              ],
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: isButtonEnabled ? _saveInfo : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: AppTheme.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}