import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bible_provider.dart';
import '../models/bible_book.dart';
import '../models/bible_chapter.dart';
import '../widgets/chapter_list_item.dart';
import '../l10n/strings_nl.dart' as strings;

class ChapterSelectionScreen extends StatelessWidget {
  final BibleBook book;

  const ChapterSelectionScreen({
    super.key,
    required this.book,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${book.name} - ${strings.AppStrings.selectChapter}'),
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
                    onPressed: () => bibleProvider.loadChapters(book.id),
                    child: Text(strings.AppStrings.submit),
                  ),
                ],
              ),
            );
          }

          if (bibleProvider.chapters.isEmpty) {
            return const Center(
              child: Text('Geen hoofdstukken beschikbaar'),
            );
          }

          return _buildChaptersList(bibleProvider.chapters, context);
        },
      ),
    );
  }

  Widget _buildChaptersList(List<BibleChapter> chapters, BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: chapters.length,
      itemBuilder: (context, index) {
        final chapter = chapters[index];
        return ChapterListItem(
          chapter: chapter,
          onTap: () => _onChapterSelected(chapter, context),
        );
      },
    );
  }

  void _onChapterSelected(BibleChapter chapter, BuildContext context) {
    // Navigate to Bible reader screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _BibleReaderScreen(
          book: book,
          chapter: chapter,
        ),
      ),
    );
  }
}

/// Internal Bible reader screen to avoid forward reference issues
class _BibleReaderScreen extends StatelessWidget {
  final BibleBook book;
  final BibleChapter chapter;

  const _BibleReaderScreen({
    required this.book,
    required this.chapter,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${book.name} ${chapter.chapter}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_outline),
            onPressed: _toggleBookmark,
          ),
        ],
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
                    onPressed: () => bibleProvider.loadVerses(book.id, chapter.chapter),
                    child: Text(strings.AppStrings.submit),
                  ),
                ],
              ),
            );
          }

          if (bibleProvider.verses.isEmpty) {
            return const Center(
              child: Text('Geen verzen gevonden'),
            );
          }

          return _buildBibleText(bibleProvider.verses, context);
        },
      ),
      bottomNavigationBar: _buildChapterNavigation(context),
    );
  }

  Widget _buildBibleText(List verses, BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: verses.length,
      itemBuilder: (context, index) {
        final verse = verses[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Verse number
              Container(
                width: 32,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.only(right: 8, top: 2),
                child: Text(
                  '${verse.verse}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              // Verse text
              Expanded(
                child: Text(
                  verse.text,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChapterNavigation(BuildContext context) {
    return Consumer<BibleProvider>(
      builder: (context, bibleProvider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              top: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Previous chapter
              if (chapter.chapter > 1)
                ElevatedButton(
                  onPressed: () => _navigateToChapter(chapter.chapter - 1, context),
                  child: const Text('Vorige'),
                )
              else
                const SizedBox(width: 80),

              // Chapter info
              Text(
                '${strings.AppStrings.chapter} ${chapter.chapter}',
                style: Theme.of(context).textTheme.titleMedium,
              ),

              // Next chapter
              if (chapter.chapter < book.chapterCount)
                ElevatedButton(
                  onPressed: () => _navigateToChapter(chapter.chapter + 1, context),
                  child: const Text('Volgende'),
                )
              else
                const SizedBox(width: 80),
            ],
          ),
        );
      },
    );
  }

  void _navigateToChapter(int chapterNumber, BuildContext context) {
    final chapterObj = BibleChapter(
      bookId: book.id,
      chapter: chapterNumber,
      verseCount: 0, // Will be loaded from API
    );

    // Replace current route with new chapter
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => _BibleReaderScreen(
          book: book,
          chapter: chapterObj,
        ),
      ),
    );
  }

  void _toggleBookmark() {
    // Placeholder for bookmark functionality - will be implemented later
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(content: Text(strings.AppStrings.addBookmark)),
    // );
  }
}