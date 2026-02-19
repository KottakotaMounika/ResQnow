// lib/screens/create_profile_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'setup_contacts_page.dart';

class CreateProfilePage extends StatefulWidget {
  const CreateProfilePage({super.key});

  @override
  State<CreateProfilePage> createState() => _CreateProfilePageState();
}

class _CreateProfilePageState extends State<CreateProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _ageController = TextEditingController();
  final _bloodGroupController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _conditionsController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _ageController.dispose();
    _bloodGroupController.dispose();
    _allergiesController.dispose();
    _conditionsController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        // Load from consistent storage keys
        _nameController.text = prefs.getString('userName') ?? 
                               prefs.getString('profile_name') ?? '';
        _contactController.text = prefs.getString('userPhone') ?? 
                                  prefs.getString('profile_contact') ?? '';
        
        // Load existing profile data if available
        _ageController.text = prefs.getString('profile_age') ?? '';
        _bloodGroupController.text = prefs.getString('profile_blood') ?? '';
        _allergiesController.text = prefs.getString('profile_allergies') ?? '';
        _conditionsController.text = prefs.getString('profile_conditions') ?? '';
        
        _isLoading = false;
      });
      
      print('✅ Profile data loaded');
    } catch (e) {
      print('❌ Error loading profile data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfileAndNavigate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save all profile data with consistent keys
      await prefs.setString('profile_name', _nameController.text.trim());
      await prefs.setString('profile_contact', _contactController.text.trim());
      await prefs.setString('profile_age', _ageController.text.trim());
      await prefs.setString('profile_blood', _bloodGroupController.text.trim());
      await prefs.setString('profile_allergies', _allergiesController.text.trim().isEmpty 
          ? 'None' : _allergiesController.text.trim());
      await prefs.setString('profile_conditions', _conditionsController.text.trim().isEmpty 
          ? 'None' : _conditionsController.text.trim());
      
      // Also update main user data if they match
      await prefs.setString('userName', _nameController.text.trim());
      await prefs.setString('userPhone', _contactController.text.trim());
      
      // Mark profile as complete
      await prefs.setBool('profile_complete', true);
      
      print('✅ Profile saved successfully');

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate to contacts setup
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const SetupContactsPage()),
          (route) => false,
        );
      }
    } catch (e) {
      print('❌ Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save profile. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Medical Profile"),
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    
                    // Header
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.person_add_alt_1_outlined, 
                            size: 60,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Create Your Medical Profile",
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "This information is vital for responders in an emergency.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Basic Information
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Basic Information",
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                labelText: "Full Name",
                                prefixIcon: Icon(Icons.person_outline),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) => value?.trim().isEmpty ?? true 
                                  ? 'Please enter your full name' : null,
                            ),
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              controller: _contactController,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              decoration: const InputDecoration(
                                labelText: "Emergency Contact Number",
                                prefixIcon: Icon(Icons.phone_outlined),
                                border: OutlineInputBorder(),
                                helperText: "10-digit phone number",
                              ),
                              validator: (value) {
                                if (value?.trim().isEmpty ?? true) {
                                  return 'Please enter your emergency contact';
                                }
                                if (value!.trim().length != 10) {
                                  return 'Please enter a valid 10-digit phone number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: _ageController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(3),
                                    ],
                                    decoration: const InputDecoration(
                                      labelText: "Age",
                                      prefixIcon: Icon(Icons.cake_outlined),
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (value) {
                                      if (value?.trim().isEmpty ?? true) {
                                        return 'Required';
                                      }
                                      final age = int.tryParse(value!);
                                      if (age == null || age < 1 || age > 120) {
                                        return 'Invalid age';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 3,
                                  child: DropdownButtonFormField<String>(
                                    value: _bloodGroupController.text.isEmpty 
                                        ? null : _bloodGroupController.text,
                                    decoration: const InputDecoration(
                                      labelText: "Blood Group",
                                      prefixIcon: Icon(Icons.bloodtype_outlined),
                                      border: OutlineInputBorder(),
                                    ),
                                    items: _bloodGroups.map((group) => 
                                      DropdownMenuItem(
                                        value: group,
                                        child: Text(group)
                                      )
                                    ).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _bloodGroupController.text = value ?? '';
                                      });
                                    },
                                    validator: (value) => value?.isEmpty ?? true 
                                        ? 'Please select blood group' : null,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Medical Information
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Medical Information",
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Leave blank if none apply",
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              controller: _allergiesController,
                              maxLines: 3,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: const InputDecoration(
                                labelText: "Allergies",
                                prefixIcon: Icon(Icons.warning_amber_outlined),
                                border: OutlineInputBorder(),
                                hintText: "e.g., Penicillin, Peanuts, Shellfish",
                                alignLabelWithHint: true,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              controller: _conditionsController,
                              maxLines: 3,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: const InputDecoration(
                                labelText: "Medical Conditions",
                                prefixIcon: Icon(Icons.medical_information_outlined),
                                border: OutlineInputBorder(),
                                hintText: "e.g., Diabetes, Hypertension, Asthma",
                                alignLabelWithHint: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfileAndNavigate,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2)
                              )
                            : const Text(
                                "Save Profile & Continue",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }
}