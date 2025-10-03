/// Model representing a Bible chapter with offline availability
class BibleChapter {
  final String bookId;
  final int chapter;
  final int verseCount;
  final bool isAvailableOffline;
  final int downloadedVerses;
  final DateTime? lastOfflineUpdate;

  const BibleChapter({
    required this.bookId,
    required this.chapter,
    required this.verseCount,
    this.isAvailableOffline = false,
    this.downloadedVerses = 0,
    this.lastOfflineUpdate,
  });

  /// Create a BibleChapter from JSON data
  factory BibleChapter.fromJson(Map<String, dynamic> json) {
    return BibleChapter(
      bookId: json['book'] as String,
      chapter: json['chapter'] as int,
      verseCount: json['verses'] as int,
      isAvailableOffline: json['isAvailableOffline'] as bool? ?? false,
      downloadedVerses: json['downloadedVerses'] as int? ?? 0,
      lastOfflineUpdate: json['lastOfflineUpdate'] != null
          ? DateTime.parse(json['lastOfflineUpdate'] as String)
          : null,
    );
  }

  /// Convert BibleChapter to JSON
  Map<String, dynamic> toJson() {
    return {
      'book': bookId,
      'chapter': chapter,
      'verses': verseCount,
      'isAvailableOffline': isAvailableOffline,
      'downloadedVerses': downloadedVerses,
      'lastOfflineUpdate': lastOfflineUpdate?.toIso8601String(),
    };
  }

  /// Get download progress percentage
  double get downloadProgress => verseCount > 0 ? (downloadedVerses / verseCount) * 100 : 0.0;

  /// Check if chapter is fully downloaded
  bool get isFullyDownloaded => downloadedVerses >= verseCount;

  /// Get offline status description
  String get offlineStatus {
    if (!isAvailableOffline) return 'Niet gedownload';
    if (isFullyDownloaded) return 'Volledig gedownload';
    return '$downloadedVerses/$verseCount verzen gedownload';
  }

  @override
  String toString() => 'BibleChapter(bookId: $bookId, chapter: $chapter, verses: $verseCount, offline: $isAvailableOffline)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BibleChapter &&
      runtimeType == other.runtimeType &&
      bookId == other.bookId &&
      chapter == other.chapter;

  @override
  int get hashCode => bookId.hashCode ^ chapter.hashCode;
}