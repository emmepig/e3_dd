import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

// I TUOI FILE ESTERNI
import 'models/map_layer.dart';
import 'models/punto_info.dart';
import 'services/layer_loader.dart';
import 'widgets/punto_dialog.dart';

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

class MappaPage extends StatefulWidget {
  const MappaPage({super.key});

  @override
  State<MappaPage> createState() => _MappaPageState();
}

class _MappaPageState extends State<MappaPage> {
  final MapController _mapController = MapController();

  // MARKER + INFO
  final List<Map<String, dynamic>> _markers = [];

  // LAYER
  List<MapLayer> _layers = [];
  String _mapStyle = "standard";

  // POSIZIONE
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
    final layers = await LayerLoader.loadLayers();
    setState(() => _layers = layers);
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

    setState(() => _currentPosition = position);

    _centerOnPosition(position);

    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
          ),
        ).listen((position) {
          setState(() => _currentPosition = position);
        });
  }

  void _centerOnPosition(Position position) {
    _mapController.move(LatLng(position.latitude, position.longitude), 20);
  }

  void _centerOnUser() {
    if (_currentPosition != null) {
      _centerOnPosition(_currentPosition!);
    }
  }

  void _centerOnUserPoint() {
    _centerOnUser();
    _addCurrentPositionMarker();
  }

  void _addCurrentPositionMarker() {
    if (_currentPosition == null) return;

    final point = LatLng(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );

    _openPuntoDialog(point, null);
  }

  // ------------------------------------------------------------
  // POPUP CREAZIONE / MODIFICA
  // ------------------------------------------------------------
  void _openPuntoDialog(LatLng point, PuntoInfo? info) {
    showDialog(
      context: context,
      builder: (context) => PuntoDialog(
        info: info,
        onSave: (newInfo) {
          setState(() {
            if (info == null) {
              // CREAZIONE
              _markers.add({
                "marker": Marker(
                  point: point,
                  width: 40,
                  height: 40,
                  child: GestureDetector(
                    onTap: () => _editMarker(point),
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ),
                "info": newInfo,
              });
            } else {
              // MODIFICA
              final item = _markers.firstWhere(
                (m) => m["marker"].point == point,
              );
              item["info"] = newInfo;
            }
          });
        },
      ),
    );
  }

  void _editMarker(LatLng point) {
    final item = _markers.firstWhere((m) => m["marker"].point == point);
    final info = item["info"] as PuntoInfo;

    _openPuntoDialog(point, info);
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
                  _openPuntoDialog(point, null);
                },
              ),
              children: [
                // LAYER DINAMICO
                TileLayer(
                  urlTemplate: _currentLayer.url,
                  subdomains: _currentLayer.subdomains,
                  userAgentPackageName: 'it.emmepig.e3trace',
                ),

                // CERCHIO POSIZIONE
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

                // MARKER POSIZIONE
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

                // MARKER UTENTE
                MarkerLayer(
                  markers: _markers.map((m) => m["marker"] as Marker).toList(),
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
