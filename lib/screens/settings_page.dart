// lib/screens/settings_page.dart - CORRECTED
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';
import 'voice_memos_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      ),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Card for Dark Mode
              Card(
                child: ListTile(
                  leading: Icon(
                    themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    color: Theme.of(context).primaryColor,
                  ),
                  title: const Text('Dark Mode'),
                  subtitle: Text(
                    themeProvider.isDarkMode ? 'Dark theme enabled' : 'Light theme enabled',
                  ),
                  trailing: Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (value) {
                      themeProvider.toggleTheme();
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Card for Voice Memos - Now correctly in its own Card
              Card(
                child: ListTile(
                  leading: const Icon(Icons.mic_none_outlined),
                  title: const Text('Voice Memos'),
                  subtitle: const Text('Listen to your recorded memos'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const VoiceMemosPage()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Card for About section
              Card(
                child: ListTile(
                  leading: Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
                  title: const Text('About'),
                  subtitle: const Text('ResQnow v1.0.0'),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'ResQnow',
                      applicationVersion: '1.0.0',
                      children: [
                        const Text('Your reliable partner in emergencies.'),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              
              // Card for Privacy Policy
              Card(
                child: ListTile(
                  leading: Icon(
                    Icons.privacy_tip_outlined,
                    color: Theme.of(context).primaryColor,
                  ),
                  title: const Text('Privacy Policy'),
                  subtitle: const Text('How we handle your data'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showInfoDialog(
                    context,
                    title: 'Privacy Policy',
                    content: '• All data is stored locally on your device.\n'
                        '• We do not collect personal information.\n'
                        '• Location data is only used for emergency services.\n'
                        '• Audio recordings are stored locally.',
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Card for Help & Support
              Card(
                child: ListTile(
                  leading: Icon(
                    Icons.help_outline,
                    color: Theme.of(context).primaryColor,
                  ),
                  title: const Text('Help & Support'),
                  subtitle: const Text('Get help using the app'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showInfoDialog(
                    context,
                    title: 'Help & Support',
                    content: '🚨 SOS: Tap the SOS button to start a countdown and alert your emergency contacts.\n\n'
                        '📱 Contacts: Add trusted contacts who will receive your SOS alerts.\n\n'
                        '🎙️ Memos: Use the "Record Memo" tool on the home page to record audio.',
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Helper function to show simple informational dialogs.
  void _showInfoDialog(BuildContext context, {required String title, required String content}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }
}