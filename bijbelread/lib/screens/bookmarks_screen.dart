import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bible_provider.dart';
import '../models/bookmark.dart';
import '../widgets/bookmark_item.dart';
import '../l10n/strings_nl.dart' as strings;

/// Screen for managing bookmarked Bible verses
class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  String _selectedCategory = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bladwijzers'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildSearchAndFilterBar(),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'manage_categories',
                child: Text('Categorieën beheren'),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Text('Exporteren'),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Text('Alles wissen'),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<BibleProvider>(
        builder: (context, bibleProvider, child) {
          final bookmarks = _getFilteredBookmarks(bibleProvider.bookmarks);

          if (bookmarks.isEmpty) {
            return _buildEmptyState();
          }

          return _buildBookmarksList(bookmarks);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBookmarkDialog,
        tooltip: 'Bladwijzer toevoegen',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Zoek in bladwijzers...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),

          const SizedBox(height: 8),

          // Category filter chips
          Consumer<BibleProvider>(
            builder: (context, bibleProvider, child) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryChip('all', 'Alles', Icons.bookmark_border),
                    const SizedBox(width: 8),
                    ...bibleProvider.bookmarkCategories.map((category) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildCategoryChip(
                          category.id,
                          category.name,
                          Icons.category,
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String categoryId, String label, IconData icon) {
    final isSelected = _selectedCategory == categoryId;

    return FilterChip(
      label: Text(label),
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? Theme.of(context).colorScheme.primary : null,
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedCategory = categoryId);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            strings.AppStrings.noBookmarks,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Tik op + om je eerste bladwijzer toe te voegen',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _showAddBookmarkDialog,
            icon: const Icon(Icons.add),
            label: const Text('Bladwijzer toevoegen'),
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarksList(List<Bookmark> bookmarks) {
    return ListView.builder(
      itemCount: bookmarks.length,
      itemBuilder: (context, index) {
        final bookmark = bookmarks[index];
        return BookmarkItem(
          bookmark: bookmark,
          onTap: () => _navigateToBookmark(bookmark),
          onEdit: () => _showEditBookmarkDialog(bookmark),
          onDelete: () => _showDeleteConfirmation(bookmark),
        );
      },
    );
  }

  List<Bookmark> _getFilteredBookmarks(List<Bookmark> allBookmarks) {
    // Filter by category
    var filtered = allBookmarks;
    if (_selectedCategory != 'all') {
      filtered = filtered.where((bookmark) =>
        bookmark.tags.contains(_selectedCategory)
      ).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((bookmark) {
        return bookmark.verseText.toLowerCase().contains(query) ||
               bookmark.bookName.toLowerCase().contains(query) ||
               bookmark.notes?.toLowerCase().contains(query) == true ||
               bookmark.formattedTags.toLowerCase().contains(query);
      }).toList();
    }

    // Sort by creation date (newest first)
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return filtered;
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'manage_categories':
        _showManageCategoriesDialog();
        break;
      case 'export':
        _exportBookmarks();
        break;
      case 'clear_all':
        _showClearAllConfirmation();
        break;
    }
  }

  void _showAddBookmarkDialog() {
    showDialog(
      context: context,
      builder: (context) => _BookmarkDialog(
        title: 'Bladwijzer toevoegen',
        onSave: (bookId, chapter, verse, bookName, notes, tags) {
          // In a real implementation, this would get the current verse from the reader
          // For now, we'll show a message that this needs to be implemented
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bladwijzer toevoegen moet worden geïmplementeerd vanuit de Bijbellezer'),
            ),
          );
        },
      ),
    );
  }

  void _showEditBookmarkDialog(Bookmark bookmark) {
    showDialog(
      context: context,
      builder: (context) => _BookmarkDialog(
        title: 'Bladwijzer bewerken',
        initialBookmark: bookmark,
        onSave: (bookId, chapter, verse, bookName, notes, tags) {
          final updatedBookmark = bookmark.copyWith(
            notes: notes,
            tags: tags,
            updatedAt: DateTime.now(),
          );
          context.read<BibleProvider>().updateBookmark(updatedBookmark);
        },
      ),
    );
  }

  void _showDeleteConfirmation(Bookmark bookmark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bladwijzer verwijderen'),
        content: Text('Weet je zeker dat je deze bladwijzer wilt verwijderen?\n\n"${bookmark.reference}"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuleren'),
          ),
          TextButton(
            onPressed: () {
              context.read<BibleProvider>().removeBookmark(bookmark.id);
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Verwijderen'),
          ),
        ],
      ),
    );
  }

  void _showManageCategoriesDialog() {
    showDialog(
      context: context,
      builder: (context) => const _ManageCategoriesDialog(),
    );
  }

  void _exportBookmarks() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporteren wordt nog geïmplementeerd')),
    );
  }

  void _showClearAllConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alle bladwijzers wissen'),
        content: const Text('Weet je zeker dat je alle bladwijzers wilt wissen? Dit kan niet ongedaan worden gemaakt.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuleren'),
          ),
          TextButton(
            onPressed: () {
              // Clear all bookmarks
              context.read<BibleProvider>().bookmarks.clear();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Alle bladwijzers zijn gewist')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Alles wissen'),
          ),
        ],
      ),
    );
  }

  void _navigateToBookmark(Bookmark bookmark) {
    // Navigate to the bookmarked verse in the reader
    // This would need to be implemented based on the existing navigation pattern
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigeren naar ${bookmark.reference}'),
        action: SnackBarAction(
          label: 'Ga naar',
          onPressed: () {
            // TODO: Implement navigation to specific verse
          },
        ),
      ),
    );
  }
}

