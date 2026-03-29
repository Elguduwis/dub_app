class Project {
  final int? id;
  final String title;
  final String mediaPath;
  final String englishTranscript;
  final String hausaTranslation;
  final String createdAt;

  Project({this.id, required this.title, required this.mediaPath, required this.englishTranscript, required this.hausaTranslation, required this.createdAt});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'mediaPath': mediaPath,
      'englishTranscript': englishTranscript,
      'hausaTranslation': hausaTranslation,
      'createdAt': createdAt,
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'],
      title: map['title'],
      mediaPath: map['mediaPath'],
      englishTranscript: map['englishTranscript'],
      hausaTranslation: map['hausaTranslation'],
      createdAt: map['createdAt'],
    );
  }
}
