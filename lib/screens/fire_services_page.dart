// lib/screens/fire_services_page.dart
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/location_service.dart';
import 'nearby_stations_map.dart';

class FireServicesPage extends StatelessWidget {
  const FireServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // The AppBar now uses the app's theme for its background and text colors.
        title: const Text("Fire Services"),
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      ),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          _buildServiceCard(
            context,
            icon: Icons.local_fire_department,
            title: "Call Fire Brigade (101)",
            subtitle: "Directly call the fire emergency helpline",
            onTap: () async {
              final Uri callUri = Uri(scheme: 'tel', path: '101');
              if (await canLaunchUrl(callUri)) {
                await launchUrl(callUri);
              }
            },
          ),
          _buildServiceCard(
            context,
            icon: Icons.map_outlined,
            title: "Nearby Fire Stations",
            subtitle: "Find fire stations on the map",
            onTap: () async {
              final locationResult = await LocationService.getCurrentLocation();
              locationResult.fold(
                (errorMessage) {
                  // Handle location error if needed
                },
                (position) {
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NearbyStationsMap(
                          userLocation: LatLng(position.latitude, position.longitude),
                          stationType: 'fire_station',
                          stationIcon: Icons.local_fire_department,
                          title: 'Nearby Fire Stations',
                        ),
                      ),
                    );
                  }
                },
              );
            },
          ),
          _buildServiceCard(
            context,
            icon: Icons.health_and_safety_outlined,
            title: "Fire Safety Tips",
            subtitle: "Learn essential prevention tips",
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Fire Safety Tip"),
                  content: const Text(
                      "In case of a fire, stay low to the ground to avoid smoke inhalation and find the nearest exit."),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("OK"))
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // This reusable widget now gets its colors from the app's theme.
  Widget _buildServiceCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(icon, color: Theme.of(context).primaryColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}