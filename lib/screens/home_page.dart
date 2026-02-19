// lib/screens/home_page.dart - FIXED
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// Models and Services
import '../models/contact_model.dart';
import '../models/memo_model.dart'; // <-- 1. IMPORT MEMO MODEL
import '../services/location_service.dart';
import '../services/storage_service.dart';

// Other Pages
import 'fire_services_page.dart';
import 'auth_page.dart';
import 'chatbot_page.dart';
import 'first_aid_page.dart';
import 'hospital_services_page.dart';
import 'live_tracking_page.dart';
import 'manage_contacts_page.dart';
import 'medical_profile_page.dart';
import 'police_services_page.dart';
import 'settings_page.dart';
import '../utils/theme.dart';

enum SosState { initial, sending, sent, error }

class AppActionController extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final StorageService _storageService = StorageService();

  final ValueNotifier<bool> isSirenPlaying = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isRecording = ValueNotifier<bool>(false);
  final ValueNotifier<SosState> sosState = ValueNotifier(SosState.initial);
  final ValueNotifier<String> statusMessage = ValueNotifier('');
  final ValueNotifier<LatLng?> userLocation = ValueNotifier(null);

  final List<Contact> _defaultContacts = [
    Contact(
        name: "National Emergency",
        phone: "112",
        isEmergency: true,
        relationship: "Official Service"),
    Contact(
        name: "Police",
        phone: "100",
        isEmergency: true,
        relationship: "Official Service"),
    Contact(
        name: "Ambulance",
        phone: "108",
        isEmergency: true,
        relationship: "Official Service"),
    Contact(
        name: "Fire Brigade",
        phone: "101",
        isEmergency: true,
        relationship: "Official Service"),
  ];

  AppActionController() {
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    await _recorder.openRecorder();
  }

  // --- 2. THIS METHOD IS NOW CORRECTED ---
  /// Toggles audio recording and saves the memo to the database.
  Future<String> toggleRecording() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      return "Microphone permission is required to record.";
    }

    if (_recorder.isStopped) {
      // Create a unique filename for each recording
      final tempDir = await getTemporaryDirectory();
      final filePath = p.join(
          tempDir.path, 'memo_${DateTime.now().millisecondsSinceEpoch}.aac');

      await _recorder.startRecorder(toFile: filePath, codec: Codec.aacMP4);
      isRecording.value = true;
      return "Recording started.";
    } else {
      final path = await _recorder.stopRecorder();
      isRecording.value = false;

      if (path != null) {
        print('Recorded file saved at: $path');

        // Create a new Memo object with the recording details
        final newMemo = Memo(
          filePath: path,
          recordedAt: DateTime.now(),
          // durationMs can be enhanced later if the recorder provides it
        );

        // Save the new memo to the database
        await _storageService.insertMemo(newMemo);

        return "Recording stopped. Memo saved successfully.";
      } else {
        print('Recording failed, path is null.');
        return "Recording failed to save.";
      }
    }
  }

  // --- Other public methods remain unchanged ---
  Future<String> triggerSOS(BuildContext context) async {
    final bool confirmed = await _showSosConfirmationDialog(context);
    if (!confirmed) return "SOS Canceled by user.";

    final status = await Permission.location.request();

    if (status.isGranted) {
      sosState.value = SosState.sending;
      statusMessage.value = "Sending SOS... Requesting location...";
      await _executeSosFlow();
      if (sosState.value == SosState.sent) {
        return "SOS sequence initiated. Location sent to emergency contacts.";
      } else {
        return "SOS failed. Could not get location or send message.";
      }
    } else {
      statusMessage.value = "Location permission denied. Cannot send SOS.";
      sosState.value = SosState.error;
      if (status.isPermanentlyDenied) await openAppSettings();
      return "SOS failed: Location permission was denied.";
    }
  }

  Future<String> findNearbyHospitals(BuildContext context) async {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const HospitalServicesPage()));
    return "Showing nearby hospitals.";
  }

  Future<String> findPoliceStations(BuildContext context) async {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const PoliceServicesPage()));
    return "Showing police services.";
  }

  Future<String> toggleSiren() async {
    if (isSirenPlaying.value) {
      await _audioPlayer.stop();
    } else {
      await _audioPlayer.play(AssetSource('siren.mp3'));
    }
    isSirenPlaying.value = !isSirenPlaying.value;
    return isSirenPlaying.value ? "Siren activated." : "Siren deactivated.";
  }

  Future<void> _executeSosFlow() async {
    final locationResult = await LocationService.getCurrentLocation();
    locationResult.fold(
      (errorMessage) {
        statusMessage.value = errorMessage;
        sosState.value = SosState.error;
      },
      (position) async {
        userLocation.value = LatLng(position.latitude, position.longitude);
        statusMessage.value = "Location found! Opening live tracking...";
        sosState.value = SosState.sent;

        final mapLink =
            'http://maps.google.com/?q=${position.latitude},${position.longitude}';
        final message =
            'EMERGENCY! I need help. My current location is: $mapLink';
        await _sendSmsToEmergencyContacts(message);
      },
    );
  }

  Future<bool> _showSosConfirmationDialog(BuildContext context) async {
    await _audioPlayer.play(AssetSource('siren.mp3'));
    final bool confirmed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) =>
              CountdownDialog(onCancel: () => Navigator.of(context).pop(false)),
        ) ??
        false;
    await _audioPlayer.stop();
    return confirmed;
  }

  Future<bool> _sendSmsToEmergencyContacts(String message) async {
    final userAddedEmergencyContacts =
        await _storageService.getEmergencyContacts();
    final allEmergencyContacts = [
      ..._defaultContacts,
      ...userAddedEmergencyContacts
    ];
    final Set<String> recipientPhones =
        allEmergencyContacts.map((c) => c.phone).toSet();
    final String recipientsString = recipientPhones.join(',');

    if (recipientsString.isEmpty) {
      print("SOS FAILED: No emergency contacts are available.");
      return false;
    }

    final Uri smsUri = Uri(
        scheme: 'sms',
        path: recipientsString,
        queryParameters: {'body': message});

    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
        return true;
      }
      return false;
    } catch (error) {
      print(
          'SOS FAILED: An error occurred while launching the SMS app: $error');
      return false;
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _recorder.closeRecorder();
    isSirenPlaying.dispose();
    isRecording.dispose();
    sosState.dispose();
    statusMessage.dispose();
    userLocation.dispose();
    super.dispose();
  }
}

