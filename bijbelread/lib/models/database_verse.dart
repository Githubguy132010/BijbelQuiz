/// Model representing a Bible verse stored in the local database
class DatabaseVerse {
  final int id;
  final String bookId;
  final int chapter;
  final int verse;
  final String text;
  final String testament;
  final String bookName;
  final DateTime downloadedAt;
  final DateTime? lastAccessedAt;
  final int accessCount;

  const DatabaseVerse({
    required this.id,
    required this.bookId,
    required this.chapter,
    required this.verse,
    required this.text,
    required this.testament,
    required this.bookName,
    required this.downloadedAt,
    this.lastAccessedAt,
    this.accessCount = 0,
  });

  /// Create from BibleVerse with additional metadata
  factory DatabaseVerse.fromBibleVerse(
    bibleVerse, {
    required String testament,
    required String bookName,
    DateTime? lastAccessedAt,
    int accessCount = 0,
  }) {
    return DatabaseVerse(
      id: 0, // Will be set by database
      bookId: bibleVerse.bookId,
      chapter: bibleVerse.chapter,
      verse: bibleVerse.verse,
      text: bibleVerse.text,
      testament: testament,
      bookName: bookName,
      downloadedAt: DateTime.now(),
      lastAccessedAt: lastAccessedAt,
      accessCount: accessCount,
    );
  }

  /// Create from JSON data
  factory DatabaseVerse.fromJson(Map<String, dynamic> json) {
    return DatabaseVerse(
      id: json['id'] as int,
      bookId: json['bookId'] as String,
      chapter: json['chapter'] as int,
      verse: json['verse'] as int,
      text: json['text'] as String,
      testament: json['testament'] as String,
      bookName: json['bookName'] as String,
      downloadedAt: DateTime.parse(json['downloadedAt'] as String),
      lastAccessedAt: json['lastAccessedAt'] != null
          ? DateTime.parse(json['lastAccessedAt'] as String)
          : null,
      accessCount: json['accessCount'] as int,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'chapter': chapter,
      'verse': verse,
      'text': text,
      'testament': testament,
      'bookName': bookName,
      'downloadedAt': downloadedAt.toIso8601String(),
      'lastAccessedAt': lastAccessedAt?.toIso8601String(),
      'accessCount': accessCount,
    };
  }

  /// Get formatted reference (e.g., "Genesis 1:1")
  String get reference => '$bookName $chapter:$verse';

  /// Get full reference with book ID (e.g., "gen 1:1")
  String get shortReference => '$bookId $chapter:$verse';

  /// Create a copy with updated fields
  DatabaseVerse copyWith({
    int? id,
    String? bookId,
    int? chapter,
    int? verse,
    String? text,
    String? testament,
    String? bookName,
    DateTime? downloadedAt,
    DateTime? lastAccessedAt,
    int? accessCount,
  }) {
    return DatabaseVerse(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      chapter: chapter ?? this.chapter,
      verse: verse ?? this.verse,
      text: text ?? this.text,
      testament: testament ?? this.testament,
      bookName: bookName ?? this.bookName,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      accessCount: accessCount ?? this.accessCount,
    );
  }

  /// Create a copy with updated access tracking
  DatabaseVerse withAccessUpdate() {
    return copyWith(
      lastAccessedAt: DateTime.now(),
      accessCount: accessCount + 1,
    );
  }

  @override
  String toString() =>
      'DatabaseVerse(id: $id, reference: $reference, length: ${text.length})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DatabaseVerse &&
      runtimeType == other.runtimeType &&
      id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Model for verse search results from database
class DatabaseSearchResult {
  final DatabaseVerse verse;
  final String query;
  final double relevance;

  const DatabaseSearchResult({
    required this.verse,
    required this.query,
    required this.relevance,
  });

  /// Create from JSON data
  factory DatabaseSearchResult.fromJson(Map<String, dynamic> json) {
    return DatabaseSearchResult(
      verse: DatabaseVerse.fromJson(json['verse'] as Map<String, dynamic>),
      query: json['query'] as String,
      relevance: (json['relevance'] as num).toDouble(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'verse': verse.toJson(),
      'query': query,
      'relevance': relevance,
    };
  }

  @override
  String toString() =>
      'DatabaseSearchResult(verse: ${verse.reference}, relevance: ${relevance.toStringAsFixed(2)})';
}

/// Model for database statistics
class DatabaseStats {
  final int totalVerses;
  final int totalBooks;
  final int totalChapters;
  final double totalSize; // in MB
  final DateTime lastUpdated;
  final Map<String, int> versesByTestament;
  final Map<String, int> versesByBook;

  const DatabaseStats({
    required this.totalVerses,
    required this.totalBooks,
    required this.totalChapters,
    required this.totalSize,
    required this.lastUpdated,
    required this.versesByTestament,
    required this.versesByBook,
  });

  /// Create from JSON data
  factory DatabaseStats.fromJson(Map<String, dynamic> json) {
    return DatabaseStats(
      totalVerses: json['totalVerses'] as int,
      totalBooks: json['totalBooks'] as int,
      totalChapters: json['totalChapters'] as int,
      totalSize: (json['totalSize'] as num).toDouble(),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      versesByTestament: Map<String, int>.from(json['versesByTestament'] as Map),
      versesByBook: Map<String, int>.from(json['versesByBook'] as Map),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'totalVerses': totalVerses,
      'totalBooks': totalBooks,
      'totalChapters': totalChapters,
      'totalSize': totalSize,
      'lastUpdated': lastUpdated.toIso8601String(),
      'versesByTestament': versesByTestament,
      'versesByBook': versesByBook,
    };
  }

  /// Get formatted total size
  String get formattedSize {
    if (totalSize < 1) {
      return '${(totalSize * 1024).round()} KB';
    }
    return '${totalSize.toStringAsFixed(1)} MB';
  }

  @override
  String toString() =>
      'DatabaseStats(verses: $totalVerses, books: $totalBooks, size: $formattedSize)';
}