import 'dart:async';

import 'logger.dart';
import 'bible_service.dart';
import 'offline_bible_service.dart';
import 'connection_service.dart';
import '../models/bible_verse.dart';
import '../models/offline_content.dart';

/// Service for synchronizing offline content with online sources
class SyncService {
  static const Duration _syncCheckInterval = Duration(hours: 24);
  static const Duration _timeout = Duration(seconds: 30);

  final BibleService _bibleService;
  final OfflineBibleService _offlineBibleService;
  final ConnectionService _connectionService;

  Timer? _periodicSyncTimer;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;

  /// Stream controllers for sync updates
  final StreamController<SyncProgress> _syncController = StreamController<SyncProgress>.broadcast();

  /// Public streams
  Stream<SyncProgress> get syncStream => _syncController.stream;

  SyncService(
    this._bibleService,
    this._offlineBibleService,
    this._connectionService,
  ) {
    _startPeriodicSync();
  }

  /// Start periodic sync checks
  void _startPeriodicSync() {
    _periodicSyncTimer = Timer.periodic(_syncCheckInterval, (_) {
      _checkAndPerformSync();
    });
  }

  /// Check if sync should be performed and execute if needed
  Future<void> _checkAndPerformSync() async {
    if (!_connectionService.isOnline || !_connectionService.isSuitableForDownloads) {
      return;
    }

    try {
      final lastSync = await _getLastSyncTime();
      final shouldSync = lastSync == null ||
          DateTime.now().difference(lastSync) > _syncCheckInterval;

      if (shouldSync) {
        await performFullSync();
      }
    } catch (e) {
      AppLogger.error('Error during periodic sync check: $e');
    }
  }

