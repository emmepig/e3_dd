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

  factory PuntoInfo.fromMap(Map<String, dynamic> map) {
    return PuntoInfo(
      nome: map['nome'],
      dimensione: map['dimensione'],
      accessibilita: map['accessibilita'],
      note: map['note'],
    );
  }
}
