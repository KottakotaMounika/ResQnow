import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AmbulanceServicesPage extends StatelessWidget {
const AmbulanceServicesPage({super.key});

final List<Map<String, String>> ambulanceContacts = const [
{"name": "National Emergency Number", "phone": "112"},
{"name": "Ambulance Helpline", "phone": "108"},
{"name": "Ravi Kumar (Local)", "phone": "+919876543210"},
{"name": "Suresh Reddy (Local)", "phone": "+919123456780"},
];

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text("Ambulance Services"),
),
body: ListView.builder(
padding: const EdgeInsets.all(8),
itemCount: ambulanceContacts.length,
itemBuilder: (context, index) {
final contact = ambulanceContacts[index];
return Card(
child: ListTile(
leading: CircleAvatar(
backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
child: Icon(Icons.phone_outlined, color: Theme.of(context).primaryColor),
),
title: Text(contact['name']!, style: const TextStyle(fontWeight: FontWeight.w600)),
subtitle: Text(contact['phone']!),
trailing: const Icon(Icons.arrow_forward_ios, size: 16),
onTap: () async {
final Uri callUri = Uri(scheme: 'tel', path: contact['phone']);
if (await canLaunchUrl(callUri)) {
await launchUrl(callUri);
}
},
),
);
},
),
);
}
}