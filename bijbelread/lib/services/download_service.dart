import 'dart:async';
import 'package:http/http.dart' as http;

import 'logger.dart';
import 'bible_service.dart';
import 'offline_bible_service.dart';
import 'connection_service.dart';
import '../models/bible_book.dart';
import '../models/bible_chapter.dart';
import '../models/bible_verse.dart';
import '../models/download_task.dart';
import '../models/offline_content.dart';

/// Service for managing Bible content downloads
class DownloadService {
  static const String _baseUrl = 'https://www.online-bijbel.nl/api.php';
  static const Duration _timeout = Duration(seconds: 15);
  static const int _maxConcurrentDownloads = 3;
  static const int _maxRetries = 3;

  final BibleService _bibleService;
  final OfflineBibleService _offlineBibleService;
  final ConnectionService _connectionService;

  final http.Client _client = http.Client();

  Timer? _queueTimer;
  bool _isProcessingQueue = false;
  int _activeDownloads = 0;

  /// Stream controllers for real-time updates
  final StreamController<DownloadTask> _taskController =
      StreamController<DownloadTask>.broadcast();
  final StreamController<String> _progressController =
      StreamController<String>.broadcast();

  /// Public streams
  Stream<DownloadTask> get taskStream => _taskController.stream;
  Stream<String> get progressStream => _progressController.stream;

  DownloadService(
    this._bibleService,
    this._offlineBibleService,
    this._connectionService,
  ) {
    _startQueueProcessor();
  }

