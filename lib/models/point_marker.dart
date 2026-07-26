import '../models/punto_info.dart';

class PointMarker {
  int? id;

  String layerId;

  double lat;
  double lon;

  PuntoInfo info;

  PointMarker({
    this.id,
    required this.layerId,
    required this.lat,
    required this.lon,
    required this.info,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'layer_id': layerId,
      'lat': lat,
      'lon': lon,
      'nome': info.nome,
      'dimensione': info.dimensione,
      'accessibilita': info.accessibilita,
      'note': info.note,
    };
  }

  factory PointMarker.fromMap(Map<String, dynamic> map) {
    return PointMarker(
      id: map['id'],
      layerId: map['layer_id'],
      lat: map['lat'],
      lon: map['lon'],
      info: PuntoInfo(
        nome: map['nome'],
        dimensione: map['dimensione'],
        accessibilita: map['accessibilita'],
        note: map['note'],
      ),
    );
  }
}