// --- UI WIDGETS ---
// The rest of your UI code does not need any changes.

class HomePage extends StatefulWidget {
  final String userName;
  final bool shouldTriggerSOS; // 👈 ADD THIS

  const HomePage({
    super.key,
    required this.userName,
    this.shouldTriggerSOS = false, // 👈 DEFAULT VALUE
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 1;
  late final AppActionController _appController;

  @override
  void initState() {
    super.initState();
    _appController = Provider.of<AppActionController>(context, listen: false);
    _appController.sosState.addListener(_handleSosStateChange);

    // If the app was opened to trigger SOS, call the controller AFTER first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.shouldTriggerSOS) {
        // small delay to ensure UI is ready and any permissions dialogs won't be blocked
        Future.delayed(const Duration(milliseconds: 200), () {
          if (!mounted) return;
          // triggerSOS requires a BuildContext, so we pass the state's context
          _appController.triggerSOS(context);
        });
      }
    });
  }

  void _handleSosStateChange() {
    final state = _appController.sosState.value;
    final message = _appController.statusMessage.value;
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (state == SosState.sent) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.green));
      if (_appController.userLocation.value != null) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => LiveTrackingPage(
                    userLocation: _appController.userLocation.value!)));
      }
    } else if (state == SosState.error) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red));
    }
    if (state != SosState.sending && state != SosState.initial) {
      _appController.sosState.value = SosState.initial;
    }
  }

  @override
  void dispose() {
    _appController.sosState.removeListener(_handleSosStateChange);
    super.dispose();
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    if (mounted) {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AuthPage()),
          (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      ChatbotPage(),
      _HomeDashboard(userName: widget.userName),
      const SettingsPage(),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('ResQnow'), actions: [
        IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: _logout)
      ]),
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.support_agent_outlined),
              activeIcon: Icon(Icons.support_agent),
              label: 'Bot'),
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings'),
        ],
      ),
    );
  }
}

class _HomeDashboard extends StatelessWidget {
  const _HomeDashboard({required this.userName});
  final String userName;