  /// Start the download queue processor
  void _startQueueProcessor() {
    _queueTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _processDownloadQueue();
    });
  }

  /// Process the download queue
  Future<void> _processDownloadQueue() async {
    if (_isProcessingQueue || _activeDownloads >= _maxConcurrentDownloads) {
      return;
    }

    if (!_connectionService.isOnline ||
        !_connectionService.isSuitableForDownloads) {
      return;
    }

    try {
      _isProcessingQueue = true;
      final activeTasks = await _offlineBibleService.getActiveDownloadTasks();

      for (final task in activeTasks) {
        if (_activeDownloads >= _maxConcurrentDownloads) break;

        if (task.status == DownloadStatus.pending) {
          _startDownload(task);
        }
      }
    } catch (e) {
      AppLogger.error('Error processing download queue: $e');
    } finally {
      _isProcessingQueue = false;
    }
  }

  /// Start downloading a task
  Future<void> _startDownload(DownloadTask task) async {
    if (_activeDownloads >= _maxConcurrentDownloads) return;

    _activeDownloads++;
    await _updateTaskStatus(task.id, DownloadStatus.downloading, 0.0, 0);

    try {
      AppLogger.info('Starting download: ${task.description}');

      switch (task.type) {
        case DownloadType.book:
          await _downloadBook(task);
          break;
        case DownloadType.chapter:
          await _downloadChapter(task);
          break;
        case DownloadType.verses:
          await _downloadVerses(task);
          break;
      }
    } catch (e) {
      AppLogger.error('Download failed for task ${task.id}: $e');
      await _handleDownloadError(task, e.toString());
    } finally {
      _activeDownloads--;
    }
  }

  /// Download a complete book
  Future<void> _downloadBook(DownloadTask task) async {
    try {
      // Get all chapters for the book
      final chapters = await _bibleService.getChapters(task.bookId);

      int totalVerses = 0;
      int downloadedVerses = 0;
      final allVerses = <BibleVerse>[];

      // Download all chapters
      for (final chapter in chapters) {
        try {
          final verses =
              await _bibleService.getVerses(task.bookId, chapter.chapter);
          allVerses.addAll(verses);
          totalVerses += verses.length;

          // Update progress
          downloadedVerses += verses.length;
          final progress =
              totalVerses > 0 ? (downloadedVerses / totalVerses) * 100 : 0.0;
          await _updateTaskProgress(task.id, progress, downloadedVerses);

          // Store verses in batches to avoid memory issues
          if (allVerses.length >= 100) {
            await _offlineBibleService.storeVerses(
                allVerses, await _getBookById(task.bookId));
            allVerses.clear();
          }
        } catch (e) {
          AppLogger.warning(
              'Failed to download chapter ${chapter.chapter}: $e');
          // Continue with other chapters
        }
      }

      // Store remaining verses
      if (allVerses.isNotEmpty) {
        await _offlineBibleService.storeVerses(
            allVerses, await _getBookById(task.bookId));
      }

      // Create offline content record
      final book = await _getBookById(task.bookId);
      final fileSize = _estimateFileSize(totalVerses);

      final offlineContent = OfflineContent.book(
        book: book,
        downloadedVerses: downloadedVerses,
        totalVerses: totalVerses,
        downloadedAt: DateTime.now(),
        fileSize: fileSize,
        status: DownloadStatus.completed,
      );

      await _offlineBibleService.addOfflineContent(offlineContent);
      await _updateTaskStatus(
          task.id, DownloadStatus.completed, 100.0, totalVerses);

      AppLogger.info(
          'Successfully downloaded book: ${task.bookName} ($downloadedVerses verses)');
    } catch (e) {
      AppLogger.error('Error downloading book ${task.bookId}: $e');
      rethrow;
    }
  }

  /// Download a specific chapter
  Future<void> _downloadChapter(DownloadTask task) async {
    if (task.chapter == null) return;

    try {
      final verses = await _bibleService.getVerses(task.bookId, task.chapter!);

      // Store verses in database
      final book = await _getBookById(task.bookId);
      await _offlineBibleService.storeVerses(verses, book);

      // Create offline content record
      final fileSize = _estimateFileSize(verses.length);

      final offlineContent = OfflineContent.chapter(
        book: book,
        chapter: await _getChapterById(task.bookId, task.chapter!),
        downloadedVerses: verses.length,
        downloadedAt: DateTime.now(),
        fileSize: fileSize,
        status: DownloadStatus.completed,
      );

      await _offlineBibleService.addOfflineContent(offlineContent);
      await _updateTaskStatus(
          task.id, DownloadStatus.completed, 100.0, verses.length);

      AppLogger.info(
          'Successfully downloaded chapter: ${task.bookName} ${task.chapter}');
    } catch (e) {
      AppLogger.error(
          'Error downloading chapter ${task.bookId}:${task.chapter}: $e');
      rethrow;
    }
  }

  /// Download specific verses
  Future<void> _downloadVerses(DownloadTask task) async {
    if (task.chapter == null ||
        task.startVerse == null ||
        task.endVerse == null) {
      return;
    }

    try {
      final verses = await _bibleService.getVerses(task.bookId, task.chapter!);

      // Filter verses based on range
      final filteredVerses = verses.where((verse) {
        return verse.verse >= task.startVerse! && verse.verse <= task.endVerse!;
      }).toList();

      // Store verses in database
      final book = await _getBookById(task.bookId);
      await _offlineBibleService.storeVerses(filteredVerses, book);

      await _updateTaskStatus(
          task.id, DownloadStatus.completed, 100.0, filteredVerses.length);

      AppLogger.info(
          'Successfully downloaded verses: ${task.bookName} ${task.chapter}:${task.startVerse}-${task.endVerse}');
    } catch (e) {
      AppLogger.error(
          'Error downloading verses ${task.bookId}:${task.chapter}:${task.startVerse}-${task.endVerse}: $e');
      rethrow;
    }
  }

  /// Handle download error with retry logic
  Future<void> _handleDownloadError(DownloadTask task, String error) async {
    final updatedTask = task.copyWith(
      retryCount: task.retryCount + 1,
      error: error,
    );

    if (updatedTask.canRetry) {
      await _updateTaskStatus(task.id, DownloadStatus.pending, 0.0, 0);
      AppLogger.info(
          'Retrying download task ${task.id} (attempt ${updatedTask.retryCount})');
    } else {
      await _updateTaskStatus(task.id, DownloadStatus.failed, 0.0, 0,
          error: error);
      AppLogger.error(
          'Download task ${task.id} failed after ${updatedTask.retryCount} attempts');
    }
  }

  /// Update task status
  Future<void> _updateTaskStatus(
    String taskId,
    DownloadStatus status,
    double progress,
    int downloadedItems, {
    String? error,
  }) async {
    try {
      final task = await _getTaskById(taskId);
      if (task == null) return;

      final now = DateTime.now();
      final updatedTask = task.copyWith(
        status: status,
        progress: progress,
        downloadedItems: downloadedItems,
        startedAt:
            status == DownloadStatus.downloading && task.startedAt == null
                ? now
                : task.startedAt,
        completedAt:
            status == DownloadStatus.completed ? now : task.completedAt,
        error: error,
      );

      await _offlineBibleService.updateDownloadTask(updatedTask);
      _taskController.add(updatedTask);

      _progressController.add(
        'Download update: ${updatedTask.description} - ${progress.toStringAsFixed(1)}%',
      );
    } catch (e) {
      AppLogger.error('Error updating task status: $e');
    }
  }

  /// Update task progress
  Future<void> _updateTaskProgress(
      String taskId, double progress, int downloadedItems) async {
    await _updateTaskStatus(
        taskId, DownloadStatus.downloading, progress, downloadedItems);
  }

  /// Get book by ID
  Future<BibleBook> _getBookById(String bookId) async {
    final books = await _bibleService.getBooks();
    return books.firstWhere((book) => book.id == bookId);
  }

  /// Get chapter by ID
  Future<BibleChapter> _getChapterById(String bookId, int chapter) async {
    final chapters = await _bibleService.getChapters(bookId);
    return chapters.firstWhere((chap) => chap.chapter == chapter);
  }

  /// Get task by ID
  Future<DownloadTask?> _getTaskById(String taskId) async {
    final tasks = await _offlineBibleService.getDownloadTasks();
    try {
      return tasks.firstWhere((task) => task.id == taskId);
    } catch (e) {
      return null;
    }
  }

  /// Estimate file size based on verse count
  double _estimateFileSize(int verseCount) {
    // Rough estimate: ~200 bytes per verse (including metadata)
    return (verseCount * 200) / (1024 * 1024); // Convert to MB
  }

  // Public API methods
  /// Queue a book for download
  Future<DownloadTask> queueBookDownload(BibleBook book,
      {bool isBackground = false}) async {
    final totalVerses = await _estimateBookVerseCount(book.id);
    final task = DownloadTask.book(
      book: book,
      totalVerses: totalVerses,
      isBackground: isBackground,
    );

    await _offlineBibleService.addDownloadTask(task);
    AppLogger.info('Queued book download: ${book.name}');
    return task;
  }

  /// Queue a chapter for download
  Future<DownloadTask> queueChapterDownload(
      BibleBook book, BibleChapter chapter) async {
    final task = DownloadTask.chapter(
      book: book,
      chapter: chapter,
    );

    await _offlineBibleService.addDownloadTask(task);
    AppLogger.info('Queued chapter download: ${book.name} ${chapter.chapter}');
    return task;
  }

  /// Queue verses for download
  Future<DownloadTask> queueVersesDownload(
    BibleBook book,
    int chapter,
    int startVerse,
    int endVerse,
  ) async {
    final task = DownloadTask.chapter(
      book: book,
      chapter: await _getChapterById(book.id, chapter),
      startVerse: startVerse,
      endVerse: endVerse,
    );

    await _offlineBibleService.addDownloadTask(task);
    AppLogger.info(
        'Queued verses download: ${book.name} $chapter:$startVerse-$endVerse');
    return task;
  }

  /// Pause a download task
  Future<void> pauseDownload(String taskId) async {
    await _updateTaskStatus(taskId, DownloadStatus.paused, 0.0, 0);
    AppLogger.info('Paused download task: $taskId');
  }

  /// Resume a download task
  Future<void> resumeDownload(String taskId) async {
    await _updateTaskStatus(taskId, DownloadStatus.pending, 0.0, 0);
    AppLogger.info('Resumed download task: $taskId');
  }

  /// Cancel a download task
  Future<void> cancelDownload(String taskId) async {
    await _updateTaskStatus(taskId, DownloadStatus.failed, 0.0, 0,
        error: 'Cancelled by user');
    await _offlineBibleService.removeDownloadTask(taskId);
    AppLogger.info('Cancelled download task: $taskId');
  }

  /// Retry a failed download task
  Future<void> retryDownload(String taskId) async {
    final task = await _getTaskById(taskId);
    if (task != null && task.canRetry) {
      final resetTask = task.copyWith(
        status: DownloadStatus.pending,
        progress: 0.0,
        downloadedItems: 0,
        error: null,
        retryCount: 0,
      );

      await _offlineBibleService.updateDownloadTask(resetTask);
      AppLogger.info('Retrying download task: $taskId');
    }
  }

  /// Get all download tasks
  Future<List<DownloadTask>> getDownloadTasks() async {
    return await _offlineBibleService.getDownloadTasks();
  }

  /// Get active download tasks
  Future<List<DownloadTask>> getActiveDownloadTasks() async {
    return await _offlineBibleService.getActiveDownloadTasks();
  }

  /// Get download progress for a task
  Future<double> getDownloadProgress(String taskId) async {
    final task = await _getTaskById(taskId);
    return task?.progress ?? 0.0;
  }

  /// Check if a book/chapter is already downloaded
  Future<bool> isContentDownloaded(String bookId, {int? chapter}) async {
    final content = await _offlineBibleService.getOfflineContentForBook(bookId);
    if (content == null) return false;

    if (chapter == null) {
      // Check if entire book is downloaded
      return content.isComplete;
    } else {
      // Check if specific chapter is downloaded
      return content.chapter == chapter && content.isComplete;
    }
  }

  /// Estimate total verse count for a book
  Future<int> _estimateBookVerseCount(String bookId) async {
    try {
      final chapters = await _bibleService.getChapters(bookId);
      return chapters.fold<int>(0, (sum, chapter) => sum + chapter.verseCount);
    } catch (e) {
      AppLogger.warning('Could not estimate verse count for book $bookId: $e');
      return 0;
    }
  }

  /// Get download statistics
  Future<DownloadStats> getDownloadStats() async {
    final tasks = await getDownloadTasks();
    final activeTasks = tasks.where((task) => task.isActive).length;
    final completedTasks = tasks.where((task) => task.isCompleted).length;
    final failedTasks = tasks.where((task) => task.hasFailed).length;

    return DownloadStats(
      totalTasks: tasks.length,
      activeTasks: activeTasks,
      completedTasks: completedTasks,
      failedTasks: failedTasks,
      isProcessing: _isProcessingQueue,
      activeDownloads: _activeDownloads,
    );
  }

  /// Clear completed download tasks (older than specified days)
  Future<void> clearCompletedTasks({int olderThanDays = 7}) async {
    try {
      final tasks = await getDownloadTasks();
      final cutoffDate = DateTime.now().subtract(Duration(days: olderThanDays));

      for (final task in tasks) {
        if (task.isCompleted &&
            task.completedAt != null &&
            task.completedAt!.isBefore(cutoffDate)) {
          await _offlineBibleService.removeDownloadTask(task.id);
        }
      }

      AppLogger.info('Cleared old completed download tasks');
    } catch (e) {
      AppLogger.error('Error clearing completed tasks: $e');
    }
  }

  /// Dispose of the service
  void dispose() {
    AppLogger.info('Disposing download service...');
    _queueTimer?.cancel();
    _client.close();
    _taskController.close();
    _progressController.close();
    AppLogger.info('Download service disposed');
  }
}

/// Model for download statistics
class DownloadStats {
  final int totalTasks;
  final int activeTasks;
  final int completedTasks;
  final int failedTasks;
  final bool isProcessing;
  final int activeDownloads;

  const DownloadStats({
    required this.totalTasks,
    required this.activeTasks,
    required this.completedTasks,
    required this.failedTasks,
    required this.isProcessing,
    required this.activeDownloads,
  });

  /// Get success rate as percentage
  double get successRate {
    if (totalTasks == 0) return 0.0;
    return (completedTasks / totalTasks) * 100;
  }

  @override
  String toString() =>
      'DownloadStats(total: $totalTasks, active: $activeTasks, completed: $completedTasks, success: ${successRate.toStringAsFixed(1)}%)';
}
