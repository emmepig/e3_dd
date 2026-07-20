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

  // ============================================================
  // LAYER DEI PUNTI
  // ============================================================
  String _activePointLayer = "default";

  Map<String, bool> _layerVisibility = {"default": true};

  Map<String, List<Map<String, dynamic>>> _layerMarkers = {"default": []};

  // ============================================================
  // LAYER MAPPA (OSM, satellite, ecc.)
  // ============================================================
  List<MapLayer> _layers = [];
  String _mapStyle = "standard";

  // ============================================================
  // POSIZIONE UTENTE
  // ============================================================
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
  // CARICAMENTO LAYER MAPPA DA JSON
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
    _mapController.move(LatLng(position.latitude, position.longitude), 18);
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
  // POPUP CREAZIONE / MODIFICA PUNTO
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
              _layerMarkers[_activePointLayer]!.add({
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
              final layer = _layerMarkers[_activePointLayer]!;
              final item = layer.firstWhere((m) => m["marker"].point == point);
              item["info"] = newInfo;
            }
          });
        },
      ),
    );
  }

  // ------------------------------------------------------------
  // MODIFICA PUNTO (CERCA IN TUTTI I LAYER)
  // ------------------------------------------------------------
  void _editMarker(LatLng point) {
    for (final entry in _layerMarkers.entries) {
      final layerId = entry.key;
      final markers = entry.value;

      final match = markers.where((m) => m["marker"].point == point);

      if (match.isNotEmpty) {
        final item = match.first;
        final info = item["info"] as PuntoInfo;

        setState(() => _activePointLayer = layerId);

        _openPuntoDialog(point, info);
        return;
      }
    }
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

            ListTile(
              leading: const Icon(Icons.layers),
              title: const Text('Gestione layer punti'),
              onTap: () {
                Navigator.pop(context);
                _openLayerManager();
              },
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
                // LAYER MAPPA DINAMICO
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

                // MARKER UTENTE PER LAYER
                MarkerLayer(
                  markers: _layerMarkers.entries
                      .where((entry) => _layerVisibility[entry.key] == true)
                      .expand(
                        (entry) =>
                            entry.value.map((m) => m["marker"] as Marker),
                      )
                      .toList(),
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
  // MENU LAYER MAPPA (OSM, satellite, ecc.)
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

  // ------------------------------------------------------------
  // MENU LAYER PUNTI
  // ------------------------------------------------------------
  void _openLayerManager() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text("Aggiungi layer"),
                  onTap: () {
                    Navigator.pop(context);
                    _createNewLayer();
                  },
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    children: _layerMarkers.keys.map((layerId) {
                      final bool isActive = layerId == _activePointLayer;

                      return ListTile(
                        title: Row(
                          children: [
                            Text(layerId),
                            const SizedBox(width: 8),
                            if (isActive)
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                          ],
                        ),

                        // VISIBILITÀ
                        leading: isActive
                            ? const Icon(Icons.visibility, color: Colors.grey)
                            : Checkbox(
                                value: _layerVisibility[layerId],
                                onChanged: (v) {
                                  setState(
                                    () => _layerVisibility[layerId] = v!,
                                  );
                                  setModalState(() {});
                                },
                              ),

                        // EDIT SOLO PER LAYER NON ATTIVO
                        trailing: isActive
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  setState(() => _activePointLayer = layerId);
                                  Navigator.pop(context);
                                },
                              ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ------------------------------------------------------------
  // CREAZIONE NUOVO LAYER PUNTI
  // ------------------------------------------------------------
  void _createNewLayer() {
    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Nuovo layer punti"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: "Nome layer"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annulla"),
            ),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  setState(() {
                    _layerMarkers[name] = [];
                    _layerVisibility[name] = true;
                  });
                }
                Navigator.pop(context);
              },
              child: const Text("Crea"),
            ),
          ],
        );
      },
    );
  }
}
