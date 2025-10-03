import 'bible_book.dart';
import 'bible_chapter.dart';

/// Model representing offline content that has been downloaded
class OfflineContent {
  final String id;
  final String bookId;
  final String bookName;
  final String testament;
  final int? chapter;
  final int? verseCount;
  final int downloadedVerses;
  final int totalVerses;
  final DateTime downloadedAt;
  final DateTime? lastAccessedAt;
  final double fileSize; // in MB
  final bool isComplete;
  final DownloadStatus status;

  const OfflineContent({
    required this.id,
    required this.bookId,
    required this.bookName,
    required this.testament,
    this.chapter,
    this.verseCount,
    required this.downloadedVerses,
    required this.totalVerses,
    required this.downloadedAt,
    this.lastAccessedAt,
    required this.fileSize,
    required this.isComplete,
    required this.status,
  });

  /// Create OfflineContent for a complete book
  factory OfflineContent.book({
    required BibleBook book,
    required int downloadedVerses,
    required int totalVerses,
    required DateTime downloadedAt,
    DateTime? lastAccessedAt,
    required double fileSize,
    required DownloadStatus status,
  }) {
    return OfflineContent(
      id: 'book_${book.id}',
      bookId: book.id,
      bookName: book.name,
      testament: book.testament,
      downloadedVerses: downloadedVerses,
      totalVerses: totalVerses,
      downloadedAt: downloadedAt,
      lastAccessedAt: lastAccessedAt,
      fileSize: fileSize,
      isComplete: downloadedVerses == totalVerses,
      status: status,
    );
  }

  /// Create OfflineContent for a specific chapter
  factory OfflineContent.chapter({
    required BibleBook book,
    required BibleChapter chapter,
    required int downloadedVerses,
    required DateTime downloadedAt,
    DateTime? lastAccessedAt,
    required double fileSize,
    required DownloadStatus status,
  }) {
    return OfflineContent(
      id: 'chapter_${book.id}_${chapter.chapter}',
      bookId: book.id,
      bookName: book.name,
      testament: book.testament,
      chapter: chapter.chapter,
      verseCount: chapter.verseCount,
      downloadedVerses: downloadedVerses,
      totalVerses: chapter.verseCount,
      downloadedAt: downloadedAt,
      lastAccessedAt: lastAccessedAt,
      fileSize: fileSize,
      isComplete: downloadedVerses == chapter.verseCount,
      status: status,
    );
  }

  /// Create from JSON data
  factory OfflineContent.fromJson(Map<String, dynamic> json) {
    return OfflineContent(
      id: json['id'] as String,
      bookId: json['bookId'] as String,
      bookName: json['bookName'] as String,
      testament: json['testament'] as String,
      chapter: json['chapter'] as int?,
      verseCount: json['verseCount'] as int?,
      downloadedVerses: json['downloadedVerses'] as int,
      totalVerses: json['totalVerses'] as int,
      downloadedAt: DateTime.parse(json['downloadedAt'] as String),
      lastAccessedAt: json['lastAccessedAt'] != null
          ? DateTime.parse(json['lastAccessedAt'] as String)
          : null,
      fileSize: (json['fileSize'] as num).toDouble(),
      isComplete: json['isComplete'] as bool,
      status: DownloadStatus.values[json['status'] as int],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'bookName': bookName,
      'testament': testament,
      'chapter': chapter,
      'verseCount': verseCount,
      'downloadedVerses': downloadedVerses,
      'totalVerses': totalVerses,
      'downloadedAt': downloadedAt.toIso8601String(),
      'lastAccessedAt': lastAccessedAt?.toIso8601String(),
      'fileSize': fileSize,
      'isComplete': isComplete,
      'status': status.index,
    };
  }

  /// Get download progress percentage
  double get progress => totalVerses > 0 ? (downloadedVerses / totalVerses) * 100 : 0.0;

  /// Get formatted file size
  String get formattedFileSize {
    if (fileSize < 1) {
      return '${(fileSize * 1024).round()} KB';
    }
    return '${fileSize.toStringAsFixed(1)} MB';
  }

  /// Get content type description
  String get contentType {
    if (chapter != null) {
      return 'Hoofdstuk $chapter';
    }
    return 'Volledig boek';
  }

  @override
  String toString() =>
      'OfflineContent(id: $id, bookId: $bookId, chapter: $chapter, progress: ${progress.toStringAsFixed(1)}%, complete: $isComplete)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfflineContent && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  /// Create a copy with updated fields
  OfflineContent copyWith({
    String? id,
    String? bookId,
    String? bookName,
    String? testament,
    int? chapter,
    int? verseCount,
    int? downloadedVerses,
    int? totalVerses,
    DateTime? downloadedAt,
    DateTime? lastAccessedAt,
    double? fileSize,
    bool? isComplete,
    DownloadStatus? status,
  }) {
    return OfflineContent(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      bookName: bookName ?? this.bookName,
      testament: testament ?? this.testament,
      chapter: chapter ?? this.chapter,
      verseCount: verseCount ?? this.verseCount,
      downloadedVerses: downloadedVerses ?? this.downloadedVerses,
      totalVerses: totalVerses ?? this.totalVerses,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      fileSize: fileSize ?? this.fileSize,
      isComplete: isComplete ?? this.isComplete,
      status: status ?? this.status,
    );
  }
}

/// Download status enumeration
enum DownloadStatus {
  pending,
  downloading,
  completed,
  failed,
  paused,
}

/// Extension for DownloadStatus to get localized strings
extension DownloadStatusExtension on DownloadStatus {
  String getLocalizedString() {
    switch (this) {
      case DownloadStatus.pending:
        return 'Wachten';
      case DownloadStatus.downloading:
        return 'Downloaden';
      case DownloadStatus.completed:
        return 'Voltooid';
      case DownloadStatus.failed:
        return 'Mislukt';
      case DownloadStatus.paused:
        return 'Gepauzeerd';
    }
  }
}