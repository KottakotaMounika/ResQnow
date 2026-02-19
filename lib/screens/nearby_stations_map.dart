// lib/screens/nearby_stations_map.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class NearbyStationsMap extends StatefulWidget {
  final LatLng userLocation;
  final String stationType; // e.g., 'police' or 'fire_station'
  final IconData stationIcon;
  final String title;

  const NearbyStationsMap({
    super.key,
    required this.userLocation,
    required this.stationType,
    required this.stationIcon,
    required this.title,
  });

  @override
  State<NearbyStationsMap> createState() => _NearbyStationsMapState();
}

class _NearbyStationsMapState extends State<NearbyStationsMap> {
  List<Marker> _markers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNearbyStations();
  }

  Future<void> _fetchNearbyStations() async {
    setState(() => _isLoading = true);
    final List<Marker> markers = [
      Marker(
        point: widget.userLocation,
        width: 80,
        height: 80,
        child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 40),
      ),
    ];

    try {
      String overpassQuery = '[out:json];node["amenity"="${widget.stationType}"](around:5000,${widget.userLocation.latitude},${widget.userLocation.longitude});out;';
      final response = await http.get(Uri.parse('https://overpass-api.de/api/interpreter?data=${Uri.encodeComponent(overpassQuery)}'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        for (var element in data['elements']) {
          final lat = element['lat'];
          final lon = element['lon'];
          markers.add(
            Marker(
              point: LatLng(lat, lon),
              width: 80,
              height: 80,
              child: Icon(widget.stationIcon, color: Theme.of(context).primaryColor, size: 35),
            ),
          );
        }
      }
    } catch (e) {
      print("Error fetching stations: $e");
    }

    if (mounted) {
      setState(() {
        _markers = markers;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              options: MapOptions(
                initialCenter: widget.userLocation,
                initialZoom: 14.0,
              ),
              children: [
                TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                MarkerLayer(markers: _markers),
              ],
            ),
    );
  }
}