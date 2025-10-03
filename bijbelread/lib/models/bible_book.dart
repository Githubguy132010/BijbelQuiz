/// Model representing a Bible book with offline availability
class BibleBook {
  final String id;
  final String name;
  final String testament; // 'old' or 'new'
  final int chapterCount;
  final bool isAvailableOffline;
  final int downloadedChapters;
  final DateTime? lastOfflineUpdate;

  const BibleBook({
    required this.id,
    required this.name,
    required this.testament,
    required this.chapterCount,
    this.isAvailableOffline = false,
    this.downloadedChapters = 0,
    this.lastOfflineUpdate,
  });

  /// Create a BibleBook from JSON data
  factory BibleBook.fromJson(Map<String, dynamic> json) {
    return BibleBook(
      id: json['id'] as String,
      name: json['name'] as String,
      testament: json['testament'] as String,
      chapterCount: json['chapters'] as int,
      isAvailableOffline: json['isAvailableOffline'] as bool? ?? false,
      downloadedChapters: json['downloadedChapters'] as int? ?? 0,
      lastOfflineUpdate: json['lastOfflineUpdate'] != null
          ? DateTime.parse(json['lastOfflineUpdate'] as String)
          : null,
    );
  }

  /// Convert BibleBook to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'testament': testament,
      'chapters': chapterCount,
      'isAvailableOffline': isAvailableOffline,
      'downloadedChapters': downloadedChapters,
      'lastOfflineUpdate': lastOfflineUpdate?.toIso8601String(),
    };
  }

  /// Get download progress percentage
  double get downloadProgress => chapterCount > 0 ? (downloadedChapters / chapterCount) * 100 : 0.0;

  /// Check if book is fully downloaded
  bool get isFullyDownloaded => downloadedChapters >= chapterCount;

  /// Get offline status description
  String get offlineStatus {
    if (!isAvailableOffline) return 'Niet gedownload';
    if (isFullyDownloaded) return 'Volledig gedownload';
    return '$downloadedChapters/$chapterCount hoofdstukken gedownload';
  }

  @override
  String toString() => 'BibleBook(id: $id, name: $name, testament: $testament, chapters: $chapterCount, offline: $isAvailableOffline)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BibleBook && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}