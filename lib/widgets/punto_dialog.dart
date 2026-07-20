import 'package:flutter/material.dart';
import '../models/punto_info.dart';

class PuntoDialog extends StatefulWidget {
  final PuntoInfo? info;
  final Function(PuntoInfo) onSave;
  final VoidCallback? onDelete;

  const PuntoDialog({
    super.key,
    required this.info,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<PuntoDialog> createState() => _PuntoDialogState();
}

class _PuntoDialogState extends State<PuntoDialog> {
  late TextEditingController nomeController;
  late TextEditingController noteController;
  int dimensione = 1;
  int accessibilita = 1;

  @override
  void initState() {
    super.initState();
    nomeController = TextEditingController(text: widget.info?.nome ?? "");
    noteController = TextEditingController(text: widget.info?.note ?? "");

    dimensione = widget.info?.dimensione ?? 1;
    accessibilita = widget.info?.accessibilita ?? 1;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.info == null ? "Nuovo punto" : "Modifica punto"),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: nomeController,
              decoration: const InputDecoration(labelText: "Denominazione"),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Dimensione"),
                Slider(
                  value: dimensione.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: dimensione.toString(),
                  onChanged: (v) => setState(() => dimensione = v.toInt()),
                ),
              ],
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Accessibilità"),
                Slider(
                  value: accessibilita.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: accessibilita.toString(),
                  onChanged: (v) => setState(() => accessibilita = v.toInt()),
                ),
              ],
            ),

            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: "Note (facoltative)",
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            widget.onSave(
              PuntoInfo(
                nome: nomeController.text,
                dimensione: dimensione,
                accessibilita: accessibilita,
                note: noteController.text.isEmpty ? null : noteController.text,
              ),
            );
            Navigator.pop(context);
          },
          child: const Text("Salva"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Annulla"),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            if (widget.onDelete != null) widget.onDelete!();
          },
          child: const Text("Elimina", style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}
