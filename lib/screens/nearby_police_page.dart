import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class NearbyPolicePage extends StatefulWidget {
final Color red;
const NearbyPolicePage({super.key, required this.red});

@override
State<NearbyPolicePage> createState() => _NearbyPolicePageState();
}

class _NearbyPolicePageState extends State<NearbyPolicePage> {
LatLng _currentPosition = LatLng(0, 0);
final MapController _mapController = MapController();
final List<Marker> _markers = [];
final List<Map<String, dynamic>> _policeStations = [];
bool _loading = true;

@override
void initState() {
super.initState();
_getCurrentLocation();
}

Future<void> _getCurrentLocation() async {
bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
if (!serviceEnabled) {
setState(() => _loading = false);
return;
}

LocationPermission permission = await Geolocator.requestPermission();
if (permission == LocationPermission.denied ||
permission == LocationPermission.deniedForever) {
setState(() => _loading = false);
return;
}

Position position = await Geolocator.getCurrentPosition();
_currentPosition = LatLng(position.latitude, position.longitude);

await _fetchNearbyPoliceStations();

setState(() => _loading = false);

_mapController.move(_currentPosition, 15.0);
}

Future<void> _fetchNearbyPoliceStations() async {
try {
final overpassQuery =
'''
[out:json];
node["amenity"="police"](around:5000,${_currentPosition.latitude},${_currentPosition.longitude});
out;
''';

final response = await http.post(
Uri.parse('https://overpass-api.de/api/interpreter'),
body: {'data': overpassQuery},
);

final data = jsonDecode(response.body)['elements'] as List<dynamic>;

_markers.clear();
_policeStations.clear();

// User location marker
_markers.add(
Marker(
point: _currentPosition,
width: 50,
height: 50,
child: Column(
children: const [
Icon(Icons.person_pin_circle, color: Colors.blue, size: 40),
Text("You", style: TextStyle(color: Colors.blue, fontSize: 12)),
],
),
),
);

// Police station markers
for (var item in data) {
double lat = item['lat'];
double lon = item['lon'];
String name = item['tags']?['name'] ?? 'Police Station';
double distance = Distance().as(
LengthUnit.Meter,
_currentPosition,
LatLng(lat, lon),
);

_policeStations.add({
'name': name,
'lat': lat,
'lon': lon,
'distance': distance,
});

_markers.add(
Marker(
point: LatLng(lat, lon),
width: 50,
height: 50,
child: GestureDetector(
onTap: () => _showPoliceInfo(name, distance),
child: const Icon(
Icons.local_police,
color: Colors.red,
size: 36,
),
),
),
);
}
} catch (e) {
print("Error fetching police stations: $e");
}
}

void _showPoliceInfo(String name, double distance) {
showModalBottomSheet(
context: context,
builder: (context) => Container(
padding: const EdgeInsets.all(16),
child: Column(
mainAxisSize: MainAxisSize.min,
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
name,
style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
),
const SizedBox(height: 8),
Text("Distance: ${distance.toStringAsFixed(0)} meters"),
const SizedBox(height: 8),
ElevatedButton.icon(
onPressed: () => Navigator.pop(context),
icon: const Icon(Icons.close),
label: const Text("Close"),
),
],
),
),
);
}

void _showAllStations() {
showModalBottomSheet(
context: context,
isScrollControlled: true,
builder: (context) => DraggableScrollableSheet(
expand: false,
minChildSize: 0.2,
maxChildSize: 0.6,
builder: (context, scrollController) => Container(
padding: const EdgeInsets.all(16),
child: ListView.builder(
controller: scrollController,
itemCount: _policeStations.length,
itemBuilder: (context, index) {
final station = _policeStations[index];
return Card(
child: ListTile(
leading: const Icon(Icons.local_police, color: Colors.red),
title: Text(station['name']),
subtitle: Text(
"Distance: ${station['distance'].toStringAsFixed(0)} meters",
),
onTap: () {
Navigator.pop(context);
_mapController.move(
LatLng(station['lat'], station['lon']),
17.0,
);
},
),
);
},
),
),
),
);
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text("Nearby Police Stations"),
backgroundColor: widget.red,
actions: [
IconButton(
icon: const Icon(Icons.list),
onPressed: _showAllStations,
tooltip: "Show all nearby stations",
),
],
),
body: _loading
? const Center(child: CircularProgressIndicator())
: FlutterMap(
mapController: _mapController,
options: MapOptions(
initialCenter: _currentPosition,
initialZoom: 15.0,
),
children: [
TileLayer(
urlTemplate:
"https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
subdomains: const ['a', 'b', 'c'],
),
MarkerLayer(markers: _markers),
],
),
);
}
}