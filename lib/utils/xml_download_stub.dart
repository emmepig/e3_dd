import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> downloadXML(String xml, String filename) async {
  final dir = await getTemporaryDirectory();

  final file = File('${dir.path}/$filename');

  await file.writeAsString(xml);

  await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
}
