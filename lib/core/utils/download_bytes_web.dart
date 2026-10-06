import 'dart:typed_data';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

Future<void> downloadBytes(
    List<int> bytes, String fileName, String subject) async {
  final uint8List = Uint8List.fromList(bytes);
  final blob = web.Blob(
    [uint8List.toJS].toJS,
    web.BlobPropertyBag(
      type:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    ),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.setAttribute('download', fileName);
  anchor.click();
  web.URL.revokeObjectURL(url);
}
