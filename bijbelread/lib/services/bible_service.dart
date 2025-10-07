import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:xml/xml.dart' as xml;

import 'logger.dart';
import 'offline_bible_service.dart';
import '../models/bible_book.dart';
import '../models/bible_chapter.dart';
import '../models/bible_verse.dart';
import '../utils/bible_book_mapper.dart';

/// Service for handling Bible API calls with offline fallback
class BibleService {
  static const String _baseUrl = 'https://www.online-bijbel.nl/api.php';
  static const Duration _timeout = Duration(seconds: 10);

  final http.Client _client = http.Client();
  final OfflineBibleService? _offlineBibleService;

  // Simple in-memory cache
  final Map<String, List<BibleBook>> _booksCache = {};
  final Map<String, List<BibleChapter>> _chaptersCache = {};
  final Map<String, List<BibleVerse>> _versesCache = {};

  // Cache expiration (5 minutes)
  static const Duration _cacheExpiration = Duration(minutes: 5);
  final Map<String, DateTime> _cacheTimestamps = {};

  // Fallback configuration
  bool _enableOfflineFallback = true;

  BibleService({OfflineBibleService? offlineBibleService})
      : _offlineBibleService = offlineBibleService;

  /// Get all Bible books
  Future<List<BibleBook>> getBooks() async {
    // Check cache first
    final cacheKey = _getBooksCacheKey();
    if (_booksCache.containsKey(cacheKey) && _isCacheValid(cacheKey)) {
      AppLogger.info('Returning cached Bible books');
      return _booksCache[cacheKey]!;
    }

    try {
      AppLogger.info('Fetching Bible books...');

      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        throw Exception('Geen internetverbinding beschikbaar');
      }

      final response = await _client.get(
        Uri.parse('$_baseUrl?p=boekenlijst'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        // Parse XML response
        final books = _parseBooksFromXml(response.body);

        // Cache the results
        _booksCache[cacheKey] = books;
        _cacheTimestamps[cacheKey] = DateTime.now();

        AppLogger.info(
            'Successfully fetched and cached ${books.length} Bible books');
        return books;
      } else {
        throw Exception('Server fout: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error fetching Bible books: $e');
      if (e is Exception && e.toString().contains('Timeout')) {
        throw Exception('Time-out bij het laden van boeken');
      }
      rethrow;
    }
  }

  /// Get chapters for a specific book
  Future<List<BibleChapter>> getChapters(String bookId) async {
    // Check cache first
    final cacheKey = _getChaptersCacheKey(bookId);
    if (_chaptersCache.containsKey(cacheKey) && _isCacheValid(cacheKey)) {
      AppLogger.info('Returning cached chapters for book: $bookId');
      return _chaptersCache[cacheKey]!;
    }

    try {
      AppLogger.info('Generating chapters for book: $bookId');

      // Get chapter count for this book
      final chapterCount = _getChapterCountForBook(bookId);
      if (chapterCount <= 0) {
        throw Exception('Ongeldig aantal hoofdstukken voor boek: $bookId');
      }

      // Generate chapters list based on chapter count
      final chapters = List<BibleChapter>.generate(
        chapterCount,
        (index) => BibleChapter(
          bookId: bookId,
          chapter: index + 1,
          verseCount: 0, // Will be determined when verses are loaded
          isAvailableOffline: false,
          downloadedVerses: 0,
        ),
      );

      // Cache the results
      _chaptersCache[cacheKey] = chapters;
      _cacheTimestamps[cacheKey] = DateTime.now();

      AppLogger.info(
          'Successfully generated and cached ${chapters.length} chapters for book: $bookId');
      return chapters;
    } catch (e) {
      AppLogger.error('Error generating chapters: $e');
      rethrow;
    }
  }

  /// Get verses for a specific chapter with offline fallback
  Future<List<BibleVerse>> getVerses(String bookId, int chapter, {int? startVerse, int? endVerse}) async {
    // Check cache first
    final cacheKey = _getVersesCacheKey(bookId, chapter);
    if (_versesCache.containsKey(cacheKey) && _isCacheValid(cacheKey)) {
      AppLogger.info('Returning cached verses for $bookId chapter $chapter');
      return _versesCache[cacheKey]!;
    }

    try {
      AppLogger.info('Fetching verses for $bookId chapter $chapter');

      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        throw Exception('Geen internetverbinding beschikbaar');
      }

      // Convert abbreviated book ID to numeric ID for API
      final numericBookId = BibleBookMapper.getNumericBookId(bookId);

      // Build URL with verse parameter - API requires verse parameter to return content
      String url = '$_baseUrl?b=$numericBookId&h=$chapter';

      // For full chapters, request a large verse range to get the entire chapter
      // The API doesn't return content without a verse parameter, so we request a large range
      if (startVerse != null) {
        if (endVerse != null && endVerse != startVerse) {
          url += '&v=$startVerse-$endVerse';
        } else {
          url += '&v=$startVerse';
        }
      } else {
        // For full chapter, request verses 1-200 (covers even the longest chapters like Psalm 119)
        url += '&v=1-200';
      }

      AppLogger.info('Making API request to: $url');
      final response = await _client.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        AppLogger.info('Response body length: ${response.body.length}');
        AppLogger.info('Response body (first 200 chars): ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');

        if (response.body.isEmpty) {
          AppLogger.error('Server returned empty response for $bookId chapter $chapter');
          throw Exception('Server geeft lege response terug voor ${BibleBookMapper.getBookName(bookId)} hoofdstuk $chapter. De bijbel API lijkt niet te werken.');
        }

        // Parse XML response (API returns XML, not JSON)
        final xmlVerses = _parseVersesFromXml(response.body);

        // Set bookId and chapter for each verse
        final verses = xmlVerses.map((verse) => BibleVerse(
          bookId: bookId,
          chapter: chapter,
          verse: verse.verse,
          text: verse.text,
        )).toList();

        // Cache the results
        _versesCache[cacheKey] = verses;
        _cacheTimestamps[cacheKey] = DateTime.now();

        AppLogger.info('Successfully fetched and cached ${verses.length} verses');
        return verses;
      } else {
        AppLogger.error('Server returned status ${response.statusCode}');
        AppLogger.error('Response body: ${response.body}');
        throw Exception('Server fout: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      AppLogger.error('Error fetching verses: $e');

      // Try offline fallback if enabled and available
      if (_enableOfflineFallback && _offlineBibleService != null) {
        try {
          AppLogger.info(
              'Attempting offline fallback for $bookId chapter $chapter');
          final offlineVerses =
              await _offlineBibleService.getVerses(bookId, chapter);

          if (offlineVerses.isNotEmpty) {
            final verses = offlineVerses
                .map((dbVerse) => BibleVerse(
                      bookId: dbVerse.bookId,
                      chapter: dbVerse.chapter,
                      verse: dbVerse.verse,
                      text: dbVerse.text,
                      isAvailableOffline: true,
                      lastOfflineUpdate: DateTime.now(),
                    ))
                .toList();

            AppLogger.info(
                'Successfully loaded ${verses.length} verses from offline storage');
            return verses;
          }
        } catch (offlineError) {
          AppLogger.warning('Offline fallback also failed: $offlineError');
        }
      }

      if (e is Exception && e.toString().contains('Timeout')) {
        throw Exception('Time-out bij het laden van verzen');
      }

      rethrow;
    }
  }

  /// Search for text in the Bible
  Future<List<BibleVerse>> searchBible(String query) async {
    try {
      AppLogger.info('Searching Bible for: $query');
      AppLogger.info('Search URL will be: $_baseUrl?search=$query');

      final connectivityResult = await Connectivity().checkConnectivity();
      AppLogger.info('Connectivity check result: $connectivityResult');
      if (connectivityResult.contains(ConnectivityResult.none)) {
        throw Exception('No internet connection');
      }

      final uri = Uri.parse('$_baseUrl?search=${Uri.encodeComponent(query)}');
      AppLogger.info('Making search request to: $uri');

      final response = await _client.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);

      AppLogger.info('Search response status: ${response.statusCode}');
      AppLogger.info('Search response headers: ${response.headers}');
      AppLogger.info('Search response body length: ${response.body.length}');
      AppLogger.info('Search response body (first 500 chars): ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          AppLogger.warning('Search returned empty response body');
          return [];
        }

        try {
          final data = json.decode(response.body);
          AppLogger.info('Decoded JSON type: ${data.runtimeType}');
          AppLogger.info('Search response data: $data');

          if (data is List) {
            if (data.isEmpty) {
              AppLogger.info('Search returned empty results list');
              return [];
            }

            final verses =
                data.map((verse) => BibleVerse.fromJson(verse)).toList();
            AppLogger.info('Search returned ${verses.length} results');
            return verses;
          } else {
            AppLogger.error('Invalid response format - expected List, got ${data.runtimeType}');
            AppLogger.error('Response body: ${response.body}');
            throw Exception('Invalid response format');
          }
        } catch (jsonError) {
          AppLogger.error('JSON decode error: $jsonError');
          AppLogger.error('Response body that failed to parse: ${response.body}');
          throw Exception('Failed to parse search response: $jsonError');
        }
      } else {
        AppLogger.error('Search failed with status: ${response.statusCode}');
        throw Exception('Search failed: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error searching Bible: $e');
      AppLogger.error('Error type: ${e.runtimeType}');
      AppLogger.error('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  /// Check if cache entry is still valid
  bool _isCacheValid(String key) {
    final timestamp = _cacheTimestamps[key];
    return timestamp != null &&
        DateTime.now().difference(timestamp) < _cacheExpiration;
  }

  /// Get cache key for books
  String _getBooksCacheKey() => 'books';

  /// Parse XML response to extract Bible verses
  List<BibleVerse> _parseVersesFromXml(String xmlResponse) {
    try {
      // Clean the response body first (remove BOM or other artifacts)
      String cleanBody = xmlResponse.trim();
      if (cleanBody.startsWith('\uFEFF')) {
        cleanBody = cleanBody.substring(1);
      }

      AppLogger.info('Parsing XML response for verses, length: ${cleanBody.length}');
      AppLogger.info('XML content (first 300 chars): ${cleanBody.substring(0, cleanBody.length > 300 ? 300 : cleanBody.length)}');

      final document = xml.XmlDocument.parse(cleanBody);
      final verses = <BibleVerse>[];

      // Find all vers elements in the XML structure
      final verseElements = document.findAllElements('vers');

      for (final verseElement in verseElements) {
        final verseNumber = verseElement.getAttribute('name'); // Changed from 'vers' to 'name'
        final verseText = verseElement.innerText.trim();

        if (verseNumber != null && verseText.isNotEmpty) {
          final verseNum = int.tryParse(verseNumber);
          if (verseNum != null) {
            verses.add(BibleVerse(
              bookId: '', // Will be set by caller
              chapter: 0, // Will be set by caller
              verse: verseNum,
              text: verseText,
            ));
          }
        }
      }

      if (verses.isEmpty) {
        AppLogger.warning('No verses found in XML response');
      } else {
        AppLogger.info('Successfully parsed ${verses.length} verses from XML');
      }

      return verses;
    } catch (e) {
      AppLogger.error('Error parsing verses XML: $e');
      AppLogger.error('XML content that failed to parse: ${xmlResponse.substring(0, xmlResponse.length > 500 ? 500 : xmlResponse.length)}');
      throw Exception('XML parsing mislukt voor verzen: $e');
    }
  }

  /// Parse XML response to extract Bible books
  List<BibleBook> _parseBooksFromXml(String xmlResponse) {
    try {
      // Clean the response body first (remove BOM or other artifacts)
      String cleanBody = xmlResponse.trim();
      if (cleanBody.startsWith('\uFEFF')) {
        cleanBody = cleanBody.substring(1);
      }

      final document = xml.XmlDocument.parse(cleanBody);
      final books = <BibleBook>[];

      // Find all bijbelboek elements in the XML structure
      final bookElements = document.findAllElements('bijbelboek');

      for (final bookElement in bookElements) {
        final name = bookElement.getAttribute('name');

        if (name != null) {
          // Extract book ID from the name attribute (format: "1", "2", etc.)
          final bookId = name;

          // Determine testament based on book number
          final bookNumber = int.tryParse(name) ?? 0;
          final isOldTestament = bookNumber <= 39;

          // Get chapter count (this would need to be determined differently)
          // For now, we'll use a default or need to fetch this separately
          final chapterCount = _getChapterCountForBook(bookId);

          books.add(BibleBook(
            id: bookId,
            name: _getBookNameFromId(bookId),
            testament: isOldTestament ? 'old' : 'new',
            chapterCount: chapterCount,
          ));
        }
      }

      if (books.isEmpty) {
        throw Exception('Geen boeken gevonden in XML response');
      }

      return books;
    } catch (e) {
      AppLogger.error('Error parsing books XML: $e');
      throw Exception('XML parsing mislukt: $e');
    }
  }

  /// Get chapter count for a book (simplified mapping)
  int _getChapterCountForBook(String bookId) {
    // This is a simplified mapping - in a real implementation you might want
    // to fetch this data or have a complete mapping
    const Map<String, int> chapterCounts = {
      '1': 50,   // Genesis
      '2': 40,   // Exodus
      '3': 27,   // Leviticus
      '4': 36,   // Numeri
      '5': 34,   // Deuteronomium
      '6': 24,   // Jozua
      '7': 21,   // Richteren
      '8': 4,    // Ruth
      '9': 31,   // 1 Samuel
      '10': 24,  // 2 Samuel
      '11': 22,  // 1 Koningen
      '12': 25,  // 2 Koningen
      '13': 29,  // 1 Kronieken
      '14': 36,  // 2 Kronieken
      '15': 10,  // Ezra
      '16': 13,  // Nehemia
      '17': 10,  // Ester
      '18': 42,  // Job
      '19': 150, // Psalmen
      '20': 31,  // Spreuken
      '21': 12,  // Prediker
      '22': 8,   // Hooglied
      '23': 66,  // Jesaja
      '24': 52,  // Jeremia
      '25': 5,   // Klaagliederen
      '26': 48,  // Ezechiël
      '27': 12,  // Daniël
      '28': 14,  // Hosea
      '29': 3,   // Joël
      '30': 9,   // Amos
      '31': 1,   // Obadja
      '32': 4,   // Jona
      '33': 7,   // Micha
      '34': 3,   // Nahum
      '35': 3,   // Habakuk
      '36': 3,   // Zefanja
      '37': 2,   // Haggai
      '38': 14,  // Zacharia
      '39': 4,   // Maleachi
      '40': 28,  // Matteüs
      '41': 16,  // Marcus
      '42': 24,  // Lukas
      '43': 21,  // Johannes
      '44': 28,  // Handelingen
      '45': 16,  // Romeinen
      '46': 16,  // 1 Korintiërs
      '47': 13,  // 2 Korintiërs
      '48': 6,   // Galaten
      '49': 6,   // Efeziërs
      '50': 4,   // Filippenzen
      '51': 4,   // Kolossenzen
      '52': 5,   // 1 Tessalonicenzen
      '53': 3,   // 2 Tessalonicenzen
      '54': 6,   // 1 Timoteüs
      '55': 4,   // 2 Timoteüs
      '56': 3,   // Titus
      '57': 1,   // Filemon
      '58': 13,  // Hebreeën
      '59': 5,   // Jakobus
      '60': 5,   // 1 Petrus
      '61': 3,   // 2 Petrus
      '62': 5,   // 1 Johannes
      '63': 1,   // 2 Johannes
      '64': 1,   // 3 Johannes
      '65': 1,   // Judas
      '66': 22,  // Openbaring
    };

    return chapterCounts[bookId] ?? 1;
  }

  /// Get book name from book ID
  String _getBookNameFromId(String bookId) {
    const Map<String, String> bookNames = {
      '1': 'Genesis',
      '2': 'Exodus',
      '3': 'Leviticus',
      '4': 'Numeri',
      '5': 'Deuteronomium',
      '6': 'Jozua',
      '7': 'Richteren',
      '8': 'Ruth',
      '9': '1 Samuel',
      '10': '2 Samuel',
      '11': '1 Koningen',
      '12': '2 Koningen',
      '13': '1 Kronieken',
      '14': '2 Kronieken',
      '15': 'Ezra',
      '16': 'Nehemia',
      '17': 'Ester',
      '18': 'Job',
      '19': 'Psalmen',
      '20': 'Spreuken',
      '21': 'Prediker',
      '22': 'Hooglied',
      '23': 'Jesaja',
      '24': 'Jeremia',
      '25': 'Klaagliederen',
      '26': 'Ezechiël',
      '27': 'Daniël',
      '28': 'Hosea',
      '29': 'Joël',
      '30': 'Amos',
      '31': 'Obadja',
      '32': 'Jona',
      '33': 'Micha',
      '34': 'Nahum',
      '35': 'Habakuk',
      '36': 'Zefanja',
      '37': 'Haggai',
      '38': 'Zacharia',
      '39': 'Maleachi',
      '40': 'Matteüs',
      '41': 'Marcus',
      '42': 'Lukas',
      '43': 'Johannes',
      '44': 'Handelingen',
      '45': 'Romeinen',
      '46': '1 Korintiërs',
      '47': '2 Korintiërs',
      '48': 'Galaten',
      '49': 'Efeziërs',
      '50': 'Filippenzen',
      '51': 'Kolossenzen',
      '52': '1 Tessalonicenzen',
      '53': '2 Tessalonicenzen',
      '54': '1 Timoteüs',
      '55': '2 Timoteüs',
      '56': 'Titus',
      '57': 'Filemon',
      '58': 'Hebreeën',
      '59': 'Jakobus',
      '60': '1 Petrus',
      '61': '2 Petrus',
      '62': '1 Johannes',
      '63': '2 Johannes',
      '64': '3 Johannes',
      '65': 'Judas',
      '66': 'Openbaring',
    };

    return bookNames[bookId] ?? 'Unknown';
  }

  /// Get cache key for chapters
  String _getChaptersCacheKey(String bookId) => 'chapters_$bookId';

  /// Get cache key for verses
  String _getVersesCacheKey(String bookId, int chapter) =>
      'verses_${bookId}_$chapter';

  /// Enable or disable offline fallback
  void setOfflineFallbackEnabled(bool enabled) {
    _enableOfflineFallback = enabled;
    AppLogger.info('Offline fallback ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Check if offline fallback is enabled
  bool get isOfflineFallbackEnabled => _enableOfflineFallback;

  /// Check if offline content is available for a book and chapter
  Future<bool> isOfflineContentAvailable(String bookId, int chapter) async {
    if (_offlineBibleService == null) return false;

    try {
      final verses = await _offlineBibleService.getVerses(bookId, chapter);
      return verses.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get offline availability info for a book
  Future<Map<String, bool>> getOfflineAvailability(String bookId) async {
    if (_offlineBibleService == null) {
      return {};
    }

    try {
      final content = await _offlineBibleService.getOfflineContentForBook(bookId);
      if (content == null) return {};

      final chapters = await getChapters(bookId);
      final availability = <String, bool>{};

      for (final chapter in chapters) {
        final isAvailable = chapter.chapter <= content.downloadedVerses / 50; // Rough estimate
        availability['chapter_${chapter.chapter}'] = isAvailable;
      }

      return availability;
    } catch (e) {
      AppLogger.error('Error checking offline availability: $e');
      return {};
    }
  }

  /// Clear all caches
  void clearCache() {
    _booksCache.clear();
    _chaptersCache.clear();
    _versesCache.clear();
    _cacheTimestamps.clear();
    AppLogger.info('Bible service cache cleared');
  }


  /// Dispose of the service
  void dispose() {
    _client.close();
    clearCache();
    AppLogger.info('Bible service disposed');
  }
}
