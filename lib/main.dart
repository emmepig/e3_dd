import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E3 trace',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MappaPage(),
    );
  }
}

class MappaPage extends StatefulWidget {
  const MappaPage({super.key});

  @override
  State<MappaPage> createState() => _MappaPageState();
}

class _MappaPageState extends State<MappaPage> {
  final MapController _mapController = MapController();
  final List<Marker> _markers = [];

  Position? _currentPosition;
  StreamSubscription<Position>? _positionSubscription;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
    );

    setState(() {
      _currentPosition = position;
    });

    _centerOnPosition(position);

    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
          ),
        ).listen((position) {
          setState(() {
            _currentPosition = position;
          });
        });
  }

  void _centerOnUser() {
    if (_currentPosition == null) return;
    _centerOnPosition(_currentPosition!);
  }

  void _centerOnUserPoint() {
    _centerOnUser();
    _addCurrentPositionMarker();
  }

  void _centerOnPosition(Position position) {
    _mapController.move(LatLng(position.latitude, position.longitude), 18);
  }

  void _addCurrentPositionMarker() {
    if (_currentPosition == null) return;

    setState(() {
      _markers.add(
        Marker(
          point: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          width: 40,
          height: 40,
          child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final LatLng center = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(41.9028, 12.4964); // Roma

    return Scaffold(
      appBar: AppBar(
        title: const Text('E3 trace'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),

      drawer: Drawer(
        child: ListView(children: const [DrawerHeader(child: Text('Menu'))]),
      ),

      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(initialCenter: center, initialZoom: 16),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'it.emmepig.e3trace',
          ),

          if (_currentPosition != null)
            CircleLayer(
              circles: [
                CircleMarker(
                  point: center,
                  radius: _currentPosition!.accuracy,
                  useRadiusInMeter: true,
                  color: Colors.blue.withValues(alpha: 0.2),
                  borderColor: Colors.blue,
                  borderStrokeWidth: 1,
                ),
              ],
            ),

          if (_currentPosition != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: center,
                  width: 24,
                  height: 24,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),

      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "center",
            onPressed: _centerOnUser,
            child: const Icon(Icons.my_location),
          ),

          const SizedBox(height: 12),

          FloatingActionButton(
            heroTag: "add",
            onPressed: _centerOnUserPoint,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
