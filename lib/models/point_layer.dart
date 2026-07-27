import 'package:flutter/material.dart';

class PointLayer {
  String id;
  String name;
  Color color;
  IconData icon;
  bool visible;
  DateTime? createdAt;
  DateTime? updatedAt;

  PointLayer({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    this.visible = true,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color.toARGB32(),
      'icon': icon.codePoint,
      'visible': visible ? 1 : 0,
    };
  }

  factory PointLayer.fromMap(Map<String, dynamic> map) {
    return PointLayer(
      id: map['id'],
      name: map['name'],
      color: Color(map['color']),
      icon: IconData(map['icon'] as int, fontFamily: 'MaterialIcons'),
      visible: map['visible'] == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
    );
  }
}