  @override
  Widget build(BuildContext context) {
    final appController =
        Provider.of<AppActionController>(context, listen: false);

    return AnimationLimiter(
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 375),
          childAnimationBuilder: (widget) => SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(child: widget),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                "Hey $userName, stay safe.",
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            _SosCard(onTap: () => appController.triggerSOS(context)),
            _ToolsCard(controller: appController),
            Padding(
              padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
              child: Text("Emergency Services",
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            const _ServicesGrid(),
          ],
        ),
      ),
    );
  }
}

class _SosCard extends StatefulWidget {
  const _SosCard({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_SosCard> createState() => _SosCardState();
}

class _SosCardState extends State<_SosCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
      lowerBound: 0.98,
      upperBound: 1.0,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animationController,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        elevation: 4,
        shadowColor: Colors.red.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [AppTheme.emergencyColor, Colors.red.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: const [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.white, size: 60),
                SizedBox(height: 16),
                Text("EMERGENCY SOS",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                SizedBox(height: 8),
                Text(
                    "Tap to send an immediate SMS alert with your location to emergency contacts.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolsCard extends StatelessWidget {
  const _ToolsCard({required this.controller});
  final AppActionController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          children: [
            Text("Emergency Tools",
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ToolButton(
                  label: "Siren",
                  valueListenable: controller.isSirenPlaying,
                  onPressed: controller.toggleSiren,
                  activeIcon: Icons.stop_circle_outlined,
                  inactiveIcon: Icons.volume_up_outlined,
                ),
                _ToolButton(
                  label: "Record Memo",
                  valueListenable: controller.isRecording,
                  onPressed: controller.toggleRecording,
                  activeIcon: Icons.stop_rounded,
                  inactiveIcon: Icons.mic_none_outlined,
                  activeColor: Colors.red.shade400,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.label,
    required this.valueListenable,
    required this.onPressed,
    required this.activeIcon,
    required this.inactiveIcon,
    this.activeColor,
  });

  final String label;
  final ValueNotifier<bool> valueListenable;
  final VoidCallback onPressed;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ValueListenableBuilder<bool>(
          valueListenable: valueListenable,
          builder: (context, isActive, child) {
            return ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(24),
                backgroundColor: isActive
                    ? (activeColor ?? Colors.grey.shade600)
                    : Theme.of(context).colorScheme.secondary,
                foregroundColor: Colors.white,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: Icon(isActive ? activeIcon : inactiveIcon,
                    key: ValueKey<bool>(isActive), size: 32),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(label),
      ],
    );
  }
}

class _ServicesGrid extends StatelessWidget {
  const _ServicesGrid();
  @override
  Widget build(BuildContext context) {
    final services = [
      {
        'title': 'Hospitals',
        'icon': Icons.local_hospital_outlined,
        'page': const HospitalServicesPage()
      },
      {
        'title': 'Fire Dept',
        'icon': Icons.local_fire_department_outlined,
        'page': const FireServicesPage()
      },
      {
        'title': 'Police',
        'icon': Icons.local_police_outlined,
        'page': const PoliceServicesPage()
      },
      {
        'title': 'My Profile',
        'icon': Icons.person_outline,
        'page': const MedicalProfilePage()
      },
      {
        'title': 'First-Aid',
        'icon': Icons.medication_liquid_outlined,
        'page': const FirstAidPage()
      },
      {
        'title': 'Contacts',
        'icon': Icons.contact_emergency_outlined,
        'page': const ManageContactsPage()
      },
    ];

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: services.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final service = services[index];
        return _ServiceGridItem(
          title: service['title'] as String,
          icon: service['icon'] as IconData,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => service['page'] as Widget)),
        );
      },
    );
  }
}

class _ServiceGridItem extends StatelessWidget {
  const _ServiceGridItem(
      {required this.title, required this.icon, required this.onTap});
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Theme.of(context).primaryColor),
            const SizedBox(height: 12),
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class CountdownDialog extends StatefulWidget {
  final VoidCallback onCancel;
  const CountdownDialog({super.key, required this.onCancel});
  @override
  State<CountdownDialog> createState() => _CountdownDialogState();
}

class _CountdownDialogState extends State<CountdownDialog> {
  int _countdown = 3;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdown == 1) {
        timer.cancel();
        Navigator.of(context).pop(true);
      } else {
        setState(() => _countdown--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text("SOS ACTIVATING"),
      content: Text("Sending alert in... $_countdown",
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center),
      actions: [
        TextButton(onPressed: widget.onCancel, child: const Text("CANCEL SOS")),
      ],
    );
  }
}
