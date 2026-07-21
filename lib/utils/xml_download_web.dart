import 'dart:js_interop';
import 'package:web/web.dart' as web;

void downloadXML(String xml, String filename) {
  final blob = web.Blob(
    [xml.toJS].toJS,
    web.BlobPropertyBag(type: 'text/xml;charset=utf-8'),
  );

  final url = web.URL.createObjectURL(blob);

  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename;

  anchor.click();

  web.URL.revokeObjectURL(url);
}
