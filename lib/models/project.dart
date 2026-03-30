class Project {
  final int? id;
  final String title;
  final String mediaPath;
  final String englishTranscript;
  final String translatedText;
  final String targetLanguage;
  final String createdAt;

  Project({
    this.id, 
    required this.title, 
    required this.mediaPath, 
    required this.englishTranscript, 
    required this.translatedText, 
    required this.targetLanguage,
    required this.createdAt
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'mediaPath': mediaPath,
      'englishTranscript': englishTranscript,
      'translatedText': translatedText,
      'targetLanguage': targetLanguage,
      'createdAt': createdAt,
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'],
      title: map['title'],
      mediaPath: map['mediaPath'],
      englishTranscript: map['englishTranscript'],
      translatedText: map['translatedText'] ?? map['hausaTranslation'] ?? '',
      targetLanguage: map['targetLanguage'] ?? 'Hausa',
      createdAt: map['createdAt'],
    );
  }
}
