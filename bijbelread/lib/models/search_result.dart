/// Model representing a search result with enhanced information
import 'bible_verse.dart';

class SearchResult {
  final String bookId;
  final String bookName;
  final int chapter;
  final int verse;
  final String text;
  final String testament; // 'old' or 'new'
  final String highlightedText; // Text with search term highlighted

  const SearchResult({
    required this.bookId,
    required this.bookName,
    required this.chapter,
    required this.verse,
    required this.text,
    required this.testament,
    required this.highlightedText,
  });

  /// Create a SearchResult from a BibleVerse and search query
  factory SearchResult.fromBibleVerse(BibleVerse bibleVerse, String query, String bookName, String testament) {
    // Simple highlighting - in a real app you might want more sophisticated highlighting
    final highlightedText = _highlightSearchTerm(bibleVerse.text, query);

    return SearchResult(
      bookId: bibleVerse.bookId,
      bookName: bookName,
      chapter: bibleVerse.chapter,
      verse: bibleVerse.verse,
      text: bibleVerse.text,
      testament: testament,
      highlightedText: highlightedText,
    );
  }

  /// Get formatted reference (e.g., "Genesis 1:1")
  String get reference {
    return '$bookName $chapter:$verse';
  }

  /// Get short reference (e.g., "Gen 1:1")
  String get shortReference {
    final shortBookName = _getShortBookName(bookName);
    return '$shortBookName $chapter:$verse';
  }

  /// Static method to highlight search terms in text
  static String _highlightSearchTerm(String text, String query) {
    if (query.isEmpty) return text;

    // Simple case-insensitive highlighting
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();

    if (!lowerText.contains(lowerQuery)) return text;

    // For now, just return the original text
    // In a real implementation, you might wrap matches in highlight widgets
    return text;
  }

  /// Get abbreviated book name
  static String _getShortBookName(String fullName) {
    // Simple abbreviation logic - could be expanded
    final name = fullName.toLowerCase();
    if (name.startsWith('genesis')) return 'Gen';
    if (name.startsWith('exodus')) return 'Ex';
    if (name.startsWith('matthe')) return 'Mat';
    if (name.startsWith('mark')) return 'Mar';
    if (name.startsWith('luke') || name.startsWith('lukas')) return 'Luk';
    if (name.startsWith('john') || name.startsWith('johannes')) return 'Joh';
    if (name.startsWith('romans') || name.startsWith('romeinen')) return 'Rom';
    if (name.startsWith('revelation') || name.startsWith('openbaring')) return 'Rev';

    // Return first 3 characters as fallback
    return fullName.length > 3 ? fullName.substring(0, 3) : fullName;
  }

  @override
  String toString() => 'SearchResult(bookId: $bookId, bookName: $bookName, chapter: $chapter, verse: $verse)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchResult &&
      runtimeType == other.runtimeType &&
      bookId == other.bookId &&
      chapter == other.chapter &&
      verse == other.verse;

  @override
  int get hashCode => bookId.hashCode ^ chapter.hashCode ^ verse.hashCode;
}

/// Model representing a search filter
class SearchFilter {
  final String type; // 'testament', 'book', 'chapter_range'
  final String value;
  final String label;

  const SearchFilter({
    required this.type,
    required this.value,
    required this.label,
  });

  @override
  String toString() => 'SearchFilter(type: $type, value: $value, label: $label)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchFilter &&
      runtimeType == other.runtimeType &&
      type == other.type &&
      value == other.value;

  @override
  int get hashCode => type.hashCode ^ value.hashCode;
}

/// Model representing search history entry
class SearchHistoryEntry {
  final String query;
  final DateTime timestamp;
  final int resultCount;

  const SearchHistoryEntry({
    required this.query,
    required this.timestamp,
    required this.resultCount,
  });

  @override
  String toString() => 'SearchHistoryEntry(query: $query, timestamp: $timestamp, results: $resultCount)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchHistoryEntry &&
      runtimeType == other.runtimeType &&
      query == other.query &&
      timestamp == other.timestamp;

  @override
  int get hashCode => query.hashCode ^ timestamp.hashCode;
}