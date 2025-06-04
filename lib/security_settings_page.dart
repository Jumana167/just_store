import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SecuritySettingsPage extends StatefulWidget {
  const SecuritySettingsPage({super.key});

  @override
  State<SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends State<SecuritySettingsPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController currentPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool showPassword = false;
  bool isLoading = false;
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    emailController.text = user?.email ?? '';
  }

  Future<void> reauthenticateUser(String password) async {
    final credential = EmailAuthProvider.credential(
      email: user!.email!,
      password: password,
    );
    await user!.reauthenticateWithCredential(credential);
  }

  Future<void> saveChanges() async {
    setState(() => isLoading = true);

    try {
      await reauthenticateUser(currentPasswordController.text.trim());

      if (emailController.text.trim() != user?.email) {
        await _updateEmail(emailController.text.trim());
        await user?.sendEmailVerification();
        _showSuccess('✔ Email updated. Check your Outlook.');
        setState(() => isLoading = false);
        return;
      }

      if (newPasswordController.text.isNotEmpty) {
        if (newPasswordController.text == confirmPasswordController.text) {
          await user?.updatePassword(newPasswordController.text);
          _showSuccess('✔ Password updated successfully');
        } else {
          _showError('❌ Passwords do not match');
          return;
        }
      }

      if (newPasswordController.text.isEmpty) {
        _showSuccess('✔ No changes detected.');
      }
    } catch (e) {
      _showError('❌ ${e.toString()}');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateEmail(String newEmail) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.verifyBeforeUpdateEmail(newEmail);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Verification email sent. Please check your inbox.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating email: $e')),
        );
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    const Color mainColor = Color(0xFF3B3B98);
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color fieldColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildHeader(mainColor),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel("Edit your universal email:", textColor),
                const SizedBox(height: 8),
                _buildInputField(emailController, fieldColor, textColor),

                const SizedBox(height: 20),
                _buildLabel("Current Password (for verification):", textColor),
                const SizedBox(height: 8),
                _buildInputField(currentPasswordController, fieldColor, textColor, isPassword: true),

                const SizedBox(height: 20),
                _buildLabel("New Password:", textColor),
                const SizedBox(height: 8),
                _buildInputField(newPasswordController, fieldColor, textColor, isPassword: true),

                const SizedBox(height: 20),
                _buildLabel("Confirm New Password:", textColor),
                const SizedBox(height: 8),
                _buildInputField(confirmPasswordController, fieldColor, textColor, isPassword: true),

                const SizedBox(height: 30),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : saveChanges,
                    icon: isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                        : const Icon(Icons.save),
                    label: Text(isLoading ? "Saving..." : "Save"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainColor,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color mainColor) {
    return Stack(
      children: [
        Container(
          height: 140,
          decoration: BoxDecoration(
            color: mainColor,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(50),
              bottomRight: Radius.circular(50),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 10, top: 10),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 10),
                const Text(
                  "Security Settings",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Text(text, style: TextStyle(fontWeight: FontWeight.bold, color: color));
  }

  Widget _buildInputField(TextEditingController controller, Color bgColor, Color textColor, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? !showPassword : false,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(showPassword ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => showPassword = !showPassword),
        )
            : null,
        filled: true,
        fillColor: bgColor,
        hintText: isPassword ? '********' : '',
        hintStyle: TextStyle(color: Colors.grey[500]),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}