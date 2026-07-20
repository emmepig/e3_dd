import 'package:flutter/material.dart';
import '../controllers/point_layer_controller.dart';

class LayerManager extends StatelessWidget {
  final PointLayerController controller;

  const LayerManager({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Column(
          children: [
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text("Aggiungi layer"),
              onTap: () {
                // Navigator.pop(context);
                _createLayerDialog(context);
              },
            ),
            const Divider(),
            Expanded(
              child: ListView(
                children: controller.layers.map((layer) {
                  final isActive = layer.id == controller.activeLayerId;

                  return ListTile(
                    title: Row(
                      children: [
                        Icon(layer.icon, color: layer.color),
                        const SizedBox(width: 8),
                        Text(layer.name),
                        if (isActive)
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            ),
                          ),
                      ],
                    ),
                    leading: isActive
                        ? const Icon(Icons.visibility, color: Colors.grey)
                        : Checkbox(
                            value: layer.visible,
                            onChanged: (v) {
                              controller.toggleVisibility(layer.id, v!);
                              setModalState(() {});
                            },
                          ),
                    trailing: isActive
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              controller.setActiveLayer(layer.id);
                              // Navigator.pop(context);
                            },
                          ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  void _createLayerDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    Color selectedColor = Colors.red;
    IconData selectedIcon = Icons.location_pin;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Nuovo layer"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Nome layer"),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text("Colore: "),
                  IconButton(
                    icon: Icon(Icons.circle, color: selectedColor),
                    onPressed: () {
                      selectedColor = Colors.blue;
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  const Text("Icona: "),
                  IconButton(
                    icon: Icon(selectedIcon),
                    onPressed: () {
                      selectedIcon = Icons.star;
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annulla"),
            ),
            ElevatedButton(
              onPressed: () {
                controller.addLayer(nameCtrl.text, selectedColor, selectedIcon);
                Navigator.pop(context);
              },
              child: const Text("Crea"),
            ),
          ],
        );
      },
    );
  }
}
