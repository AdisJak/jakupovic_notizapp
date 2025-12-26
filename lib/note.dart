class Note {
  String title;
  String content;
  DateTime createdAt;

  Note({required this.title, required this.content, required this.createdAt});

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
