/// Model representing a Bible verse with offline availability
class BibleVerse {
  final String bookId;
  final int chapter;
  final int verse;
  final String text;
  final bool isAvailableOffline;
  final DateTime? lastOfflineUpdate;

  const BibleVerse({
    required this.bookId,
    required this.chapter,
    required this.verse,
    required this.text,
    this.isAvailableOffline = false,
    this.lastOfflineUpdate,
  });

  /// Create a BibleVerse from JSON data
  factory BibleVerse.fromJson(Map<String, dynamic> json) {
    return BibleVerse(
      bookId: json['book'] as String,
      chapter: json['chapter'] as int,
      verse: json['verse'] as int,
      text: json['text'] as String,
      isAvailableOffline: json['isAvailableOffline'] as bool? ?? false,
      lastOfflineUpdate: json['lastOfflineUpdate'] != null
          ? DateTime.parse(json['lastOfflineUpdate'] as String)
          : null,
    );
  }

  /// Convert BibleVerse to JSON
  Map<String, dynamic> toJson() {
    return {
      'book': bookId,
      'chapter': chapter,
      'verse': verse,
      'text': text,
      'isAvailableOffline': isAvailableOffline,
      'lastOfflineUpdate': lastOfflineUpdate?.toIso8601String(),
    };
  }

  /// Get formatted reference (e.g., "Genesis 1:1")
  String get reference {
    return '$bookId $chapter:$verse';
  }

  /// Get offline status description
  String get offlineStatus {
    return isAvailableOffline ? 'Beschikbaar offline' : 'Alleen online';
  }

  @override
  String toString() => 'BibleVerse(bookId: $bookId, chapter: $chapter, verse: $verse, text: $text, offline: $isAvailableOffline)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BibleVerse &&
      runtimeType == other.runtimeType &&
      bookId == other.bookId &&
      chapter == other.chapter &&
      verse == other.verse;

  @override
  int get hashCode => bookId.hashCode ^ chapter.hashCode ^ verse.hashCode;
}