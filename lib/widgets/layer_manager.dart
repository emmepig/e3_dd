import 'package:flutter/material.dart';
import '../controllers/point_layer_controller.dart';

class LayerManager extends StatelessWidget {
  final PointLayerController controller;

  const LayerManager({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.add),
                    title: const Text("Aggiungi layer"),
                    onTap: () => _createLayerDialog(context, setModalState),
                  ),

                  const Divider(),

                  Expanded(
                    child: ListView(
                      controller: scrollController,
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

                          leading: Checkbox(
                            value: controller.visibility[layer.id],
                            onChanged: (v) {
                              controller.toggleVisibility(layer.id, v!);
                              setModalState(() {});
                            },
                          ),

                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  controller.setActiveLayer(layer.id);
                                  setModalState(() {});
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _confirmDeleteLayer(
                                  context,
                                  layer.id,
                                  setModalState,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _createLayerDialog(BuildContext context, Function setModalState) {
    final nameCtrl = TextEditingController();
    Color selectedColor = Colors.red;
    IconData selectedIcon = Icons.location_pin;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Nuovo layer"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Nome layer"),
              ),
              const SizedBox(height: 16),
              const Text("Colore"),
              Wrap(
                spacing: 8,
                children:
                    [
                      Colors.red,
                      Colors.blue,
                      Colors.green,
                      Colors.orange,
                      Colors.purple,
                      Colors.brown,
                    ].map((c) {
                      return GestureDetector(
                        onTap: () {
                          selectedColor = c;
                        },
                        child: CircleAvatar(backgroundColor: c),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 16),
              const Text("Icona"),
              Wrap(
                spacing: 8,
                children:
                    [
                      Icons.location_pin,
                      Icons.star,
                      Icons.flag,
                      Icons.place,
                      Icons.circle,
                      Icons.square,
                    ].map((i) {
                      return IconButton(
                        icon: Icon(i),
                        onPressed: () {
                          selectedIcon = i;
                        },
                      );
                    }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Annulla"),
            ),
            ElevatedButton(
              onPressed: () {
                controller.addLayer(nameCtrl.text, selectedColor, selectedIcon);
                setModalState(() {});
                Navigator.pop(dialogContext);
              },
              child: const Text("Crea"),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteLayer(
    BuildContext context,
    String layerId,
    Function setModalState,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Elimina layer"),
          content: const Text("Vuoi davvero eliminare questo layer?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Annulla"),
            ),
            ElevatedButton(
              onPressed: () {
                controller.removeLayer(layerId);
                setModalState(() {});
                Navigator.pop(dialogContext);
              },
              child: const Text("Elimina"),
            ),
          ],
        );
      },
    );
  }
}
