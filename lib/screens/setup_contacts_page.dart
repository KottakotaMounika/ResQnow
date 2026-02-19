import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';
import 'manage_contacts_page.dart';

class SetupContactsPage extends StatelessWidget {
const SetupContactsPage({super.key});

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text("Add Emergency Contacts"),
automaticallyImplyLeading: false,
),
body: Column(
children: [
Padding(
padding: const EdgeInsets.all(16.0),
child: Text(
"Add at least one contact who will receive an SMS during an SOS. Use the switch to mark them as an 'Emergency Contact'.",
textAlign: TextAlign.center,
style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodySmall?.color),
),
),
const Expanded(
child: ContactsManagerBody(),
),
Padding(
padding: const EdgeInsets.all(16.0),
child: ElevatedButton(
onPressed: () async {
final prefs = await SharedPreferences.getInstance();
final userName = prefs.getString('userName') ?? "User";
if (context.mounted) {
Navigator.pushAndRemoveUntil(
context,
MaterialPageRoute(builder: (_) => HomePage(userName: userName)),
(route) => false,
);
}
},
style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
child: const Text("Finish Setup & Go to Home"),
),
)
],
),
);
}
}