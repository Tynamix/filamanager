import 'dart:convert';
import 'dart:io';

import 'package:filamanager/persistence/inventory_store.dart';

final class JsonInventoryStore implements InventoryStore {
  JsonInventoryStore(this.file);

  static const currentSchemaVersion = 1;

  final File file;
  Future<InventoryDocument>? _opening;

  @override
  Future<InventoryDocument> open() => _opening ??= _open();

  Future<InventoryDocument> _open() async {
    if (!await file.exists()) {
      await _createEmptyStore();
    }

    final contents = await file.readAsString();
    final decoded = jsonDecode(contents);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Inventory store must contain a JSON object.',
      );
    }

    final schemaVersion = decoded['schemaVersion'];
    if (schemaVersion is! int || schemaVersion != currentSchemaVersion) {
      throw FormatException('Unsupported inventory schema: $schemaVersion');
    }

    return InventoryDocument(schemaVersion: schemaVersion);
  }

  Future<void> _createEmptyStore() async {
    await file.parent.create(recursive: true);
    final temporaryFile = File('${file.path}.tmp');
    final contents = jsonEncode(<String, Object>{
      'schemaVersion': currentSchemaVersion,
    });
    await temporaryFile.writeAsString(contents, flush: true);
    await temporaryFile.rename(file.path);
  }
}
