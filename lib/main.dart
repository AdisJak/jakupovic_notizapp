import 'package:flutter/material.dart';
import 'page.dart'; // <-- kein hide, ganz normal importieren

void main() {
  runApp(const NotesApp());
}

class NotesApp extends StatelessWidget {
  const NotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notizen',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const NotesPage(), // <-- WICHTIG: Name muss zur Klasse passen
    );
  }
}
