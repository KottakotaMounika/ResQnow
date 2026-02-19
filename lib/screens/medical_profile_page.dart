import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MedicalProfilePage extends StatefulWidget {
const MedicalProfilePage({super.key});

@override
_MedicalProfilePageState createState() => _MedicalProfilePageState();
}

class _MedicalProfilePageState extends State<MedicalProfilePage> {
bool _isEditing = false;
bool _isLoading = true;
String? _reportFilePath;

final _formKey = GlobalKey<FormState>();
final _nameController = TextEditingController();
final _ageController = TextEditingController();
final _bloodGroupController = TextEditingController();
final _allergiesController = TextEditingController();
final _conditionsController = TextEditingController();
final _contactController = TextEditingController();

@override
void initState() {
super.initState();
_loadProfileData();
}

Future<void> _loadProfileData() async {
final prefs = await SharedPreferences.getInstance();
setState(() {
_nameController.text = prefs.getString('profile_name') ?? prefs.getString('userName') ?? '';
_ageController.text = prefs.getString('profile_age') ?? '';
_bloodGroupController.text = prefs.getString('profile_blood') ?? '';
_allergiesController.text = prefs.getString('profile_allergies') ?? 'None';
_conditionsController.text = prefs.getString('profile_conditions') ?? 'None';
_contactController.text = prefs.getString('profile_contact') ?? prefs.getString('userPhone') ?? '';
_reportFilePath = prefs.getString('profile_report_path');
_isLoading = false;
});
}

Future<void> _saveProfileData() async {
if (_formKey.currentState!.validate()) {
final prefs = await SharedPreferences.getInstance();
await prefs.setString('profile_name', _nameController.text);
await prefs.setString('profile_age', _ageController.text);
await prefs.setString('profile_blood', _bloodGroupController.text);
await prefs.setString('profile_allergies', _allergiesController.text);
await prefs.setString('profile_conditions', _conditionsController.text);
await prefs.setString('profile_contact', _contactController.text);
if (_reportFilePath != null) {
await prefs.setString('profile_report_path', _reportFilePath!);
} else {
await prefs.remove('profile_report_path');
}

setState(() => _isEditing = false);
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Profile Saved Successfully!'), backgroundColor: Colors.green),
);
}
}

Future<void> _pickFile() async {
FilePickerResult? result = await FilePicker.platform.pickFiles();
if (result != null && result.files.single.path != null) {
setState(() {
_reportFilePath = result.files.single.path!;
});
}
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text("Medical Profile"),
actions: [
IconButton(
icon: Icon(_isEditing ? Icons.save_outlined : Icons.edit_outlined),
onPressed: () {
if (_isEditing) {
_saveProfileData();
} else {
setState(() => _isEditing = true);
}
},
),
],
),
body: _isLoading
? const Center(child: CircularProgressIndicator())
: Form(
key: _formKey,
child: ListView(
padding: const EdgeInsets.all(16.0),
children: [
_buildInfoField("Full Name", _nameController),
_buildInfoField("Age", _ageController, keyboardType: TextInputType.number),
_buildInfoField("Blood Group", _bloodGroupController),
_buildInfoField("Allergies", _allergiesController),
_buildInfoField("Medical Conditions", _conditionsController),
_buildInfoField("Emergency Contact", _contactController, keyboardType: TextInputType.phone),
const SizedBox(height: 24),
_buildMedicalReportSection(),
],
),
),
);
}

Widget _buildInfoField(String label, TextEditingController controller, {TextInputType keyboardType = TextInputType.text}) {
return Padding(
padding: const EdgeInsets.symmetric(vertical: 8.0),
child: TextFormField(
controller: controller,
readOnly: !_isEditing,
keyboardType: keyboardType,
decoration: InputDecoration(
labelText: label,
labelStyle: const TextStyle(fontWeight: FontWeight.w600),
),
validator: (value) => value == null || value.isEmpty ? 'This field cannot be empty' : null,
),
);
}

Widget _buildMedicalReportSection() {
final bool isImage = _reportFilePath != null &&
(_reportFilePath!.toLowerCase().endsWith('.jpg') ||
_reportFilePath!.toLowerCase().endsWith('.png') ||
_reportFilePath!.toLowerCase().endsWith('.jpeg'));

return Card(
child: Padding(
padding: const EdgeInsets.all(16.0),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text("Medical Reports", style: Theme.of(context).textTheme.titleLarge),
const SizedBox(height: 16),
if (_reportFilePath != null)
ClipRRect(
borderRadius: BorderRadius.circular(12),
child: isImage
? Image.file(File(_reportFilePath!), height: 200, width: double.infinity, fit: BoxFit.cover)
: Container(
height: 150,
decoration: BoxDecoration(
color: Theme.of(context).colorScheme.surfaceVariant,
borderRadius: BorderRadius.circular(12)),
child: Center(
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
const Icon(Icons.insert_drive_file_outlined, size: 50),
const SizedBox(height: 8),
Padding(
padding: const EdgeInsets.symmetric(horizontal: 8.0),
child: Text(
_reportFilePath!.split('/').last,
textAlign: TextAlign.center,
),
),
],
),
),
),
)
else
Container(
height: 150,
decoration: BoxDecoration(
color: Theme.of(context).colorScheme.surfaceVariant,
borderRadius: BorderRadius.circular(12)),
child: const Center(child: Text("No report uploaded.")),
),
const SizedBox(height: 16),
if(_isEditing)
SizedBox(
width: double.infinity,
child: ElevatedButton.icon(
onPressed: _pickFile,
icon: const Icon(Icons.upload_file_outlined),
label: Text(_reportFilePath != null ? "Change Report" : "Upload Report"),
style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.secondary),
),
),
],
),
),
);
}
}