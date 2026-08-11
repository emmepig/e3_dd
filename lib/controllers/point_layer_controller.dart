import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/punto_info.dart';
import '../models/point_layer.dart';
import '../models/point_marker.dart';
import '../database/db_helper.dart';

class PointLayerController {
  final DBHelper db = DBHelper.instance;

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

  // POINTS
  final List<PointMarker> points = [];

  // VISIBILITY PER LAYER
  final Map<String, bool> visibility = {"default": true};

  Future<void> loadData() async {
    layers.clear();
    points.clear();

    final dbLayers = await db.getLayers();
    final dbPoints = await db.getPoints();

    if (dbLayers.isEmpty) {
      final defaultLayer = PointLayer(
        id: "default",
        name: "Default",
        color: Colors.red,
        icon: Icons.location_pin,
        visible: true,
      );

      layers.add(defaultLayer);

      await db.insertLayer(defaultLayer);
    } else {
      layers.addAll(dbLayers);
    }

    points.addAll(dbPoints);

    visibility.clear();

    for (final layer in layers) {
      visibility[layer.id] = layer.visible;
    }

    activeLayerId = layers.first.id;
  }

  // AGGIUNTA LAYER
  Future<void> addLayer(String name, Color color, IconData icon) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    final layer = PointLayer(
      id: id,
      name: name,
      color: color,
      icon: icon,
      visible: true,
    );

    layers.add(layer);

    await db.insertLayer(layer);

    activeLayerId = id;
  }

  // ELIMINAZIONE LAYER
  Future<void> removeLayer(String id) async {
    if (layers.length <= 1) return;

    layers.removeWhere((l) => l.id == id);

    points.removeWhere((p) => p.layerId == id);

    visibility.remove(id);

    if (activeLayerId == id) {
      activeLayerId = layers.first.id;
    }

    await db.deleteLayer(id);

    for (final p in points.where((e) => e.layerId == id).toList()) {
      if (p.id != null) {
        await db.deletePoint(p.id!);
      }
    }
  }

  // CAMBIO LAYER ATTIVO
  void setActiveLayer(String id) {
    activeLayerId = id;
  }

  // VISIBILITÀ
  Future<void> toggleVisibility(String id, bool v) async {
    visibility[id] = v;

    final layer = layers.firstWhere((l) => l.id == id);
    layer.visible = v;

    await db.updateLayer(layer);
  }

  // AGGIUNTA PUNTO
  Future<void> addPoint(LatLng point, PuntoInfo info) async {
    final marker = PointMarker(
      layerId: activeLayerId,
      lat: point.latitude,
      lon: point.longitude,
      info: info,
    );

    points.add(marker);

    final id = await db.insertPoint(marker);

    marker.id = id;
  }

  // MODIFICA PUNTO
  Future<void> updatePoint(LatLng point, PuntoInfo info) async {
    final p = findPoint(point);

    if (p == null) return;

    p.info = info;

    if (p.id != null) {
      await db.updatePoint(p);
    }
  }

  // ELIMINA PUNTO
  Future<void> deletePoint(LatLng point) async {
    final p = findPoint(point);

    if (p == null) return;

    if (p.id != null) {
      await db.deletePoint(p.id!);
    }

    points.remove(p);
  }

  // CERCA PUNTO
  PointMarker? findPoint(LatLng point) {
    try {
      return points.firstWhere(
        (p) => p.lat == point.latitude && p.lon == point.longitude,
      );
    } catch (_) {
      return null;
    }
  }

  // MARKER VISIBILI PER FLUTTER_MAP
  List<Marker> getVisibleMarkers(void Function(LatLng) onTapEdit) {
    final result = <Marker>[];

    for (final p in points) {
      final layer = layers.firstWhere((l) => l.id == p.layerId);

      if (!layer.visible) continue;

      result.add(
        Marker(
          point: LatLng(p.lat, p.lon),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => onTapEdit(LatLng(p.lat, p.lon)),
            child: Icon(layer.icon, color: layer.color, size: 40),
          ),
        ),
      );
    }

    return result;
  }

  String getNextPointName() {
    int n = 1;
    int nMax = 1;

    final layerPoints = points.where((p) => p.layerId == activeLayerId);

    for (final point in layerPoints) {
      n++;

      final nome = point.info.nome;

      if (nome.isEmpty) continue;

      final nQui = int.tryParse(nome);

      if (nQui != null && nQui >= nMax) {
        nMax = nQui + 1;
      }
    }

    return n > nMax ? n.toString() : nMax.toString();
  }

  // EXPORT XML SINGOLO LAYER
  String exportLayerToXML([String? layerId]) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<layers>');

    Iterable<PointLayer> elenco = layers;
    if (layerId != null) elenco = layers.where((l) => l.id == layerId);

    for (final layer in elenco) {
      buffer.writeln(
        '<layer id="${layer.id}" name="${_escapeXml(layer.name)}">',
      );
      final layerPoints = points.where((p) => p.layerId == layer.id);

      for (final p in layerPoints) {
        final info = p.info;

        buffer.writeln('  <point id="${p.id}">');
        buffer.writeln('    <lat>${p.lat}</lat>');
        buffer.writeln('    <lon>${p.lon}</lon>');
        buffer.writeln('    <name>${_escapeXml(info.nome)}</name>');
        buffer.writeln('    <note>${_escapeXml(info.note)}</note>');
        buffer.writeln('    <dimensione>${info.dimensione}</dimensione>');
        buffer.writeln(
          '    <accessibilita>${info.accessibilita}</accessibilita>',
        );
        buffer.writeln('  </point>');
      }

      buffer.writeln('</layer>');
    }
    buffer.writeln('</layers>');

    return buffer.toString();
  }

  // EXPORT XML COMPLETO

  String _escapeXml(String? value) {
    if (value == null) return '';

    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}
