import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'note.dart';

class NoteStorage {
  static const String _keyNotes = 'notes';

  /// Speichert die Liste der Notizen als JSON in SharedPreferences
  Future<void> saveNotes(List<Note> notes) async {
    final prefs = await SharedPreferences.getInstance();

    // List<Note> -> List<Map> -> JSON-String
    final jsonList = notes.map((note) => note.toJson()).toList();
    final jsonString = json.encode(jsonList);

    await prefs.setString(_keyNotes, jsonString);
  }

  /// Lädt die Notizen aus SharedPreferences
  Future<List<Note>> loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyNotes);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((item) => Note.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Falls was schief geht, lieber leer zurückgeben
      return [];
    }
  }
}
