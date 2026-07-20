import 'package:flutter/material.dart';

class PointLayer {
  String id;
  String name;
  Color color;
  IconData icon;
  bool visible;

  PointLayer({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    this.visible = true,
  });
}
