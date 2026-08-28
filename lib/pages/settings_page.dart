import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_provider.dart';
import '../controllers/point_layer_controller.dart';
import '../utils/xml_download.dart';
import '../utils/xml_send_web.dart';
import '../services/app_settings.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final PointLayerController pointLayerController = PointLayerController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.gps_fixed),
            title: const Text('Precisione GPS minima'),
            subtitle: Text(
              '${AppSettings.gpsAccuracyThreshold.toStringAsFixed(1)} m',
            ),
            onTap: () async {
              final textController = TextEditingController(
                text: AppSettings.gpsAccuracyThreshold.toString(),
              );

              final value = await showDialog<double>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Precisione GPS'),
                  content: TextField(
                    controller: textController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Metri'),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annulla'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final v = double.tryParse(
                          textController.text.replaceAll(',', '.'),
                        );

                        Navigator.pop(context, v);
                      },
                      child: const Text('Salva'),
                    ),
                  ],
                ),
              );

              if (value != null) {
                await AppSettings.setGpsAccuracyThreshold(value);

                setState(() {});
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Sincronizza WEB'),
            onTap: () async {
              final xml = pointLayerController.exportLayerToXML();

              final messaggioFinale = await inviaXmlAlServer(xml: xml);

              if (!context.mounted) return;

              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(messaggioFinale)));
            },
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Download XML'),
            onTap: () async {
              final xml = pointLayerController.exportLayerToXML();

              final timestamp = DateFormat(
                'yyyyMMdd_HHmmss',
              ).format(DateTime.now());

              await downloadXML(xml, "elenco_$timestamp.xml");

              if (!context.mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sincronizzazione non ancora implementata'),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Esci'),
            onTap: () async {
              await context.read<AuthProvider>().logout();

              if (context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }
}
