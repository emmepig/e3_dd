import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/point_layer.dart';

class PointLayerStorage {
  static Future<String> _filePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return "${dir.path}/point_layers.json";
  }

  static Future<void> save(List<PointLayer> layers) async {
    final file = File(await _filePath());
    //final jsonData = layers.map((l) => l.toJson()).toList();
    //await file.writeAsString(jsonEncode(jsonData));
  }

  static Future<List<PointLayer>> load() async {
    final file = File(await _filePath());
    if (!await file.exists()) return [];

    final content = await file.readAsString();
    final jsonData = jsonDecode(content);

    //return (jsonData as List).map((l) => PointLayer.fromJson(l)).toList();
  }
}