  /// Perform a full sync of all offline content
  Future<SyncResult> performFullSync() async {
    if (_isSyncing) {
      AppLogger.info('Sync already in progress, skipping');
      return SyncResult.skipped;
    }

    if (!_connectionService.isOnline) {
      AppLogger.info('No internet connection, cannot sync');
      return SyncResult.failed;
    }

    _isSyncing = true;
    SyncProgress progress = const SyncProgress(
      phase: SyncPhase.starting,
      currentItem: '',
      progress: 0.0,
    );

    try {
      AppLogger.info('Starting full sync...');
      _syncController.add(progress.copyWith(phase: SyncPhase.checking));

      // Get all offline content
      final offlineContent = await _offlineBibleService.getOfflineContent();
      if (offlineContent.isEmpty) {
        _isSyncing = false;
        _lastSyncTime = DateTime.now();
        await _saveLastSyncTime(_lastSyncTime!);
        return SyncResult.success;
      }

      progress = progress.copyWith(
        phase: SyncPhase.syncing,
        totalItems: offlineContent.length,
      );
      _syncController.add(progress);

      int syncedItems = 0;
      int failedItems = 0;
      final updatedContent = <OfflineContent>[];

      // Sync each piece of content
      for (final content in offlineContent) {
        progress = progress.copyWith(
          currentItem: content.bookName,
          currentIndex: syncedItems + failedItems,
        );
        _syncController.add(progress);

        try {
          if (content.chapter != null) {
            // Sync specific chapter
            await _syncChapter(content.bookId, content.chapter!);
          } else {
            // Sync entire book
            await _syncBook(content.bookId);
          }

          updatedContent.add(content.copyWith(
            lastAccessedAt: DateTime.now(),
          ));
          syncedItems++;
        } catch (e) {
          AppLogger.warning('Failed to sync ${content.bookName}: $e');
          failedItems++;
        }

        // Small delay to avoid overwhelming the server
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Update offline content metadata
      for (final content in updatedContent) {
        await _offlineBibleService.updateOfflineContent(content);
      }

      _lastSyncTime = DateTime.now();
      await _saveLastSyncTime(_lastSyncTime!);

      progress = progress.copyWith(
        phase: SyncPhase.completed,
        progress: 100.0,
        syncedItems: syncedItems,
        failedItems: failedItems,
      );
      _syncController.add(progress);

      AppLogger.info('Sync completed: $syncedItems synced, $failedItems failed');

      return failedItems == 0 ? SyncResult.success : SyncResult.partial;

    } catch (e) {
      AppLogger.error('Sync failed: $e');

      progress = progress.copyWith(
        phase: SyncPhase.error,
        error: e.toString(),
      );
      _syncController.add(progress);

      return SyncResult.failed;
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync a specific book
  Future<void> _syncBook(String bookId) async {
    try {
      // Get fresh chapters from online
      final chapters = await _bibleService.getChapters(bookId);

      // Get current offline content
      final offlineContent = await _offlineBibleService.getOfflineContentForBook(bookId);
      if (offlineContent == null) return;

      // Download all chapters for the book
      final allVerses = <BibleVerse>[];
      int totalVerses = 0;

      for (final chapter in chapters) {
        try {
          final verses = await _bibleService.getVerses(bookId, chapter.chapter);
          allVerses.addAll(verses);
          totalVerses += verses.length;
        } catch (e) {
          AppLogger.warning('Failed to sync chapter ${chapter.chapter}: $e');
        }
      }

      if (allVerses.isNotEmpty) {
        // Get book info for storage
        final books = await _bibleService.getBooks();
        final book = books.firstWhere((b) => b.id == bookId);

        // Store updated verses
        await _offlineBibleService.storeVerses(allVerses, book);

        AppLogger.info('Synced book $bookId with $totalVerses verses');
      }
    } catch (e) {
      AppLogger.error('Error syncing book $bookId: $e');
      rethrow;
    }
  }

  /// Sync a specific chapter
  Future<void> _syncChapter(String bookId, int chapter) async {
    try {
      // Get fresh verses from online
      final verses = await _bibleService.getVerses(bookId, chapter);

      if (verses.isNotEmpty) {
        // Get book info for storage
        final books = await _bibleService.getBooks();
        final book = books.firstWhere((b) => b.id == bookId);

        // Store updated verses
        await _offlineBibleService.storeVerses(verses, book);

        AppLogger.info('Synced chapter $bookId:$chapter with ${verses.length} verses');
      }
    } catch (e) {
      AppLogger.error('Error syncing chapter $bookId:$chapter: $e');
      rethrow;
    }
  }

  /// Sync specific offline content
  Future<bool> syncOfflineContent(String contentId) async {
    if (!_connectionService.isOnline) {
      return false;
    }

    try {
      final content = await _offlineBibleService.getOfflineContentForBook(
        contentId.replaceAll('book_', '').replaceAll('chapter_', '').split('_').first,
      );

      if (content == null) return false;

      if (content.chapter != null) {
        await _syncChapter(content.bookId, content.chapter!);
      } else {
        await _syncBook(content.bookId);
      }

      return true;
    } catch (e) {
      AppLogger.error('Error syncing content $contentId: $e');
      return false;
    }
  }

  /// Check for updates to offline content
  Future<List<OfflineContent>> checkForUpdates() async {
    if (!_connectionService.isOnline) {
      return [];
    }

    try {
      final offlineContent = await _offlineBibleService.getOfflineContent();
      final updatesAvailable = <OfflineContent>[];

      for (final content in offlineContent) {
        // Simple check: if content is older than 7 days, suggest update
        final daysSinceUpdate = DateTime.now().difference(
          content.lastAccessedAt ?? content.downloadedAt,
        ).inDays;

        if (daysSinceUpdate > 7) {
          updatesAvailable.add(content);
        }
      }

      return updatesAvailable;
    } catch (e) {
      AppLogger.error('Error checking for updates: $e');
      return [];
    }
  }

  /// Get sync status
  Future<SyncStatus> getSyncStatus() async {
    try {
      final lastSync = await _getLastSyncTime();
      final offlineContent = await _offlineBibleService.getOfflineContent();
      final updatesAvailable = await checkForUpdates();

      return SyncStatus(
        lastSyncTime: lastSync,
        hasOfflineContent: offlineContent.isNotEmpty,
        updatesAvailable: updatesAvailable.isNotEmpty,
        updateCount: updatesAvailable.length,
        isOnline: _connectionService.isOnline,
      );
    } catch (e) {
      AppLogger.error('Error getting sync status: $e');
      return const SyncStatus(
        lastSyncTime: null,
        isOnline: false,
        hasOfflineContent: false,
        updatesAvailable: false,
        updateCount: 0,
      );
    }
  }

  /// Force refresh of specific content
  Future<void> refreshContent(String bookId, {int? chapter}) async {
    if (!_connectionService.isOnline) {
      throw Exception('Geen internetverbinding beschikbaar');
    }

    try {
      if (chapter != null) {
        await _syncChapter(bookId, chapter);
      } else {
        await _syncBook(bookId);
      }

      AppLogger.info('Content refreshed: $bookId${chapter != null ? ':$chapter' : ''}');
    } catch (e) {
      AppLogger.error('Error refreshing content: $e');
      rethrow;
    }
  }

  /// Get last sync time from storage
  Future<DateTime?> _getLastSyncTime() async {
    try {
      // In a real implementation, this would be stored in SharedPreferences
      return _lastSyncTime;
    } catch (e) {
      return null;
    }
  }

  /// Save last sync time to storage
  Future<void> _saveLastSyncTime(DateTime time) async {
    try {
      // In a real implementation, this would be stored in SharedPreferences
      _lastSyncTime = time;
    } catch (e) {
      AppLogger.error('Error saving last sync time: $e');
    }
  }

  /// Enable or disable automatic sync
  void setAutoSyncEnabled(bool enabled) {
    if (enabled) {
      _startPeriodicSync();
    } else {
      _periodicSyncTimer?.cancel();
      _periodicSyncTimer = null;
    }
    AppLogger.info('Auto sync ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Check if currently syncing
  bool get isSyncing => _isSyncing;

  /// Get last sync time
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Dispose of the service
  void dispose() {
    AppLogger.info('Disposing sync service...');
    _periodicSyncTimer?.cancel();
    _syncController.close();
    AppLogger.info('Sync service disposed');
  }
}

/// Sync progress model
class SyncProgress {
  final SyncPhase phase;
  final String currentItem;
  final double progress;
  final int totalItems;
  final int currentIndex;
  final int syncedItems;
  final int failedItems;
  final String? error;

  const SyncProgress({
    required this.phase,
    required this.currentItem,
    required this.progress,
    this.totalItems = 0,
    this.currentIndex = 0,
    this.syncedItems = 0,
    this.failedItems = 0,
    this.error,
  });

  SyncProgress copyWith({
    SyncPhase? phase,
    String? currentItem,
    double? progress,
    int? totalItems,
    int? currentIndex,
    int? syncedItems,
    int? failedItems,
    String? error,
  }) {
    return SyncProgress(
      phase: phase ?? this.phase,
      currentItem: currentItem ?? this.currentItem,
      progress: progress ?? this.progress,
      totalItems: totalItems ?? this.totalItems,
      currentIndex: currentIndex ?? this.currentIndex,
      syncedItems: syncedItems ?? this.syncedItems,
      failedItems: failedItems ?? this.failedItems,
      error: error ?? this.error,
    );
  }

  @override
  String toString() =>
    'SyncProgress(phase: $phase, item: $currentItem, progress: ${progress.toStringAsFixed(1)}%)';
}

/// Sync phase enumeration
enum SyncPhase {
  starting,
  checking,
  syncing,
  completed,
  error,
}

/// Sync result enumeration
enum SyncResult {
  success,
  partial,
  failed,
  skipped,
}

/// Sync status model
class SyncStatus {
  final DateTime? lastSyncTime;
  final bool hasOfflineContent;
  final bool updatesAvailable;
  final int updateCount;
  final bool isOnline;

  const SyncStatus({
    required this.lastSyncTime,
    required this.hasOfflineContent,
    required this.updatesAvailable,
    required this.updateCount,
    required this.isOnline,
  });

  /// Get localized status description
  String getStatusDescription() {
    if (!isOnline) {
      return 'Offline - synchronisatie niet beschikbaar';
    }

    if (!hasOfflineContent) {
      return 'Geen offline inhoud om te synchroniseren';
    }

    if (updatesAvailable) {
      return 'Updates beschikbaar ($updateCount items)';
    }

    if (lastSyncTime != null) {
      final daysSinceSync = DateTime.now().difference(lastSyncTime!).inDays;
      return 'Laatste sync: $daysSinceSync dagen geleden';
    }

    return 'Klaar voor synchronisatie';
  }

  @override
  String toString() =>
    'SyncStatus(online: $isOnline, hasContent: $hasOfflineContent, updates: $updatesAvailable)';
}