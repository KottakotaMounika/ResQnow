import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'create_profile_page.dart';

class OnboardingPage extends StatefulWidget {
const OnboardingPage({super.key});

@override
State<OnboardingPage> createState() => _OnboardingPageState();
}

// ✅ IMPROVEMENT: Add WidgetsBindingObserver to detect when the app is resumed.
class _OnboardingPageState extends State<OnboardingPage> with WidgetsBindingObserver {
PermissionStatus _locationStatus = PermissionStatus.denied;
PermissionStatus _microphoneStatus = PermissionStatus.denied;
// ✅ REMOVED: _smsStatus variable is no longer needed.

@override
void initState() {
super.initState();
// ✅ IMPROVEMENT: Start listening to app lifecycle events.
WidgetsBinding.instance.addObserver(this);
_checkAllPermissions();
}

@override
void dispose() {
// ✅ IMPROVEMENT: Stop listening to app lifecycle events.
WidgetsBinding.instance.removeObserver(this);
super.dispose();
}

/// ✅ IMPROVEMENT: Automatically re-check permissions when user returns to the app.
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
if (state == AppLifecycleState.resumed) {
_checkAllPermissions();
}
}

/// Checks the status of all required permissions.
Future<void> _checkAllPermissions() async {
final location = await Permission.location.status;
final microphone = await Permission.microphone.status;
if (mounted) {
setState(() {
_locationStatus = location;
_microphoneStatus = microphone;
});
}
}

/// ✅ IMPROVEMENT: Simplified request logic.
/// After requesting, it re-checks all permissions to update the UI.
Future<void> _requestPermission(Permission permission) async {
await permission.request();
// After the user responds, re-check all statuses to refresh the screen.
_checkAllPermissions();
}

void _navigateToNextPage() {
if (mounted) {
Navigator.pushReplacement(
context,
MaterialPageRoute(builder: (_) => const CreateProfilePage()),
);
}
}

@override
Widget build(BuildContext context) {
// Continue button is enabled only if the required permission (location) is granted.
final bool canContinue = _locationStatus.isGranted;

return Scaffold(
body: SafeArea(
child: Padding(
padding: const EdgeInsets.all(24.0),
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
const Icon(Icons.shield_outlined, size: 60, color: Colors.blue),
const SizedBox(height: 24),
const Text(
"App Permissions",
style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
),
const SizedBox(height: 16),
const Text(
"To keep you safe, ResQnow needs access to the following features.",
textAlign: TextAlign.center,
style: TextStyle(fontSize: 16, color: Colors.grey),
),
const SizedBox(height: 40),
_buildPermissionTile(
permission: Permission.location,
status: _locationStatus,
title: "Location (Required)",
subtitle: "To share your position during an SOS.",
icon: Icons.location_on_outlined,
),
// ✅ REMOVED: The permission tile for SMS is gone.
_buildPermissionTile(
permission: Permission.microphone,
status: _microphoneStatus,
title: "Microphone (Optional)",
subtitle: "To enable voice commands and memos.",
icon: Icons.mic_none_outlined,
),
const Spacer(),
ElevatedButton(
onPressed: canContinue ? _navigateToNextPage : null,
style: ElevatedButton.styleFrom(
minimumSize: const Size(double.infinity, 50),
disabledBackgroundColor: Colors.grey.shade300,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
),
child: const Text("Continue"),
),
],
),
),
),
);
}

Widget _buildPermissionTile({
required Permission permission,
required PermissionStatus status,
required String title,
required String subtitle,
required IconData icon,
}) {
Widget trailingWidget;
Color leadingColor = status.isGranted ? Colors.green : Theme.of(context).primaryColor;

if (status.isGranted) {
trailingWidget = const Icon(Icons.check_circle, color: Colors.green, size: 30);
} else if (status.isPermanentlyDenied) {
trailingWidget = TextButton(onPressed: openAppSettings, child: const Text("Settings"));
} else {
trailingWidget = ElevatedButton(
onPressed: () => _requestPermission(permission),
child: const Text("Allow"),
);
}

return Card(
margin: const EdgeInsets.symmetric(vertical: 8),
child: ListTile(
leading: Icon(icon, color: leadingColor),
title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
subtitle: Text(subtitle),
trailing: trailingWidget,
),
);
}
}