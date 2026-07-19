import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/map_layer.dart';

class LayerLoader {
  static Future<List<MapLayer>> loadLayers() async {
    final jsonString = await rootBundle.loadString('assets/map_layers.json');
    final List<dynamic> data = json.decode(jsonString);
    return data.map((e) => MapLayer.fromJson(e)).toList();
  }
}
