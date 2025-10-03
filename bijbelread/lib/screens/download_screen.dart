import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../models/bible_book.dart';
import '../models/download_task.dart';
import '../models/offline_content.dart';
import '../models/database_verse.dart';
import '../services/download_service.dart';
import '../services/offline_bible_service.dart';
import '../services/bible_service.dart';
import '../services/connection_service.dart';
import '../services/logger.dart';
import '../l10n/strings_nl.dart';

/// Screen for managing offline Bible content and downloads
class DownloadScreen extends StatefulWidget {
  const DownloadScreen({super.key});

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // Services
  late BibleService _bibleService;
  late OfflineBibleService _offlineBibleService;
  late DownloadService _downloadService;
  late ConnectionService _connectionService;

  // State
  List<BibleBook> _books = [];
  List<OfflineContent> _offlineContent = [];
  List<DownloadTask> _downloadTasks = [];
  bool _isLoading = true;
  String? _error;

  // Stream subscriptions
  StreamSubscription? _contentSubscription;
  StreamSubscription? _taskSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _initializeServices();
    _loadData();
    _setupStreams();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _contentSubscription?.cancel();
    _taskSubscription?.cancel();
    super.dispose();
  }

  /// Initialize services from providers
  void _initializeServices() {
    _bibleService = Provider.of<BibleService>(context, listen: false);
    _offlineBibleService =
        Provider.of<OfflineBibleService>(context, listen: false);
    _downloadService = Provider.of<DownloadService>(context, listen: false);
    _connectionService = Provider.of<ConnectionService>(context, listen: false);
  }

  /// Load initial data
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load books for download options
      _books = await _bibleService.getBooks();

      // Load offline content and download tasks
      await _loadOfflineContent();
      await _loadDownloadTasks();

      AppLogger.info('Download screen data loaded successfully');
    } catch (e) {
      setState(() {
        _error = 'Fout bij laden: $e';
      });
      AppLogger.error('Error loading download screen data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Load offline content
  Future<void> _loadOfflineContent() async {
    final content = await _offlineBibleService.getOfflineContent();
    setState(() {
      _offlineContent = content;
    });
  }

  /// Load download tasks
  Future<void> _loadDownloadTasks() async {
    final tasks = await _offlineBibleService.getDownloadTasks();
    setState(() {
      _downloadTasks = tasks;
    });
  }

  /// Setup stream listeners
  void _setupStreams() {
    _contentSubscription = _offlineBibleService.contentStream.listen((content) {
      setState(() {
        // Update or add content
        final index = _offlineContent.indexWhere((c) => c.id == content.id);
        if (index >= 0) {
          _offlineContent[index] = content;
        } else {
          _offlineContent.add(content);
        }
      });
    });

    _taskSubscription = _offlineBibleService.downloadStream.listen((task) {
      setState(() {
        // Update or add task
        final index = _downloadTasks.indexWhere((t) => t.id == task.id);
        if (index >= 0) {
          _downloadTasks[index] = task;
        } else {
          _downloadTasks.add(task);
        }
      });
    });
  }

  /// Show book selection dialog for downloads
  Future<void> _showBookSelectionDialog() async {
    final selectedBooks = await showDialog<List<BibleBook>>(
      context: context,
      builder: (context) => BookSelectionDialog(
        books: _books,
        offlineContent: _offlineContent,
      ),
    );

    if (selectedBooks != null && selectedBooks.isNotEmpty) {
      for (final book in selectedBooks) {
        await _downloadService.queueBookDownload(book);
      }
      await _loadDownloadTasks();
    }
  }

  /// Show storage management dialog
  Future<void> _showStorageManagementDialog() async {
    final stats = await _offlineBibleService.getDatabaseStats();

    showDialog(
      context: context,
      builder: (context) => StorageManagementDialog(
        stats: stats,
        onClearData: () async {
          await _offlineBibleService.clearAllData();
          await _loadOfflineContent();
          await _loadDownloadTasks();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Downloads'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Opnieuw proberen'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Bijbel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.storage),
            onPressed: _showStorageManagementDialog,
            tooltip: 'Opslag beheren',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Downloads'),
            Tab(text: 'Offline inhoud'),
            Tab(text: 'Bibliotheek'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDownloadsTab(),
          _buildOfflineContentTab(),
          _buildLibraryTab(),
        ],
      ),
      floatingActionButton: !_connectionService.isOnline
          ? null
          : FloatingActionButton(
              onPressed: _showBookSelectionDialog,
              tooltip: 'Nieuwe download',
              child: const Icon(Icons.download),
            ),
    );
  }

  /// Build downloads tab showing active and queued downloads
  Widget _buildDownloadsTab() {
    final activeTasks = _downloadTasks.where((task) => task.isActive).toList();
    final completedTasks =
        _downloadTasks.where((task) => task.isCompleted).toList();
    final failedTasks = _downloadTasks.where((task) => task.hasFailed).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Connection status
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: _connectionService.isOnline
                ? Colors.green[50]
                : Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _connectionService.isOnline
                  ? Colors.green[200]!
                  : Colors.orange[200]!,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _connectionService.isOnline ? Icons.wifi : Icons.wifi_off,
                color: _connectionService.isOnline
                    ? Colors.green[700]
                    : Colors.orange[700],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _connectionService.isOnline
                          ? 'Online - ${_connectionService.currentInfo.getQualityString()}'
                          : 'Offline',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _connectionService.isOnline
                            ? Colors.green[700]
                            : Colors.orange[700],
                      ),
                    ),
                    if (_connectionService.isOnline)
                      Text(
                        'Downloads zijn actief',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[600],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Active downloads
        if (activeTasks.isNotEmpty) ...[
          const Text(
            'Actieve downloads',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...activeTasks.map((task) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.description,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                task.progressText,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildTaskActionButton(task),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearPercentIndicator(
                      percent: task.progress / 100,
                      lineHeight: 8,
                      backgroundColor: Colors.grey[200],
                      progressColor: _getTaskProgressColor(task),
                      barRadius: const Radius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getTaskStatusText(task),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getTaskStatusColor(task),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )),
          const SizedBox(height: 16),
        ],

        // Failed downloads
        if (failedTasks.isNotEmpty) ...[
          const Text(
            'Mislukte downloads',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...failedTasks.map((task) => ListTile(
                title: Text(task.description),
                subtitle: Text(task.error ?? 'Onbekende fout'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () => _downloadService.retryDownload(task.id),
                      tooltip: 'Opnieuw proberen',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _downloadService.cancelDownload(task.id),
                      tooltip: 'Verwijderen',
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 16),
        ],

        // Completed downloads
        if (completedTasks.isNotEmpty) ...[
          const Text(
            'Voltooide downloads',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...completedTasks.take(10).map((task) => ListTile(
                title: Text(task.description),
                subtitle: Text(
                  'Voltooid op ${_formatDate(task.completedAt!)}',
                ),
                leading: const Icon(Icons.check_circle, color: Colors.green),
              )),
        ],

        // Empty state
        if (activeTasks.isEmpty &&
            failedTasks.isEmpty &&
            completedTasks.isEmpty)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.download_outlined,
                    size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Geen downloads',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tik op + om Bijbelboeken te downloaden',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Build offline content tab showing downloaded books/chapters
  Widget _buildOfflineContentTab() {
    if (_offlineContent.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.library_books_outlined,
                size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Geen offline inhoud',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Download boeken om offline te lezen',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    // Group content by testament
    final oldTestament =
        _offlineContent.where((c) => c.testament == 'old').toList();
    final newTestament =
        _offlineContent.where((c) => c.testament == 'new').toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Old Testament
        if (oldTestament.isNotEmpty) ...[
          const Text(
            'Oude Testament',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...oldTestament.map((content) => _buildOfflineContentTile(content)),
          const SizedBox(height: 16),
        ],

        // New Testament
        if (newTestament.isNotEmpty) ...[
          const Text(
            'Nieuwe Testament',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...newTestament.map((content) => _buildOfflineContentTile(content)),
        ],
      ],
    );
  }

  /// Build library tab for browsing and downloading books
  Widget _buildLibraryTab() {
    // Group books by testament
    final oldTestamentBooks =
        _books.where((book) => book.testament == 'old').toList();
    final newTestamentBooks =
        _books.where((book) => book.testament == 'new').toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Old Testament
        const Text(
          'Oude Testament',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...oldTestamentBooks.map((book) => _buildBookTile(book)),
        const SizedBox(height: 16),

        // New Testament
        const Text(
          'Nieuwe Testament',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...newTestamentBooks.map((book) => _buildBookTile(book)),
      ],
    );
  }

  /// Build tile for offline content
  Widget _buildOfflineContentTile(OfflineContent content) {
    final isDownloading = _downloadTasks.any((task) =>
        task.bookId == content.bookId &&
        task.status == DownloadStatus.downloading);

    return Card(
      child: ListTile(
        title: Text(content.bookName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(content.contentType),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: content.progress / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      content.isComplete ? Colors.green : Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${content.progress.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: content.isComplete ? Colors.green : Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${content.formattedFileSize} • ${_formatDate(content.downloadedAt)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            switch (value) {
              case 'remove':
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Verwijderen bevestigen'),
                    content: Text(
                      'Weet je zeker dat je "${content.bookName}" wilt verwijderen?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Annuleren'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Verwijderen'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  await _offlineBibleService.removeOfflineContent(content.id);
                }
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'remove',
              child: Text('Verwijderen'),
            ),
          ],
        ),
        leading: content.isComplete
            ? const Icon(Icons.check_circle, color: Colors.green)
            : isDownloading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.downloading, color: Colors.orange),
      ),
    );
  }

  /// Build tile for book in library
  Widget _buildBookTile(BibleBook book) {
    final isDownloaded =
        _offlineContent.any((c) => c.bookId == book.id && c.isComplete);

    final isDownloading = _downloadTasks.any((task) =>
        task.bookId == book.id && task.status == DownloadStatus.downloading);

    return Card(
      child: ListTile(
        title: Text(book.name),
        subtitle: Text('${book.chapterCount} hoofdstukken'),
        trailing: isDownloaded
            ? const Icon(Icons.check_circle, color: Colors.green)
            : isDownloading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () => _downloadService.queueBookDownload(book),
                    tooltip: 'Downloaden',
                  ),
        leading: Text(
          book.id.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Vandaag';
    } else if (difference.inDays == 1) {
      return 'Gisteren';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} dagen geleden';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Build action button for task
  Widget _buildTaskActionButton(DownloadTask task) {
    switch (task.status) {
      case DownloadStatus.downloading:
        return IconButton(
          icon: const Icon(Icons.pause),
          onPressed: () => _downloadService.pauseDownload(task.id),
          tooltip: 'Pauzeren',
          iconSize: 20,
        );
      case DownloadStatus.pending:
        return IconButton(
          icon: const Icon(Icons.cancel),
          onPressed: () => _downloadService.cancelDownload(task.id),
          tooltip: 'Annuleren',
          iconSize: 20,
        );
      case DownloadStatus.paused:
        return IconButton(
          icon: const Icon(Icons.play_arrow),
          onPressed: () => _downloadService.resumeDownload(task.id),
          tooltip: 'Hervatten',
          iconSize: 20,
        );
      case DownloadStatus.failed:
        return IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => _downloadService.retryDownload(task.id),
          tooltip: 'Opnieuw proberen',
          iconSize: 20,
        );
      case DownloadStatus.completed:
        return const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 20,
        );
    }
  }

  /// Get progress color for task
  Color _getTaskProgressColor(DownloadTask task) {
    switch (task.status) {
      case DownloadStatus.downloading:
        return Colors.blue;
      case DownloadStatus.completed:
        return Colors.green;
      case DownloadStatus.failed:
        return Colors.red;
      case DownloadStatus.paused:
        return Colors.orange;
      case DownloadStatus.pending:
        return Colors.grey;
    }
  }

  /// Get status text for task
  String _getTaskStatusText(DownloadTask task) {
    switch (task.status) {
      case DownloadStatus.downloading:
        return 'Downloaden...';
      case DownloadStatus.pending:
        return 'Wachten op start';
      case DownloadStatus.paused:
        return 'Gepauzeerd';
      case DownloadStatus.failed:
        return 'Mislukt';
      case DownloadStatus.completed:
        return 'Voltooid';
    }
  }

  /// Get status color for task
  Color _getTaskStatusColor(DownloadTask task) {
    switch (task.status) {
      case DownloadStatus.downloading:
        return Colors.blue;
      case DownloadStatus.completed:
        return Colors.green;
      case DownloadStatus.failed:
        return Colors.red;
      case DownloadStatus.paused:
        return Colors.orange;
      case DownloadStatus.pending:
        return Colors.grey;
    }
  }
}

/// Dialog for selecting books to download
class BookSelectionDialog extends StatefulWidget {
  final List<BibleBook> books;
  final List<OfflineContent> offlineContent;

  const BookSelectionDialog({
    super.key,
    required this.books,
    required this.offlineContent,
  });

  @override
  State<BookSelectionDialog> createState() => _BookSelectionDialogState();
}

class _BookSelectionDialogState extends State<BookSelectionDialog> {
  final Set<String> _selectedBookIds = {};

  @override
  Widget build(BuildContext context) {
    final availableBooks = widget.books.where((book) {
      return !widget.offlineContent
          .any((c) => c.bookId == book.id && c.isComplete);
    }).toList();

    return AlertDialog(
      title: const Text('Boeken selecteren'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: ListView.builder(
          itemCount: availableBooks.length,
          itemBuilder: (context, index) {
            final book = availableBooks[index];
            final isSelected = _selectedBookIds.contains(book.id);

            return CheckboxListTile(
              title: Text(book.name),
              subtitle: Text('${book.chapterCount} hoofdstukken'),
              value: isSelected,
              onChanged: (checked) {
                setState(() {
                  if (checked == true) {
                    _selectedBookIds.add(book.id);
                  } else {
                    _selectedBookIds.remove(book.id);
                  }
                });
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuleren'),
        ),
        TextButton(
          onPressed: _selectedBookIds.isEmpty
              ? null
              : () {
                  final selectedBooks = widget.books
                      .where((book) => _selectedBookIds.contains(book.id))
                      .toList();
                  Navigator.of(context).pop(selectedBooks);
                },
          child: const Text('Downloaden'),
        ),
      ],
    );
  }
}

/// Dialog for storage management
class StorageManagementDialog extends StatelessWidget {
  final DatabaseStats stats;
  final VoidCallback onClearData;

  const StorageManagementDialog({
    super.key,
    required this.stats,
    required this.onClearData,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Opslag beheren'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Totale grootte: ${stats.formattedSize}'),
          const SizedBox(height: 8),
          Text('Aantal verzen: ${stats.totalVerses}'),
          const SizedBox(height: 8),
          Text('Aantal boeken: ${stats.totalBooks}'),
          const SizedBox(height: 8),
          Text('Laatste update: ${_formatDate(stats.lastUpdated)}'),
          const SizedBox(height: 16),
          const Text('Verdeling per testament:'),
          ...stats.versesByTestament.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text('${entry.key}: ${entry.value} verzen'),
              )),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Sluiten'),
        ),
        TextButton(
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Alle gegevens wissen?'),
                content: const Text(
                  'Dit verwijdert alle gedownloade Bijbelinhoud. '
                  'Deze actie kan niet ongedaan worden gemaakt.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Annuleren'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Wissen'),
                  ),
                ],
              ),
            );

            if (confirmed == true) {
              onClearData();
              Navigator.of(context).pop();
            }
          },
          child: const Text('Alles wissen'),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