/// Dialog for adding/editing bookmarks
class _BookmarkDialog extends StatefulWidget {
  final String title;
  final Bookmark? initialBookmark;
  final Function(String bookId, int chapter, int verse, String bookName, String? notes, List<String> tags) onSave;

  const _BookmarkDialog({
    required this.title,
    this.initialBookmark,
    required this.onSave,
  });

  @override
  State<_BookmarkDialog> createState() => _BookmarkDialogState();
}

class _BookmarkDialogState extends State<_BookmarkDialog> {
  late TextEditingController _notesController;
  late TextEditingController _tagsController;
  late List<String> _tags;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.initialBookmark?.notes ?? '');
    _tags = List.from(widget.initialBookmark?.tags ?? []);
    _tagsController = TextEditingController(text: _tags.join(', '));
  }

  @override
  void dispose() {
    _notesController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.initialBookmark != null) ...[
            ListTile(
              title: Text(widget.initialBookmark!.reference),
              subtitle: Text(widget.initialBookmark!.verseText),
              leading: const Icon(Icons.book),
            ),
            const Divider(),
          ],
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notities (optioneel)',
              hintText: 'Voeg persoonlijke notities toe...',
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _tagsController,
            decoration: const InputDecoration(
              labelText: 'Tags (gescheiden door komma\'s)',
              hintText: 'Bijvoorbeeld: studie, gebed, favoriet',
            ),
            onChanged: (value) {
              setState(() {
                _tags = value.split(',')
                    .map((tag) => tag.trim())
                    .where((tag) => tag.isNotEmpty)
                    .toList();
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuleren'),
        ),
        TextButton(
          onPressed: () {
            if (widget.initialBookmark != null) {
              widget.onSave(
                widget.initialBookmark!.bookId,
                widget.initialBookmark!.chapter,
                widget.initialBookmark!.verse,
                widget.initialBookmark!.bookName,
                _notesController.text.isNotEmpty ? _notesController.text : null,
                _tags,
              );
            }
            Navigator.of(context).pop();
          },
          child: const Text('Opslaan'),
        ),
      ],
    );
  }
}

/// Dialog for managing bookmark categories
class _ManageCategoriesDialog extends StatelessWidget {
  const _ManageCategoriesDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Categorieën beheren'),
      content: const Text('Categorieënbeheer wordt nog geïmplementeerd'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Sluiten'),
        ),
      ],
    );
  }
}