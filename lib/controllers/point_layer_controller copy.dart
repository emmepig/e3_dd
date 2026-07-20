import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/point_layer.dart';
import '../models/punto_info.dart';
import '../services/point_layer_storage.dart';

class PointLayerController extends ChangeNotifier {
  List<PointLayer> layers = [];
  String activeLayerId = "default";

  Future<void> load() async {
    layers = await PointLayerStorage.load();

    if (layers.isEmpty) {
      layers = [PointLayer(id: "default", name: "Default")];
    }

    notifyListeners();
  }

  Future<void> save() async {
    await PointLayerStorage.save(layers);
  }

  PointLayer get activeLayer => layers.firstWhere((l) => l.id == activeLayerId);

  void addLayer(String name, Color color, IconData icon) {
    layers.add(
      PointLayer(
        id: name.toLowerCase().replaceAll(" ", "_"),
        name: name,
        color: color,
        icon: icon,
      ),
    );
    save();
    notifyListeners();
  }

  void removeLayer(String id) {
    // Se c'è solo un layer, non lo rimuovo
    if (layers.length <= 1) {
      return;
    }

    // Rimuovo il layer
    layers.removeWhere((l) => l.id == id);

    // Se il layer eliminato era quello attivo
    if (activeLayerId == id) {
      // Imposto il primo layer rimasto come attivo
      activeLayerId = layers.first.id;
    }
  }

  void setActiveLayer(String id) {
    activeLayerId = id;
    notifyListeners();
  }

  void toggleVisibility(String id, bool visible) {
    layers.firstWhere((l) => l.id == id).visible = visible;
    save();
    notifyListeners();
  }

  void addPoint(LatLng point, PuntoInfo info) {
    activeLayer.points.add(PointEntry(point: point, info: info));
    save();
    notifyListeners();
  }

  void updatePoint(LatLng point, PuntoInfo info) {
    final layer = activeLayer;
    final entry = layer.points.firstWhere((p) => p.point == point);
    entry.info = info;
    save();
    notifyListeners();
  }

  void movePoint(LatLng oldPoint, LatLng newPoint) {
    final layer = activeLayer;
    final entry = layer.points.firstWhere((p) => p.point == oldPoint);
    entry.point = newPoint;
    save();
    notifyListeners();
  }

  void deletePoint(LatLng point) {
    activeLayer.points.removeWhere((p) => p.point == point);
    save();
    notifyListeners();
  }
}
