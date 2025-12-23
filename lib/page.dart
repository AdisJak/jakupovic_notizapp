import 'package:flutter/material.dart';
import 'note.dart';
import 'note_storage.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final NoteFileStorage _storage = NoteFileStorage();
  List<Note> _notes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final notes = await _storage.loadNotes();
    setState(() {
      _notes = notes;
      _isLoading = false;
    });
  }

  Future<void> _addNote(Note note) async {
    setState(() {
      _notes.add(note);
    });
    await _storage.saveNotes(_notes);
  }

  Future<void> _updateNote(int index, Note updatedNote) async {
    setState(() {
      _notes[index] = updatedNote;
    });
    await _storage.saveNotes(_notes);
  }

  Future<void> _deleteNote(int index) async {
    final removed = _notes[index];

    setState(() {
      _notes.removeAt(index);
    });
    await _storage.saveNotes(_notes);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notiz "${removed.title}" gelöscht'),
        action: SnackBarAction(
          label: 'Rückgängig',
          onPressed: () async {
            setState(() {
              _notes.insert(index, removed);
            });
            await _storage.saveNotes(_notes);
          },
        ),
      ),
    );
  }

  Future<Note?> _showNoteDialog({Note? initial}) async {
    final titleController = TextEditingController(text: initial?.title ?? '');
    final contentController =
        TextEditingController(text: initial?.content ?? '');

    return showDialog<Note>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(initial == null ? 'Neue Notiz' : 'Notiz bearbeiten'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Titel'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentController,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Inhalt'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              final content = contentController.text.trim();

              if (title.isEmpty && content.isEmpty) {
                Navigator.pop(context, null);
                return;
              }

              Navigator.pop(
                context,
                Note(title: title, content: content),
              );
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _notes.isEmpty
            ? const Center(
                child: Text('Noch keine Notizen.\nDrück auf +.'),
              )
            : ListView.builder(
                itemCount: _notes.length,
                itemBuilder: (context, index) {
                  final note = _notes[index];
                  return Dismissible(
                    key: ValueKey('note_$index'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const Icon(Icons.delete),
                    ),
                    onDismissed: (_) => _deleteNote(index),
                    child: ListTile(
                      title: Text(
                        note.title.isEmpty ? '(Ohne Titel)' : note.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: note.content.isEmpty
                          ? null
                          : Text(
                              note.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                      onTap: () async {
                        final updated =
                            await _showNoteDialog(initial: note);
                        if (updated != null) {
                          await _updateNote(index, updated);
                        }
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteNote(index),
                      ),
                    ),
                  );
                },
              );

    return Scaffold(
      appBar: AppBar(title: const Text('Notizen')),
      body: body,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newNote = await _showNoteDialog();
          if (newNote != null) {
            await _addNote(newNote);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
