// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/auth_page.dart';
import 'screens/home_page.dart';
import 'services/storage_service.dart';
import 'services/memo_service.dart';
import 'utils/theme.dart';
import 'utils/theme_provider.dart';
import 'package:receive_intent/receive_intent.dart';

// Import the AppActionController to provide it to the app
import 'screens/home_page.dart' show AppActionController;

Future<void> main() async {
  try {
    // 1. Ensure Flutter engine is ready
    WidgetsFlutterBinding.ensureInitialized();

    // 2. Initialize storage service
    final storageService = StorageService();
    await storageService.database; // Initialize database

    // 3. Initialize memo service
    final memoService = MemoService();
    await memoService.initialize();

    // 4. Load environment variables
    try {
      await dotenv.load(fileName: ".env");
      print("✅ Environment variables loaded");
    } catch (e) {
      print("⚠️ Could not load .env file: $e");
    }

    // 5. Check SharedPreferences to see if the user is logged in
    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final bool isFirstTime = prefs.getBool('isFirstTime') ?? true;

    // 6. Determine which screen to show first
    Widget initialScreen;
    if (isLoggedIn) {
      final userName = prefs.getString('userName') ?? "User";
      initialScreen = HomePage(userName: userName);
      print("✅ User logged in: $userName");
    } else {
      initialScreen = const AuthPage();
      print("📱 Showing auth page");
    }
    // 👇 Add this before runApp
    final receivedIntent = await ReceiveIntent.getInitialIntent();
    if (receivedIntent?.action == "com.resqnow.app.resq_fixed.TRIGGER_SOS") {
      // We'll pass a flag to HomePage so it knows it should trigger SOS
      initialScreen = HomePage(
          userName: prefs.getString('userName') ?? "User",
          shouldTriggerSOS: true);
    }
    // 7. Run the app with all necessary providers
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()..loadTheme()),
          ChangeNotifierProvider(create: (_) => AppActionController()),
          // Add more providers here as needed
        ],
        child: ResQnowApp(initialScreen: initialScreen),
      ),
    );

    print("✅ ResQnow app started successfully");
  } catch (e) {
    // If anything fails during startup, show a helpful error screen
    print("❌ Error during app initialization: $e");
    runApp(ErrorApp(error: e.toString()));
  }
}

/// The root widget of your application.
class ResQnowApp extends StatelessWidget {
  final Widget initialScreen;

  const ResQnowApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'ResQnow',
          debugShowCheckedModeBanner: false,

          // Theme configuration
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,

          // Initial screen
          home: initialScreen,

          // Global material app settings
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaleFactor: 1.0, // Prevent text scaling issues
              ),
              child: child!,
            );
          },
        );
      },
    );
  }
}

/// Error app to show when initialization fails
class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ResQnow - Error',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.red.shade50,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 80,
                    color: Colors.red.shade700,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "ResQnow Initialization Error",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "We encountered an error while starting the app:",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.red.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Text(
                      error,
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Please try restarting the app or contact support if the issue persists.",
                    style: TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Restart the app
                      main();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text("Restart App"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// App-wide constants
class AppConstants {
  static const String appName = 'ResQnow';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Your reliable partner in emergencies';

  // Emergency numbers
  static const String policeNumber = '100';
  static const String ambulanceNumber = '108';
  static const String fireNumber = '101';
  static const String emergencyNumber = '112';

  // Database settings
  static const String databaseName = 'resqnow.db';
  static const int databaseVersion = 1;

  // Audio settings
  static const int maxRecordingDurationSeconds = 600; // 10 minutes
  static const String audioFormat = 'aac';

  // Storage keys
  static const String keyIsLoggedIn = 'isLoggedIn';
  static const String keyIsFirstTime = 'isFirstTime';
  static const String keyUserName = 'userName';
  static const String keyUserPhone = 'userPhone';
  static const String keyIsDarkMode = 'isDarkMode';
}

/// Global utility functions
class AppUtils {
  static bool isValidPhoneNumber(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    return digits.length == 10;
  }

  static String formatPhoneNumber(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length == 10) {
      return '${digits.substring(0, 3)}-${digits.substring(3, 6)}-${digits.substring(6)}';
    }
    return phone;
  }

  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  static void showSnackBar(BuildContext context, String message,
      {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String content,
    String confirmText = 'Yes',
    String cancelText = 'No',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
