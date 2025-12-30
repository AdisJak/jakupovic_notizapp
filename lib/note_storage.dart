import 'dart:convert';
import 'dart:io';

import 'note.dart';

class NoteStorage {
  static const _fileName = 'notes.json';

  Future<File> _getFile() async {
    // aktueller Projekt/Programm-Ordner
    final dir = Directory.current;

    // Unterordner "data" anlegen (falls nicht vorhanden)
    final folder = Directory('${dir.path}/data');
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    return File('${folder.path}/$_fileName');
  }

  Future<List<Note>> loadNotes() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return [];

      final text = await file.readAsString();
      if (text.isEmpty) return [];

      final List<dynamic> jsonList = json.decode(text);
      return jsonList
          .map((e) => Note.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveNotes(List<Note> notes) async {
    final file = await _getFile();
    final jsonList = notes.map((e) => e.toJson()).toList();
    final jsonString = const JsonEncoder.withIndent('  ').convert(jsonList);
    await file.writeAsString(jsonString, flush: true);
  }
}
