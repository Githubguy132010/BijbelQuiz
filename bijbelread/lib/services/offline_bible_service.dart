import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'logger.dart';
import '../models/database_verse.dart';
import '../models/offline_content.dart';
import '../models/download_task.dart';
import '../models/bible_book.dart';
import '../models/bible_verse.dart';

/// Service for managing offline Bible content using SQLite
class OfflineBibleService {
  static const String _databaseName = 'bijbelread_offline.db';
  static const int _databaseVersion = 1;

  Database? _database;
  bool _isInitialized = false;

  /// Stream controllers for real-time updates
  final StreamController<OfflineContent> _contentController = StreamController<OfflineContent>.broadcast();
  final StreamController<DownloadTask> _downloadController = StreamController<DownloadTask>.broadcast();
  final StreamController<String> _progressController = StreamController<String>.broadcast();

  /// Public streams
  Stream<OfflineContent> get contentStream => _contentController.stream;
  Stream<DownloadTask> get downloadStream => _downloadController.stream;
  Stream<String> get progressStream => _progressController.stream;

  /// Initialize the database
  Future<void> initialize() async {
    if (_isInitialized) return;

    AppLogger.info('Initializing offline Bible service...');

    try {
      // Log platform information for debugging
      AppLogger.info('Platform: ${Platform.operatingSystem}');
      AppLogger.info('Platform is Linux: ${Platform.isLinux}');
      AppLogger.info('Platform is Windows: ${Platform.isWindows}');
      AppLogger.info('Platform is macOS: ${Platform.isMacOS}');
      AppLogger.info('Platform is Android: ${Platform.isAndroid}');
      AppLogger.info('Platform is iOS: ${Platform.isIOS}');

      // Check if sqflite_common_ffi is available
      try {
        // This will help us understand if the FFI factory is available
        AppLogger.info('Checking sqflite_common_ffi availability...');
        // We'll add the import and initialization in the fix
      } catch (ffiError) {
        AppLogger.warning('sqflite_common_ffi check failed: $ffiError');
      }

      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, _databaseName);

      AppLogger.info('Database path: $path');
      AppLogger.info('Attempting to open database...');

      _database = await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );

