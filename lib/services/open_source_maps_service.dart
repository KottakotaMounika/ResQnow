import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

// IMPORTANT: Replace with your actual OpenRouteService API Key
const String ORS_API_KEY = "YOUR_OPENROUTESERVICE_API_KEY";

class OpenSourceMapsService {
final String _baseUrl = "api.openrouteservice.org";

// Get route polylines for directions
Future<List<LatLng>> getRouteCoordinates(LatLng start, LatLng end) async {
final uri = Uri.https(_baseUrl, '/v2/directions/driving-car/geojson');
final response = await http.post(
uri,
headers: {
'Content-Type': 'application/json',
'Authorization': ORS_API_KEY,
},
body: json.encode({
"coordinates": [
[start.longitude, start.latitude],
[end.longitude, end.latitude]
]
}),
);

if (response.statusCode == 200) {
final data = json.decode(response.body);
final List<dynamic> coords =
data['features'][0]['geometry']['coordinates'];
return coords
.map((coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()))
.toList();
} else {
print('ORS Error: ${response.body}');
throw Exception('Failed to load route from OpenRouteService');
}
}

// Get nearby places (Points of Interest)
Future<List<dynamic>> getNearbyPlaces(
LatLng location, String category) async {
final uri = Uri.https(_baseUrl, '/pois');
final response = await http.post(
uri,
headers: {
'Content-Type': 'application/json',
'Authorization': ORS_API_KEY,
},
body: json.encode({
"request": "pois",
"geometry": {
"bbox": [
[
location.longitude - 0.05,
location.latitude - 0.05
], // Bounding box
[location.longitude + 0.05, location.latitude + 0.05]
],
"geojson": {
"type": "Point",
"coordinates": [location.longitude, location.latitude]
},
},
"filters": {
"category_group_ids": [category == 'hospital' ? 326 : 301], // 326 for healthcare, 301 for public services (police)
},
"limit": 20,
}),
);

if (response.statusCode == 200) {
final data = json.decode(response.body);
// We need to manually shape the data to be consistent for our app
return (data['features'] as List).map((place) {
return {
'name': place['properties']['osm_tags']?['name'] ?? 'Unnamed Place',
'geometry': {
'location': {
'lat': place['geometry']['coordinates'][1],
'lng': place['geometry']['coordinates'][0],
}
}
};
}).toList();
} else {
print('ORS POI Error: ${response.body}');
throw Exception('Failed to load nearby places from OpenRouteService');
}
}
}