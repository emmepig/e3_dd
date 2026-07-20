class PuntoInfo {
  String nome;
  int dimensione;
  int accessibilita;
  String? note; // FACOLTATIVO

  PuntoInfo({
    required this.nome,
    required this.dimensione,
    required this.accessibilita,
    this.note, // può essere null
  });

  Map<String, dynamic> toJson() => {
    "nome": nome,
    "dimensione": dimensione,
    "accessibilita": accessibilita,
    "note": note,
  };

  static PuntoInfo fromJson(Map<String, dynamic> json) {
    return PuntoInfo(
      nome: json["nome"],
      dimensione: json["dimensione"],
      accessibilita: json["accessibilita"],
      note: json["note"],
    );
  }
}
