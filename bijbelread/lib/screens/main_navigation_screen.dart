import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bible_provider.dart';
import '../models/bible_book.dart';
import '../models/bible_chapter.dart';
import 'book_selection_screen.dart';
import 'chapter_selection_screen.dart';
import 'search_screen.dart';
import 'bookmarks_screen.dart';
import 'settings_screen.dart';
import '../l10n/strings_nl.dart' as strings;

/// Main navigation screen for Bible reading
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load books when the app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BibleProvider>().loadBooks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.AppStrings.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.bookmark),
            onPressed: _showBookmarks,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Lezen',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Zoeken',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark),
            label: 'Bladwijzers',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildReaderTab();
      case 1:
        return _buildSearchTab();
      case 2:
        return _buildBookmarksTab();
      default:
        return _buildReaderTab();
    }
  }

  Widget _buildReaderTab() {
    return Consumer<BibleProvider>(
      builder: (context, bibleProvider, child) {
        if (bibleProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (bibleProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  bibleProvider.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => bibleProvider.loadBooks(),
                  child: const Text('Opnieuw proberen'),
                ),
              ],
            ),
          );
        }

        if (bibleProvider.books.isEmpty) {
          return const Center(
            child: Text('Geen boeken beschikbaar'),
          );
        }

        return ListView.builder(
          itemCount: bibleProvider.books.length,
          itemBuilder: (context, index) {
            final book = bibleProvider.books[index];
            return ListTile(
              title: Text(book.name),
              subtitle: Text('${book.chapterCount} ${strings.AppStrings.chapter}${book.chapterCount != 1 ? 's' : ''}'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _navigateToBookSelection(book),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchTab() {
    return const SearchScreen();
  }

  Widget _buildBookmarksTab() {
    return const BookmarksScreen();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showSearchDialog() {
    // Navigate directly to search tab
    setState(() => _selectedIndex = 1);
  }

  void _navigateToBookSelection(BibleBook book) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChapterSelectionScreen(book: book),
      ),
    );
  }

  void _showBookmarks() {
    // Navigate directly to bookmarks tab
    setState(() => _selectedIndex = 2);
  }

  void _showSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }
}