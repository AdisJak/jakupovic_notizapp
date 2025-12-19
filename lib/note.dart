class Note {
  String title;
  String content;

  Note({
    required this.title,
    required this.content,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
    };
  }
}
