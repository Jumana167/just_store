import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'chat_page.dart';
import '../services/chat_service.dart';
import 'app_theme.dart';
import 'chat_room_page.dart';

class ClothesDetailsPage extends StatelessWidget {
  final String image;
  final String title;
  final String description;
  final String price;
  final String phoneNumber;
  final String recipientId;
  final String recipientName;
  final String recipientAvatar;

  const ClothesDetailsPage({
    super.key,
    required this.image,
    required this.title,
    required this.description,
    required this.price,
    required this.phoneNumber,
    required this.recipientId,
    required this.recipientName,
    required this.recipientAvatar,
  });

  // Function to make phone call
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    final isOwnProduct = user?.uid == recipientId;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: AppTheme.white,
        centerTitle: true,
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // صورة الملابس
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: image.isNotEmpty
                  ? Image.network(
                image,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 250,
                  width: double.infinity,
                  color: theme.colorScheme.surface,
                  child: const Icon(Icons.checkroom, size: 64),
                ),
              )
                  : Container(
                height: 250,
                width: double.infinity,
                color: theme.colorScheme.surface,
                child: const Icon(Icons.checkroom, size: 64),
              ),
            ),
            const SizedBox(height: 20),

            // اسم المنتج
            Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // الوصف
            Text(
              description,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? theme.textTheme.bodyLarge?.color : AppTheme.darkGrey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // السعر
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.green),
              ),
              child: Text(
                '$price ${l10n.jd}',
                style: const TextStyle(
                  fontSize: 22,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // معلومات البائع
            if (!isOwnProduct) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundImage: recipientAvatar.isNotEmpty
                          ? NetworkImage(recipientAvatar)
                          : null,
                      child: recipientAvatar.isEmpty
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.seller,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            recipientName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // أزرار التواصل
              Text(
                l10n.contactSeller,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: phoneNumber.isNotEmpty
                          ? () => _makePhoneCall(phoneNumber)
                          : null,
                      icon: const Icon(Icons.call, color: Colors.white),
                      label: Text(l10n.call, style: const TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (user == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.pleaseLoginToChat)),
                          );
                          return;
                        }

                        try {
                          // Create chat service instance
                          final chatService = ChatService();

                          // Show loading
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );

                          // Create or get chat room ID
                          final String chatRoomId = await chatService.createOrGetChatRoom(recipientId);

                          if (!context.mounted) return;

                          // Hide loading
                          Navigator.pop(context);

                          // Navigate to chat page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatRoomPage(
                                chatRoomId: chatRoomId,
                                recipientId: recipientId,
                              ),
                            ),
                          );
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.pop(context); // Hide loading
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.errorStartingChat)),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.chat, color: Colors.white),
                      label: Text(l10n.chat, style: const TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // إذا كانت الملابس ملك المستخدم الحالي
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.withOpacity(AppTheme.primaryBlue, 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryBlue),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: AppTheme.primaryBlue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This is your item',
                        style: TextStyle(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}