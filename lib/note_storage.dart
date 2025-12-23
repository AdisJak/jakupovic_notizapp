import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'note.dart';

class NoteFileStorage {
  static const String _fileName = 'notes.json';

  Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<void> saveNotes(List<Note> notes) async {
    final file = await _getFile();
    final jsonList = notes.map((n) => n.toJson()).toList();
    final jsonString = json.encode(jsonList);
    await file.writeAsString(jsonString);
  }

  Future<List<Note>> loadNotes() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) {
        return [];
      }

      final jsonString = await file.readAsString();
      if (jsonString.isEmpty) return [];

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((item) => Note.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Falls etwas schiefgeht, lieber leere Liste zurückgeben
      return [];
    }
  }
}
