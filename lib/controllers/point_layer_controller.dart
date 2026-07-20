import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/punto_info.dart';
import '../models/point_layer.dart';

class PointLayerController {
  // LAYER LIST
  final List<PointLayer> layers = [
    PointLayer(
      id: "default",
      name: "Default",
      color: Colors.red,
      icon: Icons.location_pin,
      visible: true,
    ),
  ];

  // ACTIVE LAYER
  String activeLayerId = "default";

  // MARKERS PER LAYER
  final Map<String, List<Map<String, dynamic>>> markers = {"default": []};

  // VISIBILITY PER LAYER
  final Map<String, bool> visibility = {"default": true};

  // AGGIUNTA LAYER
  void addLayer(String name, Color color, IconData icon) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    layers.add(
      PointLayer(id: id, name: name, color: color, icon: icon, visible: true),
    );

    markers[id] = [];
    visibility[id] = true;

    activeLayerId = id;
  }

  // ELIMINAZIONE LAYER
  void removeLayer(String id) {
    if (layers.length <= 1) return;

    layers.removeWhere((l) => l.id == id);
    markers.remove(id);
    visibility.remove(id);

    if (activeLayerId == id) {
      activeLayerId = layers.first.id;
    }
  }

  // CAMBIO LAYER ATTIVO
  void setActiveLayer(String id) {
    activeLayerId = id;
  }

  // VISIBILITÀ
  void toggleVisibility(String id, bool v) {
    visibility[id] = v;
    final layer = layers.firstWhere((l) => l.id == id);
    layer.visible = v;
  }

  // AGGIUNTA PUNTO
  void addPoint(LatLng point, PuntoInfo info, void Function(LatLng) onTapEdit) {
    final layer = layers.firstWhere((l) => l.id == activeLayerId);

    markers[activeLayerId]!.add({
      "marker": Marker(
        point: point,
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => onTapEdit(point),
          child: Icon(layer.icon, color: layer.color, size: 40),
        ),
      ),
      "info": info,
    });
  }

  // MODIFICA PUNTO
  void updatePoint(LatLng point, PuntoInfo info) {
    final result = findPoint(point);
    if (result == null) return;

    final item = result["item"];
    item["info"] = info;
  }

  // ELIMINA PUNTO
  void deletePoint(LatLng point) {
    final result = findPoint(point);
    if (result == null) return;

    final layerId = result["layerId"];
    markers[layerId]!.removeWhere((m) => m["marker"].point == point);
  }

  // CERCA PUNTO IN TUTTI I LAYER
  Map<String, dynamic>? findPoint(LatLng point) {
    for (final entry in markers.entries) {
      final match = entry.value.where((m) => m["marker"].point == point);
      if (match.isNotEmpty) {
        return {"layerId": entry.key, "item": match.first};
      }
    }
    return null;
  }
}
