import 'package:flutter/material.dart';
import 'note.dart';
import 'note_storage.dart';

class NotesPage extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  const NotesPage({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final NoteStorage _storage = NoteStorage();
  final TextEditingController _searchController = TextEditingController();

  List<Note> _notes = [];
  List<Note> _filteredNotes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    final notes = await _storage.loadNotes();

    notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    setState(() {
      _notes = notes;
      _filteredNotes = List.from(notes);
      _isLoading = false;
    });
  }

  void _applyFilter() {
    final q = _searchController.text.toLowerCase();

    setState(() {
      if (q.isEmpty) {
        _filteredNotes = List.from(_notes);
      } else {
        _filteredNotes = _notes
            .where((n) => n.title.toLowerCase().contains(q))
            .toList();
      }
    });
  }

  Future<void> _save() async => _storage.saveNotes(_notes);

  Future<void> _addNote(Note n) async {
    setState(() {
      _notes.add(n);
      _notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _applyFilter();
    });
    await _save();
  }

  Future<void> _updateNote(int index, Note updated) async {
    final realIndex = _notes.indexOf(_filteredNotes[index]);

    setState(() {
      _notes[realIndex] = updated;
      _notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _applyFilter();
    });

    await _save();
  }

  Future<void> _deleteNote(int index) async {
    final note = _filteredNotes[index];
    final realIndex = _notes.indexOf(note);

    setState(() {
      _notes.removeAt(realIndex);
      _applyFilter();
    });

    await _save();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notiz "${note.title}" gelöscht'),
        action: SnackBarAction(
          label: 'Rückgängig',
          onPressed: () async {
            setState(() {
              _notes.insert(realIndex, note);
              _applyFilter();
            });
            await _save();
          },
        ),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year} "
      "${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";

  // ---------------- Dialog ----------------
  Future<Note?> _showNoteDialog({Note? initial}) async {
    final title = TextEditingController(text: initial?.title ?? '');
    final content = TextEditingController(text: initial?.content ?? '');

    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(initial == null ? "Neue Notiz" : "Notiz bearbeiten"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                width: 420,
                child: TextField(
                  controller: title,
                  maxLength: 40,
                  decoration: const InputDecoration(
                    labelText: "Titel",
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 420,
                height: 240,
                child: TextField(
                  controller: content,
                  maxLength: 250,
                  decoration: const InputDecoration(
                    labelText: "Inhalt",
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                ),
              ),
            ],
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Abbrechen"),
          ),
          FilledButton(
            onPressed: () {
              final t = title.text.trim();
              final c = content.text.trim();

              if (t.isEmpty && c.isEmpty) {
                Navigator.pop(context);
                return;
              }

              Navigator.pop(
                context,
                Note(title: t, content: c, createdAt: DateTime.now()),
              );
            },
            child: const Text("Speichern"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _filteredNotes.isEmpty
        ? const Center(child: Text("Keine Notizen"))
        : ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            itemCount: _filteredNotes.length,
            itemBuilder: (_, i) {
              final note = _filteredNotes[i];

              return Dismissible(
                key: ValueKey(note.createdAt.toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: const Icon(Icons.delete),
                ),
                onDismissed: (_) => _deleteNote(i),
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      final updated = await _showNoteDialog(initial: note);
                      if (updated != null) _updateNote(i, updated);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  note.title.isEmpty
                                      ? "(Ohne Titel)"
                                      : note.title,
                                  style: const TextStyle(fontSize: 18),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  "Geändert: ${_formatDate(note.createdAt)}",
                                  style: const TextStyle(fontSize: 12),
                                ),
                                if (note.content.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    note.content,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _deleteNote(i),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Jakupovic Notizapp"),
        actions: [
          const Icon(Icons.light_mode),
          Switch(value: widget.isDarkMode, onChanged: widget.onThemeChanged),
          const Icon(Icons.dark_mode),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: "Suche nach Titel...",
                prefixIcon: Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: body,
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text("Neue Notiz"),
        onPressed: () async {
          final n = await _showNoteDialog();
          if (n != null) _addNote(n);
        },
      ),
    );
  }
}
