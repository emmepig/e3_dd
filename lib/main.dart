import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E3 trace',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MappaPage(),
    );
  }
}

// ------------------------------------------------------------
// MODELLO DATI PER I LAYER
// ------------------------------------------------------------
class MapLayer {
  final String name;
  final String id;
  final String url;
  final List<String> subdomains;

  MapLayer({
    required this.name,
    required this.id,
    required this.url,
    required this.subdomains,
  });

  factory MapLayer.fromJson(Map<String, dynamic> json) {
    return MapLayer(
      name: json['name'],
      id: json['id'],
      url: json['url'],
      subdomains: List<String>.from(json['subdomains']),
    );
  }
}

// ------------------------------------------------------------
// PAGINA MAPPA
// ------------------------------------------------------------
class MappaPage extends StatefulWidget {
  const MappaPage({super.key});

  @override
  State<MappaPage> createState() => _MappaPageState();
}

class _MappaPageState extends State<MappaPage> {
  final MapController _mapController = MapController();
  final List<Marker> _markers = [];

  List<MapLayer> _layers = [];
  String _mapStyle = "standard";

  Position? _currentPosition;
  StreamSubscription<Position>? _positionSubscription;

  @override
  void initState() {
    super.initState();
    _loadLayers();
    _initLocation();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  // ------------------------------------------------------------
  // CARICAMENTO LAYER DA JSON
  // ------------------------------------------------------------
  Future<void> _loadLayers() async {
    final jsonString = await rootBundle.loadString('assets/map_layers.json');
    final List<dynamic> data = json.decode(jsonString);

    setState(() {
      _layers = data.map((e) => MapLayer.fromJson(e)).toList();
    });
  }

  MapLayer get _currentLayer =>
      _layers.firstWhere((layer) => layer.id == _mapStyle);

  // ------------------------------------------------------------
  // LOCALIZZAZIONE
  // ------------------------------------------------------------
  Future<void> _initLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

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

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------
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
        child: ListView(
          children: [
            const DrawerHeader(child: Text('Menu')),
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text('Cambia visualizzazione'),
              onTap: _showMapStyleDialog,
            ),
          ],
        ),
      ),

      body: _layers.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 16,
                onTap: (tapPosition, point) {
                  setState(() {
                    _markers.add(
                      Marker(
                        point: point,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    );
                  });
                },
              ),
              children: [
                // LAYER DINAMICO
                TileLayer(
                  urlTemplate: _currentLayer.url,
                  subdomains: _currentLayer.subdomains,
                  userAgentPackageName: 'it.emmepig.e3trace',
                ),

                if (_currentPosition != null)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: center,
                        radius: _currentPosition!.accuracy,
                        useRadiusInMeter: true,
                        color: Colors.blue.withOpacity(0.2),
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

                MarkerLayer(markers: _markers),
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

  // ------------------------------------------------------------
  // MENU LAYER DINAMICO
  // ------------------------------------------------------------
  void _showMapStyleDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Seleziona visualizzazione'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _layers.map((layer) {
              return RadioListTile(
                title: Text(layer.name),
                value: layer.id,
                groupValue: _mapStyle,
                onChanged: (value) {
                  setState(() => _mapStyle = value!);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
