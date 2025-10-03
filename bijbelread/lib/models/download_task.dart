import 'bible_book.dart';
import 'bible_chapter.dart';
import 'offline_content.dart';

/// Model representing a download task
class DownloadTask {
  final String id;
  final DownloadType type;
  final String bookId;
  final String bookName;
  final String testament;
  final int? chapter;
  final int? startVerse;
  final int? endVerse;
  final DownloadStatus status;
  final double progress;
  final int downloadedItems;
  final int totalItems;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? error;
  final int retryCount;
  final bool isBackground;

  const DownloadTask({
    required this.id,
    required this.type,
    required this.bookId,
    required this.bookName,
    required this.testament,
    this.chapter,
    this.startVerse,
    this.endVerse,
    required this.status,
    required this.progress,
    required this.downloadedItems,
    required this.totalItems,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.error,
    this.retryCount = 0,
    this.isBackground = false,
  });

  /// Create a book download task
  factory DownloadTask.book({
    required BibleBook book,
    required int totalVerses,
    bool isBackground = false,
  }) {
    return DownloadTask(
      id: 'book_${book.id}_${DateTime.now().millisecondsSinceEpoch}',
      type: DownloadType.book,
      bookId: book.id,
      bookName: book.name,
      testament: book.testament,
      status: DownloadStatus.pending,
      progress: 0.0,
      downloadedItems: 0,
      totalItems: totalVerses,
      createdAt: DateTime.now(),
      isBackground: isBackground,
    );
  }

  /// Create a chapter download task
  factory DownloadTask.chapter({
    required BibleBook book,
    required BibleChapter chapter,
    int? startVerse,
    int? endVerse,
    bool isBackground = false,
  }) {
    return DownloadTask(
      id: 'chapter_${book.id}_${chapter.chapter}_${DateTime.now().millisecondsSinceEpoch}',
      type: DownloadType.chapter,
      bookId: book.id,
      bookName: book.name,
      testament: book.testament,
      chapter: chapter.chapter,
      startVerse: startVerse,
      endVerse: endVerse,
      status: DownloadStatus.pending,
      progress: 0.0,
      downloadedItems: 0,
      totalItems: endVerse != null && startVerse != null
          ? endVerse - startVerse + 1
          : chapter.verseCount,
      createdAt: DateTime.now(),
      isBackground: isBackground,
    );
  }

  /// Create from JSON data
  factory DownloadTask.fromJson(Map<String, dynamic> json) {
    return DownloadTask(
      id: json['id'] as String,
      type: DownloadType.values[json['type'] as int],
      bookId: json['bookId'] as String,
      bookName: json['bookName'] as String,
      testament: json['testament'] as String,
      chapter: json['chapter'] as int?,
      startVerse: json['startVerse'] as int?,
      endVerse: json['endVerse'] as int?,
      status: DownloadStatus.values[json['status'] as int],
      progress: (json['progress'] as num).toDouble(),
      downloadedItems: json['downloadedItems'] as int,
      totalItems: json['totalItems'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      error: json['error'] as String?,
      retryCount: json['retryCount'] as int,
      isBackground: json['isBackground'] as bool,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'bookId': bookId,
      'bookName': bookName,
      'testament': testament,
      'chapter': chapter,
      'startVerse': startVerse,
      'endVerse': endVerse,
      'status': status.index,
      'progress': progress,
      'downloadedItems': downloadedItems,
      'totalItems': totalItems,
      'createdAt': createdAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'error': error,
      'retryCount': retryCount,
      'isBackground': isBackground,
    };
  }

  /// Get description of the download task
  String get description {
    switch (type) {
      case DownloadType.book:
        return 'Download $bookName (volledig boek)';
      case DownloadType.chapter:
        return 'Download $bookName $chapter';
      case DownloadType.verses:
        if (startVerse != null && endVerse != null) {
          return 'Download $bookName $chapter:${startVerse!}-${endVerse!}';
        }
        return 'Download $bookName $chapter (selectie)';
    }
  }

  /// Get formatted progress text
  String get progressText {
    return '$downloadedItems/$totalItems (${progress.toStringAsFixed(1)}%)';
  }

  /// Check if task can be retried
  bool get canRetry => status == DownloadStatus.failed && retryCount < 3;

  /// Check if task is active (downloading or pending)
  bool get isActive => status == DownloadStatus.downloading || status == DownloadStatus.pending;

  /// Check if task is completed
  bool get isCompleted => status == DownloadStatus.completed;

  /// Check if task has failed
  bool get hasFailed => status == DownloadStatus.failed;

  @override
  String toString() =>
      'DownloadTask(id: $id, type: $type, bookId: $bookId, progress: ${progress.toStringAsFixed(1)}%, status: $status)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadTask && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  /// Create a copy with updated fields
  DownloadTask copyWith({
    String? id,
    DownloadType? type,
    String? bookId,
    String? bookName,
    String? testament,
    int? chapter,
    int? startVerse,
    int? endVerse,
    DownloadStatus? status,
    double? progress,
    int? downloadedItems,
    int? totalItems,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    String? error,
    int? retryCount,
    bool? isBackground,
  }) {
    return DownloadTask(
      id: id ?? this.id,
      type: type ?? this.type,
      bookId: bookId ?? this.bookId,
      bookName: bookName ?? this.bookName,
      testament: testament ?? this.testament,
      chapter: chapter ?? this.chapter,
      startVerse: startVerse ?? this.startVerse,
      endVerse: endVerse ?? this.endVerse,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      downloadedItems: downloadedItems ?? this.downloadedItems,
      totalItems: totalItems ?? this.totalItems,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      error: error ?? this.error,
      retryCount: retryCount ?? this.retryCount,
      isBackground: isBackground ?? this.isBackground,
    );
  }
}

/// Download type enumeration
enum DownloadType {
  book,
  chapter,
  verses,
}

/// Extension for DownloadType to get localized strings
extension DownloadTypeExtension on DownloadType {
  String getLocalizedString() {
    switch (this) {
      case DownloadType.book:
        return 'Boek';
      case DownloadType.chapter:
        return 'Hoofdstuk';
      case DownloadType.verses:
        return 'Verzen';
    }
  }
}