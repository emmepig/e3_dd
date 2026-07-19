class MapLayer {
  final String name;
  final String id;
  final String url;
  final List<String> subdomains;

  MapLayer({
    required this.name,
    required this.id,
    required this.url,
    required this.subdomains,
  });

  factory MapLayer.fromJson(Map<String, dynamic> json) {
    return MapLayer(
      name: json['name'],
      id: json['id'],
      url: json['url'],
      subdomains: List<String>.from(json['subdomains']),
    );
  }
}
