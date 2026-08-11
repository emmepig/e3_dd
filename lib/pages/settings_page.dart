import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../controllers/point_layer_controller.dart';
import '../utils/xml_download.dart';
import 'package:intl/intl.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.controller});
  final PointLayerController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Sincronizza'),
            onTap: () async {
              final xml = controller.exportLayerToXML();

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
