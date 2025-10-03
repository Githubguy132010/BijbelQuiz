import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bible_provider.dart';
import '../models/bible_book.dart';
import '../models/bible_chapter.dart';
import '../models/bible_verse.dart';
import '../widgets/bible_text_widget.dart';
import 'book_selection_screen.dart';
import '../l10n/strings_nl.dart' as strings;

/// Screen for reading Bible text
class BibleReaderScreen extends StatefulWidget {
  final BibleBook book;
  final BibleChapter chapter;

  const BibleReaderScreen({
    super.key,
    required this.book,
    required this.chapter,
  });

  @override
  State<BibleReaderScreen> createState() => _BibleReaderScreenState();
}

class _BibleReaderScreenState extends State<BibleReaderScreen> {
  @override
  void initState() {
    super.initState();
    // Load verses when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<BibleProvider>()
          .loadVerses(widget.book.id, widget.chapter.chapter);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.book.name} ${widget.chapter.chapter}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.library_books),
            onPressed: _showBookSelection,
          ),
          Consumer<BibleProvider>(
            builder: (context, bibleProvider, child) {
              final isBookmarked = bibleProvider.isVerseBookmarked(
                widget.book.id,
                widget.chapter.chapter,
                1,
              );

              return IconButton(
                icon: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                  color: isBookmarked ? Theme.of(context).colorScheme.primary : null,
                ),
                onPressed: _toggleBookmark,
              );
            },
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
                    onPressed: () => bibleProvider.loadVerses(
                        widget.book.id, widget.chapter.chapter),
                    child: const Text('Opnieuw proberen'),
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

          return BibleTextWidget(verses: bibleProvider.verses);
        },
      ),
      bottomNavigationBar: _buildChapterNavigation(),
    );
  }


  Widget _buildChapterNavigation() {
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
              if (widget.chapter.chapter > 1)
                ElevatedButton(
                  onPressed: () =>
                      _navigateToChapter(widget.chapter.chapter - 1),
                  child: const Text('Vorige'),
                )
              else
                const SizedBox(width: 80),

              // Chapter info
              Text(
                'Hoofdstuk ${widget.chapter.chapter}',
                style: Theme.of(context).textTheme.titleMedium,
              ),

              // Next chapter
              if (widget.chapter.chapter < widget.book.chapterCount)
                ElevatedButton(
                  onPressed: () =>
                      _navigateToChapter(widget.chapter.chapter + 1),
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

  void _navigateToChapter(int chapter) {
    final chapterObj = BibleChapter(
      bookId: widget.book.id,
      chapter: chapter,
      verseCount: 0, // Will be loaded from API
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => BibleReaderScreen(
          book: widget.book,
          chapter: chapterObj,
        ),
      ),
    );
  }

  void _showBookSelection() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const BookSelectionScreen(),
      ),
    );
  }

  void _toggleBookmark() async {
    final bibleProvider = context.read<BibleProvider>();

    // For now, bookmark the current chapter (could be enhanced to bookmark specific verses)
    final isBookmarked = bibleProvider.isVerseBookmarked(
      widget.book.id,
      widget.chapter.chapter,
      1, // First verse of chapter as representative
    );

    if (isBookmarked) {
      // Remove bookmark
      final bookmarks = bibleProvider.bookmarks.where((bookmark) =>
        bookmark.bookId == widget.book.id &&
        bookmark.chapter == widget.chapter.chapter
      ).toList();

      if (bookmarks.isNotEmpty) {
        await bibleProvider.removeBookmark(bookmarks.first.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bladwijzer verwijderd voor ${widget.book.name} ${widget.chapter.chapter}')),
        );
      }
    } else {
      // Add bookmark
      if (bibleProvider.verses.isNotEmpty) {
        await bibleProvider.addBookmark(
          bibleProvider.verses.first,
          widget.book.name,
          notes: 'Bladwijzer voor ${widget.book.name} ${widget.chapter.chapter}',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bladwijzer toegevoegd voor ${widget.book.name} ${widget.chapter.chapter}')),
        );
      }
    }
  }
}
