/// Model representing a bookmark for a Bible verse
library;
import 'bible_verse.dart';

class Bookmark {
  final String id;
  final String bookId;
  final String bookName;
  final int chapter;
  final int verse;
  final String verseText;
  final String? notes;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Bookmark({
    required this.id,
    required this.bookId,
    required this.bookName,
    required this.chapter,
    required this.verse,
    required this.verseText,
    this.notes,
    this.tags = const [],
    required this.createdAt,
    this.updatedAt,
  });

  /// Create a Bookmark from a BibleVerse
  factory Bookmark.fromBibleVerse({
    required String id,
    required BibleVerse bibleVerse,
    required String bookName,
    String? notes,
    List<String> tags = const [],
  }) {
    return Bookmark(
      id: id,
      bookId: bibleVerse.bookId,
      bookName: bookName,
      chapter: bibleVerse.chapter,
      verse: bibleVerse.verse,
      verseText: bibleVerse.text,
      notes: notes,
      tags: tags,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Create a copy of this bookmark with updated fields
  Bookmark copyWith({
    String? id,
    String? bookId,
    String? bookName,
    int? chapter,
    int? verse,
    String? verseText,
    String? notes,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Bookmark(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      bookName: bookName ?? this.bookName,
      chapter: chapter ?? this.chapter,
      verse: verse ?? this.verse,
      verseText: verseText ?? this.verseText,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get formatted reference (e.g., "Genesis 1:1")
  String get reference {
    return '$bookName $chapter:$verse';
  }

  /// Get short reference (e.g., "Gen 1:1")
  String get shortReference {
    final shortBookName = _getShortBookName(bookName);
    return '$shortBookName $chapter:$verse';
  }

  /// Check if bookmark has notes
  bool get hasNotes => notes != null && notes!.isNotEmpty;

  /// Check if bookmark has tags
  bool get hasTags => tags.isNotEmpty;

  /// Get formatted tags string
  String get formattedTags {
    if (tags.isEmpty) return '';
    return tags.join(', ');
  }

  /// Static method to get abbreviated book name
  static String _getShortBookName(String fullName) {
    final name = fullName.toLowerCase();
    if (name.startsWith('genesis')) return 'Gen';
    if (name.startsWith('exodus')) return 'Ex';
    if (name.startsWith('matthe')) return 'Mat';
    if (name.startsWith('mark')) return 'Mar';
    if (name.startsWith('luke') || name.startsWith('lukas')) return 'Luk';
    if (name.startsWith('john') || name.startsWith('johannes')) return 'Joh';
    if (name.startsWith('romans') || name.startsWith('romeinen')) return 'Rom';
    if (name.startsWith('revelation') || name.startsWith('openbaring')) return 'Rev';

    return fullName.length > 3 ? fullName.substring(0, 3) : fullName;
  }

  /// Convert Bookmark to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'bookName': bookName,
      'chapter': chapter,
      'verse': verse,
      'verseText': verseText,
      'notes': notes,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Create Bookmark from JSON
  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'] as String,
      bookId: json['bookId'] as String,
      bookName: json['bookName'] as String,
      chapter: json['chapter'] as int,
      verse: json['verse'] as int,
      verseText: json['verseText'] as String,
      notes: json['notes'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    );
  }

  @override
  String toString() => 'Bookmark(id: $id, reference: $reference)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Bookmark &&
      runtimeType == other.runtimeType &&
      id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Model representing a bookmark category/tag
class BookmarkCategory {
  final String id;
  final String name;
  final String color;
  final DateTime createdAt;

  const BookmarkCategory({
    required this.id,
    required this.name,
    required this.color,
    required this.createdAt,
  });

  /// Predefined categories
  static List<BookmarkCategory> get defaultCategories => [
    BookmarkCategory(
      id: 'favorite',
      name: 'Favorieten',
      color: '#FFD700', // Gold
      createdAt: DateTime(2024, 1, 1),
    ),
    BookmarkCategory(
      id: 'study',
      name: 'Studie',
      color: '#2196F3', // Blue
      createdAt: DateTime(2024, 1, 1),
    ),
    BookmarkCategory(
      id: 'prayer',
      name: 'Gebed',
      color: '#4CAF50', // Green
      createdAt: DateTime(2024, 1, 1),
    ),
    BookmarkCategory(
      id: 'memory',
      name: 'Memoriseren',
      color: '#9C27B0', // Purple
      createdAt: DateTime(2024, 1, 1),
    ),
  ];

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory BookmarkCategory.fromJson(Map<String, dynamic> json) {
    return BookmarkCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  String toString() => 'BookmarkCategory(id: $id, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookmarkCategory &&
      runtimeType == other.runtimeType &&
      id == other.id;

  @override
  int get hashCode => id.hashCode;
}