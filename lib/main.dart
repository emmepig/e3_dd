import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

// I TUOI FILE ESTERNI
import 'models/map_layer.dart';
import 'models/punto_info.dart';
import 'services/layer_loader.dart';
import 'widgets/punto_dialog.dart';
import 'widgets/layer_manager.dart';
import 'controllers/point_layer_controller.dart';
import 'services/auth_provider.dart';
import 'pages/settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authProvider = AuthProvider();
  await authProvider.initialize();

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider.value(value: authProvider)],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E3 trace',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
      ),
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
  final PointLayerController pointLayerController = PointLayerController();

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

    _loadPointData();
  }

  Future<void> _loadPointData() async {
    await pointLayerController.loadData();

    setState(() {});
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
        controller: pointLayerController,
        onSave: (newInfo) {
          setState(() {
            if (info == null) {
              // CREAZIONE
              pointLayerController.addPoint(point, newInfo);
            } else {
              // MODIFICA
              pointLayerController.updatePoint(point, newInfo);
            }
          });
        },
        // elimina punto
        onDelete: () async {
          final bool? conferma = await showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text("Conferma eliminazione"),
                content: const Text("Vuoi davvero eliminare questo punto?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Annulla"),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text("Elimina"),
                  ),
                ],
              );
            },
          );

          if (conferma == true) {
            setState(() {
              pointLayerController.deletePoint(point);
            });
          }
        },
      ),
    );
  }

  // ------------------------------------------------------------
  // MODIFICA PUNTO (CERCA IN TUTTI I LAYER)
  // ------------------------------------------------------------
  void _editMarker(LatLng point) {
    final pointData = pointLayerController.findPoint(point);

    if (pointData != null) {
      setState(() {
        pointLayerController.activeLayerId = pointData.layerId;
      });

      _openPuntoDialog(point, pointData.info);
    }
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final LatLng center = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(41.9028, 12.4964); // Roma

    return Scaffold(
      appBar: AppBar(
        title: const Text('E3 trace', style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
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

                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) {
                    return LayerManager(
                      controller: pointLayerController,
                      onChanged: () => setState(() {}),
                      showMessage: (String p1) {},
                    );
                  },
                );
              },
            ),

            const Divider(),

            // VOCE DINAMICA
            if (!auth.isLoggedIn)
              ListTile(
                leading: const Icon(Icons.login),
                title: const Text('Accedi'),
                onTap: () async {
                  Navigator.pop(context);
                  await auth.login();
                },
              )
            else
              ListTile(
                leading: auth.user?.photoUrl != null
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(auth.user!.photoUrl!),
                      )
                    : const CircleAvatar(child: Icon(Icons.person)),
                title: Text(auth.user!.name),
                subtitle: Text(auth.user!.email),
                onTap: () {
                  Navigator.pop(context);

                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                  );
                },
              ),
            if (auth.isLoggedIn)
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Esci'),
                onTap: () async {
                  await context.read<AuthProvider>().logout();

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
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
                  markers: pointLayerController.getVisibleMarkers(_editMarker),
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
}
