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
}
