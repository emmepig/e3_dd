import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'punto_info.dart';

class PointLayer {
  final String id;
  String name;
  bool visible;
  Color color;
  IconData icon;

  List<PointEntry> points;

  PointLayer({
    required this.id,
    required this.name,
    this.visible = true,
    this.color = Colors.red,
    this.icon = Icons.location_pin,
    List<PointEntry>? points,
  }) : points = points ?? [];

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "visible": visible,
    "color": color.toARGB32(),
    "icon": icon.codePoint,
    "points": points.map((p) => p.toJson()).toList(),
  };

  static PointLayer fromJson(Map<String, dynamic> json) {
    return PointLayer(
      id: json["id"],
      name: json["name"],
      visible: json["visible"],
      color: Color(json["color"]),
      icon: IconData(json["icon"], fontFamily: 'MaterialIcons'),
      points: (json["points"] as List)
          .map((p) => PointEntry.fromJson(p))
          .toList(),
    );
  }
}

class PointEntry {
  LatLng point;
  PuntoInfo info;

  PointEntry({required this.point, required this.info});

  Map<String, dynamic> toJson() => {
    "lat": point.latitude,
    "lng": point.longitude,
    "info": info.toJson(),
  };

  static PointEntry fromJson(Map<String, dynamic> json) {
    return PointEntry(
      point: LatLng(json["lat"], json["lng"]),
      info: PuntoInfo.fromJson(json["info"]),
    );
  }
}
