import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';

Future<void> downloadXML(String xml, String filename) async {
  await FileSaver.instance.saveFile(
    name: filename.replaceAll('.xml', ''),
    bytes: Uint8List.fromList(xml.codeUnits),
    ext: 'xml',
    mimeType: MimeType.text,
  );
}
