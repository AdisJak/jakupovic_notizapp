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
    _sortNotes(notes);
    setState(() {
      _notes = notes;
      _filteredNotes = List.from(notes);
      _isLoading = false;
    });
  }

  void _sortNotes(List<Note> list) {
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void _refresh() {
    _sortNotes(_notes);
    _applyFilter();
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

  int _realIndex(int filteredIndex) =>
      _notes.indexOf(_filteredNotes[filteredIndex]);

  Future<void> _save() async => _storage.saveNotes(_notes);

  Future<void> _addNote(Note note) async {
    setState(() {
      _notes.add(note);
      _refresh();
    });
    await _save();
  }

  Future<void> _updateNote(int filteredIndex, Note updated) async {
    final real = _realIndex(filteredIndex);
    setState(() {
      _notes[real] = updated;
      _refresh();
    });
    await _save();
  }

  Future<void> _deleteNote(int filteredIndex) async {
    final note = _filteredNotes[filteredIndex];
    final real = _realIndex(filteredIndex);

    setState(() {
      _notes.removeAt(real);
      _refresh();
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
              _notes.insert(real, note);
              _refresh();
            });
            await _save();
          },
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}.'
        '${d.month.toString().padLeft(2, '0')}.'
        '${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }

  Future<Note?> _showNoteDialog({Note? initial}) async {
    final titleController = TextEditingController(text: initial?.title ?? '');
    final contentController = TextEditingController(
      text: initial?.content ?? '',
    );

    return showDialog<Note>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(initial == null ? 'Neue Notiz' : 'Notiz bearbeiten'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 420,
                child: TextField(
                  controller: titleController,
                  maxLength: 40,
                  decoration: const InputDecoration(
                    labelText: 'Titel',
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
                  controller: contentController,
                  maxLength: 250,
                  decoration: const InputDecoration(
                    labelText: 'Inhalt',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              final title = titleController.text.trim();
              final content = contentController.text.trim();

              if (title.isEmpty && content.isEmpty) {
                Navigator.pop(context);
                return;
              }

              Navigator.pop(
                context,
                Note(title: title, content: content, createdAt: DateTime.now()),
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
        : _filteredNotes.isEmpty
        ? const Center(child: Text('Keine Notizen'))
        : ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            itemCount: _filteredNotes.length,
            itemBuilder: (context, i) {
              final note = _filteredNotes[i];

              return Dismissible(
                key: ValueKey(note.createdAt.toIso8601String()),
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
                      if (updated != null) {
                        await _updateNote(i, updated);
                      }
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
                                      ? '(Ohne Titel)'
                                      : note.title,
                                  style: const TextStyle(fontSize: 18),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Geändert: ${_formatDate(note.createdAt)}',
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
        title: const Text('Jakupovic Notizapp'),
        actions: [
          const Icon(Icons.light_mode, size: 20),
          Switch(value: widget.isDarkMode, onChanged: widget.onThemeChanged),
          const Icon(Icons.dark_mode, size: 20),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Suche nach Titel…',
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
        label: const Text('Neue Notiz'),
        onPressed: () async {
          final note = await _showNoteDialog();
          if (note != null) {
            await _addNote(note);
          }
        },
      ),
    );
  }
}
