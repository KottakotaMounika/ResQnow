import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

enum TrackingStatus { dispatched, approaching, arrived }

class LiveTrackingPage extends StatefulWidget {
final LatLng userLocation;
const LiveTrackingPage({super.key, required this.userLocation});

@override
State<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends State<LiveTrackingPage> {
late LatLng ambulanceLocation;
final MapController _mapController = MapController();
Timer? _timer;

TrackingStatus _status = TrackingStatus.dispatched;

@override
void initState() {
super.initState();
ambulanceLocation = LatLng(
widget.userLocation.latitude + (Random().nextDouble() * 0.05 - 0.025),
widget.userLocation.longitude + (Random().nextDouble() * 0.05 - 0.025),
);

_timer = Timer.periodic(const Duration(seconds: 2), (timer) {
if (!mounted) {
timer.cancel();
return;
}

final newLat = ambulanceLocation.latitude + (widget.userLocation.latitude - ambulanceLocation.latitude) * 0.1;
final newLon = ambulanceLocation.longitude + (widget.userLocation.longitude - ambulanceLocation.longitude) * 0.1;

setState(() {
ambulanceLocation = LatLng(newLat, newLon);
_mapController.move(ambulanceLocation, _mapController.camera.zoom);

final distance = const Distance().as(LengthUnit.Meter, ambulanceLocation, widget.userLocation);
if (distance < 50) {
timer.cancel();
_status = TrackingStatus.arrived;
_showArrivalDialog();
} else if (distance < 1000) {
_status = TrackingStatus.approaching;
} else {
_status = TrackingStatus.dispatched;
}
});
});
}

@override
void dispose() {
_timer?.cancel();
super.dispose();
}

void _showArrivalDialog() {
if(!mounted) return;
showDialog(
context: context,
builder: (_) => AlertDialog(
title: const Text("Ambulance Arrived"),
content: const Text("The emergency responders have arrived at your location."),
actions: [
TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("OK")),
],
),
);
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(title: const Text("Live Responder Tracking")),
body: Stack(
children: [
FlutterMap(
mapController: _mapController,
options: MapOptions(
initialCenter: widget.userLocation,
initialZoom: 15,
),
children: [
TileLayer(
urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
),
PolylineLayer(
polylines: [
Polyline(
points: [ambulanceLocation, widget.userLocation],
strokeWidth: 4.0,
color: Colors.blue.withOpacity(0.8),
),
],
),
MarkerLayer(
markers: [
Marker(
point: widget.userLocation,
width: 80, height: 80,
child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 40),
),
Marker(
point: ambulanceLocation,
width: 80, height: 80,
child: const Icon(Icons.emergency_outlined, color: Colors.red, size: 40),
)
],
),
],
),
Positioned(
bottom: 0,
left: 0,
right: 0,
child: Card(
margin: const EdgeInsets.all(16),
elevation: 5,
child: Padding(
padding: const EdgeInsets.all(16.0),
child: Column(
children: [
Text("Ambulance Status", style: Theme.of(context).textTheme.titleLarge),
const SizedBox(height: 16),
_buildStatusTimeline(),
const Divider(height: 24),
Row(
mainAxisAlignment: MainAxisAlignment.spaceAround,
children: [
_buildInfoChip("Vehicle", "AP-09-1234"),
_buildInfoChip("Driver", "Ravi Kumar"),
],
),
],
),
),
),
),
],
),
);
}

Widget _buildStatusTimeline() {
return Column(
children: [
_buildStatusStep("SOS Sent", "Alerting emergency services", true),
_buildStatusStep("Responder Dispatched", "Ambulance is on the way", _status.index >= 0),
_buildStatusStep("Approaching", "The ambulance is nearby", _status.index >= 1),
_buildStatusStep("Arrived", "Help is at your location", _status.index >= 2, isLast: true),
],
);
}

Widget _buildStatusStep(String title, String subtitle, bool isActive, {bool isLast = false}) {
return Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Column(
children: [
Icon(
isActive ? Icons.check_circle : Icons.radio_button_unchecked,
color: isActive ? Colors.green : Colors.grey,
),
if (!isLast)
Container(
height: 20,
width: 2,
color: isActive ? Colors.green : Colors.grey,
),
],
),
const SizedBox(width: 16),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isActive ? null : Colors.grey)),
Text(subtitle, style: TextStyle(color: isActive ? null : Colors.grey)),
],
),
),
],
);
}

Widget _buildInfoChip(String label, String value) {
return Column(
children: [
Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
const SizedBox(height: 4),
Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
],
);
}
}