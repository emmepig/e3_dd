import 'package:flutter/material.dart';
import '../controllers/point_layer_controller.dart';
import '../utils/xml_download.dart';

class LayerManager extends StatelessWidget {
  final PointLayerController controller;
  final VoidCallback onChanged;
  final void Function(String) showMessage;

  const LayerManager({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.showMessage,
  });

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
                              Expanded(
                                child: Text(
                                  layer.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                          leading: Checkbox(
                            value: controller.visibility[layer.id] ?? true,
                            onChanged: (v) {
                              // Se il layer è attivo → NON permettere di disattivarlo
                              if (layer.id == controller.activeLayerId &&
                                  v == false) {
                                showDialog(
                                  context: context,
                                  builder: (ctx) {
                                    return AlertDialog(
                                      title: const Text("Layer attivo"),
                                      content: const Text(
                                        "Il layer attivo non può essere nascosto.",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text("OK"),
                                        ),
                                      ],
                                    );
                                  },
                                );
                                return; // 🔥 blocca la deselezione
                              }

                              controller.toggleVisibility(layer.id, v!);
                              setModalState(() {});
                              onChanged(); // 🔥 aggiorna la mappa
                            },
                          ),

                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Seleziona layer attivo
                              IconButton(
                                icon: Icon(
                                  isActive
                                      ? Icons.check_circle
                                      : Icons.circle_outlined,
                                  color: isActive ? Colors.green : Colors.grey,
                                ),
                                onPressed: () {
                                  controller.setActiveLayer(layer.id);

                                  // Se non è visibile → rendilo visibile
                                  if (!(controller.visibility[layer.id] ??
                                      false)) {
                                    controller.toggleVisibility(layer.id, true);
                                  }

                                  setModalState(() {});
                                  onChanged();
                                },
                              ),
                              // Modifica layer
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _editLayerDialog(
                                  context,
                                  layer,
                                  setModalState,
                                ),
                              ),
                              // Export GPX/XML
                              IconButton(
                                icon: const Icon(Icons.download),
                                onPressed: () async {
                                  final xml = controller.exportLayerToXML(
                                    layer.id,
                                  );
                                  await downloadXML(xml, "${layer.name}.xml");

                                  showMessage(
                                    "GPX esportato per il layer '${layer.name}'.",
                                  );
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

  // ------------------------------------------------------------
  // CREAZIONE NUOVO LAYER
  // ------------------------------------------------------------
  void _createLayerDialog(BuildContext context, Function setModalState) {
    final nameCtrl = TextEditingController();
    Color selectedColor = Colors.red;
    IconData selectedIcon = Icons.location_pin;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Nuovo layer"),
          content: StatefulBuilder(
            builder: (context, setState) {
              return _layerEditor(
                nameCtrl,
                selectedColor,
                selectedIcon,
                (c) {
                  setState(() {
                    selectedColor = c;
                  });
                },
                (i) {
                  setState(() {
                    selectedIcon = i;
                  });
                },
              );
            },
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

  // ------------------------------------------------------------
  // MODIFICA LAYER
  // ------------------------------------------------------------
  void _editLayerDialog(BuildContext context, layer, Function setModalState) {
    final nameCtrl = TextEditingController(text: layer.name);
    Color selectedColor = layer.color;
    IconData selectedIcon = layer.icon;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Modifica layer"),
          content: StatefulBuilder(
            builder: (context, setState) {
              return _layerEditor(
                nameCtrl,
                selectedColor,
                selectedIcon,
                (c) {
                  setState(() {
                    selectedColor = c;
                  });
                },
                (i) {
                  setState(() {
                    selectedIcon = i;
                  });
                },
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Annulla"),
            ),
            ElevatedButton(
              onPressed: () async {
                layer.name = nameCtrl.text;
                layer.color = selectedColor;
                layer.icon = selectedIcon;

                await controller.db.updateLayer(layer);

                // controller.refreshLayerMarkers(layer.id);

                setModalState(() {});
                onChanged();
                Navigator.pop(dialogContext);
              },
              child: const Text("Salva"),
            ),
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------
  // EDITOR LAYER (nome, colore, icona)
  // ------------------------------------------------------------
  Widget _layerEditor(
    TextEditingController nameCtrl,
    Color selectedColor,
    IconData selectedIcon,
    Function(Color) onColor,
    Function(IconData) onIcon,
  ) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(selectedIcon, color: selectedColor, size: 28),
              ),

              const SizedBox(width: 12),

              Flexible(
                child: TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Nome layer"),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          const Text("Colore"),

          Wrap(
            spacing: 8,
            children:
                [
                  Colors.red,
                  Colors.orange,
                  Colors.yellow,
                  Colors.blue,
                  Colors.cyanAccent,
                  Colors.green,
                  Colors.purple,
                  Colors.grey,
                  Colors.brown,
                  Colors.blueGrey,
                ].map((c) {
                  return GestureDetector(
                    onTap: () => onColor(c),
                    child: CircleAvatar(
                      backgroundColor: c,
                      child: selectedColor == c
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
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
                  Icons.accessibility,
                  Icons.account_balance,
                  Icons.photo,
                  Icons.yard,
                ].map((i) {
                  return IconButton(
                    icon: Icon(
                      i,
                      color: selectedIcon == i ? Colors.blue : null,
                    ),
                    onPressed: () => onIcon(i),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // ELIMINAZIONE LAYER
  // ------------------------------------------------------------
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
                onChanged(); // 🔥 aggiorna la mappa
              },
              child: const Text("Elimina"),
            ),
          ],
        );
      },
    );
  }
}
