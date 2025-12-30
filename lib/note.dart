class Note {
  String title;
  String content;
  DateTime createdAt;

  Note({required this.title, required this.content, required this.createdAt});

  // zum laden der Notiz aus JSON
  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  // Zum speichern der Notiz als JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