      AppLogger.info('Database opened successfully');
      _isInitialized = true;
      AppLogger.info('Offline Bible service initialized successfully');
    } catch (e) {
      AppLogger.error('Failed to initialize offline Bible service: $e');
      AppLogger.error('Error type: ${e.runtimeType}');
      AppLogger.error('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    AppLogger.info('Creating database schema...');

    // Verses table
    await db.execute('''
      CREATE TABLE verses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bookId TEXT NOT NULL,
        chapter INTEGER NOT NULL,
        verse INTEGER NOT NULL,
        text TEXT NOT NULL,
        testament TEXT NOT NULL,
        bookName TEXT NOT NULL,
        downloadedAt TEXT NOT NULL,
        lastAccessedAt TEXT,
        accessCount INTEGER DEFAULT 0,
        UNIQUE(bookId, chapter, verse)
      )
    ''');

    // Offline content table
    await db.execute('''
      CREATE TABLE offline_content (
        id TEXT PRIMARY KEY,
        bookId TEXT NOT NULL,
        bookName TEXT NOT NULL,
        testament TEXT NOT NULL,
        chapter INTEGER,
        verseCount INTEGER,
        downloadedVerses INTEGER NOT NULL,
        totalVerses INTEGER NOT NULL,
        downloadedAt TEXT NOT NULL,
        lastAccessedAt TEXT,
        fileSize REAL NOT NULL,
        isComplete INTEGER NOT NULL,
        status INTEGER NOT NULL
      )
    ''');

    // Download tasks table
    await db.execute('''
      CREATE TABLE download_tasks (
        id TEXT PRIMARY KEY,
        type INTEGER NOT NULL,
        bookId TEXT NOT NULL,
        bookName TEXT NOT NULL,
        testament TEXT NOT NULL,
        chapter INTEGER,
        startVerse INTEGER,
        endVerse INTEGER,
        status INTEGER NOT NULL,
        progress REAL NOT NULL,
        downloadedItems INTEGER NOT NULL,
        totalItems INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        startedAt TEXT,
        completedAt TEXT,
        error TEXT,
        retryCount INTEGER DEFAULT 0,
        isBackground INTEGER DEFAULT 0
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_verses_book_chapter ON verses(bookId, chapter)');
    await db.execute('CREATE INDEX idx_verses_testament ON verses(testament)');
    await db.execute('CREATE INDEX idx_verses_last_accessed ON verses(lastAccessedAt)');
    await db.execute('CREATE INDEX idx_offline_content_book ON offline_content(bookId)');
    await db.execute('CREATE INDEX idx_download_tasks_status ON download_tasks(status)');

    AppLogger.info('Database schema created successfully');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    AppLogger.info('Upgrading database from version $oldVersion to $newVersion');
    // Handle future schema migrations here
  }

  /// Check if database is initialized
  bool get isInitialized => _isInitialized && _database != null;

  // Verse operations
  /// Store verses in the database
  Future<void> storeVerses(List<BibleVerse> verses, BibleBook book) async {
    if (!isInitialized) await initialize();

    try {
      final batch = _database!.batch();
      final timestamp = DateTime.now().toIso8601String();

      for (final verse in verses) {
        final databaseVerse = DatabaseVerse.fromBibleVerse(
          verse,
          testament: book.testament,
          bookName: book.name,
        );

        batch.insert(
          'verses',
          databaseVerse.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);
      AppLogger.info('Stored ${verses.length} verses for ${book.name}');
    } catch (e) {
      AppLogger.error('Error storing verses: $e');
      rethrow;
    }
  }

  /// Get verses for a specific chapter
  Future<List<BibleVerse>> getVerses(String bookId, int chapter) async {
    if (!isInitialized) await initialize();

    try {
      final List<Map<String, dynamic>> maps = await _database!.query(
        'verses',
        where: 'bookId = ? AND chapter = ?',
        whereArgs: [bookId, chapter],
        orderBy: 'verse ASC',
      );

      // Update access tracking
      await _updateVerseAccess(bookId, chapter);

      final verses = maps.map((map) {
        final dbVerse = DatabaseVerse.fromJson(map);
        return BibleVerse(
          bookId: dbVerse.bookId,
          chapter: dbVerse.chapter,
          verse: dbVerse.verse,
          text: dbVerse.text,
        );
      }).toList();

      AppLogger.info('Retrieved ${verses.length} verses for $bookId chapter $chapter');
      return verses;
    } catch (e) {
      AppLogger.error('Error retrieving verses: $e');
      rethrow;
    }
  }

  /// Search verses in offline database
  Future<List<DatabaseSearchResult>> searchVerses(String query, {int limit = 50}) async {
    if (!isInitialized) await initialize();

    try {
      // Simple text search (can be enhanced with FTS for better performance)
      final List<Map<String, dynamic>> maps = await _database!.query(
        'verses',
        where: 'text LIKE ?',
        whereArgs: ['%$query%'],
        orderBy: 'accessCount DESC, lastAccessedAt DESC',
        limit: limit,
      );

      final results = maps.map((map) {
        final verse = DatabaseVerse.fromJson(map);
        // Simple relevance scoring based on query position and access count
        final relevance = _calculateRelevance(verse.text, query, verse.accessCount);
        return DatabaseSearchResult(
          verse: verse,
          query: query,
          relevance: relevance,
        );
      }).toList();

      // Sort by relevance
      results.sort((a, b) => b.relevance.compareTo(a.relevance));

      AppLogger.info('Found ${results.length} search results for: $query');
      return results;
    } catch (e) {
      AppLogger.error('Error searching verses: $e');
      rethrow;
    }
  }

  /// Update verse access tracking
  Future<void> _updateVerseAccess(String bookId, int chapter) async {
    final timestamp = DateTime.now().toIso8601String();

    await _database!.update(
      'verses',
      {
        'lastAccessedAt': timestamp,
        'accessCount': 'accessCount + 1',
      },
      where: 'bookId = ? AND chapter = ?',
      whereArgs: [bookId, chapter],
    );
  }

  /// Calculate search relevance score
  double _calculateRelevance(String text, String query, int accessCount) {
    double score = 0.0;

    // Base score from access count (popular verses get higher score)
    score += accessCount * 0.1;

    // Boost score if query matches at word boundaries
    final queryLower = query.toLowerCase();
    final textLower = text.toLowerCase();

    if (textLower.contains(queryLower)) {
      score += 10.0;

      // Extra boost for exact word matches
      final words = textLower.split(RegExp(r'\s+'));
      if (words.any((word) => word == queryLower)) {
        score += 5.0;
      }
    }

    return score;
  }

  // Offline content management
  /// Add or update offline content record
  Future<void> addOfflineContent(OfflineContent content) async {
    if (!isInitialized) await initialize();

    try {
      await _database!.insert(
        'offline_content',
        content.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      _contentController.add(content);
      AppLogger.info('Added offline content: ${content.id}');
    } catch (e) {
      AppLogger.error('Error adding offline content: $e');
      rethrow;
    }
  }

  /// Get all offline content
  Future<List<OfflineContent>> getOfflineContent() async {
    if (!isInitialized) await initialize();

    try {
      final List<Map<String, dynamic>> maps = await _database!.query(
        'offline_content',
        orderBy: 'lastAccessedAt DESC, downloadedAt DESC',
      );

      final content = maps.map((map) => OfflineContent.fromJson(map)).toList();
      AppLogger.info('Retrieved ${content.length} offline content items');
      return content;
    } catch (e) {
      AppLogger.error('Error retrieving offline content: $e');
      rethrow;
    }
  }

  /// Get offline content for a specific book
  Future<OfflineContent?> getOfflineContentForBook(String bookId) async {
    if (!isInitialized) await initialize();

    try {
      final List<Map<String, dynamic>> maps = await _database!.query(
        'offline_content',
        where: 'bookId = ?',
        whereArgs: [bookId],
      );

      if (maps.isEmpty) return null;

      return OfflineContent.fromJson(maps.first);
    } catch (e) {
      AppLogger.error('Error retrieving offline content for book: $e');
      rethrow;
    }
  }

  /// Update offline content
  Future<void> updateOfflineContent(OfflineContent content) async {
    if (!isInitialized) await initialize();

    try {
      await _database!.update(
        'offline_content',
        content.toJson(),
        where: 'id = ?',
        whereArgs: [content.id],
      );

      _contentController.add(content);
      AppLogger.info('Updated offline content: ${content.id}');
    } catch (e) {
      AppLogger.error('Error updating offline content: $e');
      rethrow;
    }
  }

  /// Remove offline content
  Future<void> removeOfflineContent(String contentId) async {
    if (!isInitialized) await initialize();

    try {
      // Get content info before deletion for cascade delete
      final content = await _getOfflineContentById(contentId);
      if (content != null) {
        // Remove associated verses
        await _database!.delete(
          'verses',
          where: 'bookId = ?',
          whereArgs: [content.bookId],
        );

        // Remove the content record
        await _database!.delete(
          'offline_content',
          where: 'id = ?',
          whereArgs: [contentId],
        );

        _contentController.add(content.copyWith(
          status: DownloadStatus.failed, // Mark as removed
        ));

        AppLogger.info('Removed offline content: $contentId');
      }
    } catch (e) {
      AppLogger.error('Error removing offline content: $e');
      rethrow;
    }
  }

  /// Get offline content by ID
  Future<OfflineContent?> _getOfflineContentById(String id) async {
    final List<Map<String, dynamic>> maps = await _database!.query(
      'offline_content',
      where: 'id = ?',
      whereArgs: [id],
    );

    return maps.isNotEmpty ? OfflineContent.fromJson(maps.first) : null;
  }

  // Download task management
  /// Add download task
  Future<void> addDownloadTask(DownloadTask task) async {
    if (!isInitialized) await initialize();

    try {
      await _database!.insert(
        'download_tasks',
        task.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      _downloadController.add(task);
      AppLogger.info('Added download task: ${task.id}');
    } catch (e) {
      AppLogger.error('Error adding download task: $e');
      rethrow;
    }
  }

  /// Update download task
  Future<void> updateDownloadTask(DownloadTask task) async {
    if (!isInitialized) await initialize();

    try {
      await _database!.update(
        'download_tasks',
        task.toJson(),
        where: 'id = ?',
        whereArgs: [task.id],
      );

      _downloadController.add(task);
      AppLogger.info('Updated download task: ${task.id}');
    } catch (e) {
      AppLogger.error('Error updating download task: $e');
      rethrow;
    }
  }

  /// Get all download tasks
  Future<List<DownloadTask>> getDownloadTasks() async {
    if (!isInitialized) await initialize();

    try {
      final List<Map<String, dynamic>> maps = await _database!.query(
        'download_tasks',
        orderBy: 'createdAt DESC',
      );

      return maps.map((map) => DownloadTask.fromJson(map)).toList();
    } catch (e) {
      AppLogger.error('Error retrieving download tasks: $e');
      rethrow;
    }
  }

  /// Get active download tasks
  Future<List<DownloadTask>> getActiveDownloadTasks() async {
    if (!isInitialized) await initialize();

    try {
      final List<Map<String, dynamic>> maps = await _database!.query(
        'download_tasks',
        where: 'status IN (?, ?)',
        whereArgs: [DownloadStatus.pending.index, DownloadStatus.downloading.index],
        orderBy: 'createdAt ASC',
      );

      return maps.map((map) => DownloadTask.fromJson(map)).toList();
    } catch (e) {
      AppLogger.error('Error retrieving active download tasks: $e');
      rethrow;
    }
  }

  /// Remove download task
  Future<void> removeDownloadTask(String taskId) async {
    if (!isInitialized) await initialize();

    try {
      await _database!.delete(
        'download_tasks',
        where: 'id = ?',
        whereArgs: [taskId],
      );

      AppLogger.info('Removed download task: $taskId');
    } catch (e) {
      AppLogger.error('Error removing download task: $e');
      rethrow;
    }
  }

  // Database maintenance
  /// Get database statistics
  Future<DatabaseStats> getDatabaseStats() async {
    if (!isInitialized) await initialize();

    try {
      // Get total counts
      final verseCount = Sqflite.firstIntValue(
        await _database!.rawQuery('SELECT COUNT(*) FROM verses'),
      ) ?? 0;

      final bookCount = Sqflite.firstIntValue(
        await _database!.rawQuery('SELECT COUNT(DISTINCT bookId) FROM verses'),
      ) ?? 0;

      final chapterCount = Sqflite.firstIntValue(
        await _database!.rawQuery('SELECT COUNT(DISTINCT bookId || "_" || chapter) FROM verses'),
      ) ?? 0;

      // Get size (rough estimate)
      final dbPath = await _getDatabasePath();
      final file = File(dbPath);
      final sizeInBytes = await file.length();
      final sizeInMB = sizeInBytes / (1024 * 1024);

      // Get verses by testament
      final testamentMaps = await _database!.rawQuery(
        'SELECT testament, COUNT(*) as count FROM verses GROUP BY testament',
      );
      final versesByTestament = <String, int>{};
      for (final map in testamentMaps) {
        versesByTestament[map['testament'] as String] = map['count'] as int;
      }

      // Get verses by book
      final bookMaps = await _database!.rawQuery(
        'SELECT bookId, COUNT(*) as count FROM verses GROUP BY bookId ORDER BY count DESC',
      );
      final versesByBook = <String, int>{};
      for (final map in bookMaps) {
        versesByBook[map['bookId'] as String] = map['count'] as int;
      }

      return DatabaseStats(
        totalVerses: verseCount,
        totalBooks: bookCount,
        totalChapters: chapterCount,
        totalSize: sizeInMB,
        lastUpdated: DateTime.now(),
        versesByTestament: versesByTestament,
        versesByBook: versesByBook,
      );
    } catch (e) {
      AppLogger.error('Error getting database stats: $e');
      rethrow;
    }
  }

  /// Clean up old data (LRU cache-like behavior)
  Future<void> cleanupOldData({int maxAgeDays = 30, int maxAccessCount = 1000}) async {
    if (!isInitialized) await initialize();

    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: maxAgeDays));

      // Remove old, rarely accessed verses
      final deletedVerses = await _database!.delete(
        'verses',
        where: 'lastAccessedAt < ? AND accessCount < ?',
        whereArgs: [cutoffDate.toIso8601String(), maxAccessCount],
      );

      AppLogger.info('Cleaned up $deletedVerses old verses');
    } catch (e) {
      AppLogger.error('Error cleaning up old data: $e');
      rethrow;
    }
  }

  /// Clear all data
  Future<void> clearAllData() async {
    if (!isInitialized) await initialize();

    try {
      await _database!.delete('verses');
      await _database!.delete('offline_content');
      await _database!.delete('download_tasks');

      AppLogger.info('Cleared all offline data');
    } catch (e) {
      AppLogger.error('Error clearing all data: $e');
      rethrow;
    }
  }

  /// Get database path for debugging
  Future<String> _getDatabasePath() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    return join(documentsDirectory.path, _databaseName);
  }

  /// Close database connection
  Future<void> dispose() async {
    AppLogger.info('Disposing offline Bible service...');

    await _contentController.close();
    await _downloadController.close();
    await _progressController.close();

    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    _isInitialized = false;
    AppLogger.info('Offline Bible service disposed');
  }
}