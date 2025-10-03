import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bible_provider.dart';
import '../models/bible_book.dart';
import 'chapter_selection_screen.dart';
import '../l10n/strings_nl.dart' as strings;

/// Screen for selecting a Bible book
class BookSelectionScreen extends StatelessWidget {
  const BookSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.AppStrings.selectBook),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<BibleProvider>(
        builder: (context, bibleProvider, child) {
          if (bibleProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
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

          return _buildBooksList(bibleProvider.books, context);
        },
      ),
    );
  }

  Widget _buildBooksList(List<BibleBook> books, BuildContext context) {
    // Group books by testament
    final oldTestamentBooks = books.where((book) => book.testament == 'old').toList();
    final newTestamentBooks = books.where((book) => book.testament == 'new').toList();

    return ListView(
      children: [
        // Old Testament section
        if (oldTestamentBooks.isNotEmpty) ...[
          _buildTestamentHeader(strings.AppStrings.oldTestament),
          ...oldTestamentBooks.map((book) => _buildBookTile(book, context)),
        ],

        // New Testament section
        if (newTestamentBooks.isNotEmpty) ...[
          _buildTestamentHeader(strings.AppStrings.newTestament),
          ...newTestamentBooks.map((book) => _buildBookTile(book, context)),
        ],
      ],
    );
  }

  Widget _buildTestamentHeader(String title) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade100,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBookTile(BibleBook book, BuildContext context) {
    return ListTile(
      title: Text(book.name),
      subtitle: Text('${book.chapterCount} ${strings.AppStrings.chapter}${book.chapterCount != 1 ? 's' : ''}'),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () => _onBookSelected(book, context),
    );
  }

  void _onBookSelected(BibleBook book, BuildContext context) {
    // Navigate to chapter selection for this book
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChapterSelectionScreen(book: book),
      ),
    );
  }
}