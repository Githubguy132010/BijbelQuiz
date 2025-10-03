/// Utility class for mapping Bible book names and IDs
class BibleBookMapper {
  /// Map of abbreviated book IDs to numeric IDs for online-bijbel.nl API
  static const Map<String, String> _abbreviatedToNumeric = {
    'gen': '1',
    'exo': '2',
    'lev': '3',
    'num': '4',
    'deu': '5',
    'jos': '6',
    'jdg': '7',
    'rut': '8',
    '1sa': '9',
    '2sa': '10',
    '1ki': '11',
    '2ki': '12',
    '1ch': '13',
    '2ch': '14',
    'ezr': '15',
    'neh': '16',
    'est': '17',
    'job': '18',
    'psa': '19',
    'pro': '20',
    'ecc': '21',
    'sol': '22',
    'isa': '23',
    'jer': '24',
    'lam': '25',
    'eze': '26',
    'dan': '27',
    'hos': '28',
    'jol': '29',
    'amo': '30',
    'oba': '31',
    'jon': '32',
    'mic': '33',
    'nah': '34',
    'hab': '35',
    'zep': '36',
    'hag': '37',
    'zec': '38',
    'mal': '39',
    'mat': '40',
    'mar': '41',
    'luk': '42',
    'joh': '43',
    'act': '44',
    'rom': '45',
    '1co': '46',
    '2co': '47',
    'gal': '48',
    'eph': '49',
    'phi': '50',
    'col': '51',
    '1th': '52',
    '2th': '53',
    '1ti': '54',
    '2ti': '55',
    'tit': '56',
    'phm': '57',
    'heb': '58',
    'jam': '59',
    '1pe': '60',
    '2pe': '61',
    '1jo': '62',
    '2jo': '63',
    '3jo': '64',
    'jud': '65',
    'rev': '66',
  };

  /// Map of Bible book IDs to their full names
  static const Map<String, String> bookNames = {
    'gen': 'Genesis',
    'exo': 'Exodus',
    'lev': 'Leviticus',
    'num': 'Numeri',
    'deu': 'Deuteronomium',
    'jos': 'Jozua',
    'jdg': 'Richteren',
    'rut': 'Ruth',
    '1sa': '1 Samuel',
    '2sa': '2 Samuel',
    '1ki': '1 Koningen',
    '2ki': '2 Koningen',
    '1ch': '1 Kronieken',
    '2ch': '2 Kronieken',
    'ezr': 'Ezra',
    'neh': 'Nehemia',
    'est': 'Esther',
    'job': 'Job',
    'psa': 'Psalmen',
    'pro': 'Spreuken',
    'ecc': 'Prediker',
    'sol': 'Hooglied',
    'isa': 'Jesaja',
    'jer': 'Jeremia',
    'lam': 'Klaagliederen',
    'eze': 'Ezechiël',
    'dan': 'Daniël',
    'hos': 'Hosea',
    'jol': 'Joël',
    'amo': 'Amos',
    'oba': 'Obadja',
    'jon': 'Jona',
    'mic': 'Micha',
    'nah': 'Nahum',
    'hab': 'Habakuk',
    'zep': 'Zefanja',
    'hag': 'Haggai',
    'zec': 'Zacharia',
    'mal': 'Maleachi',
    'mat': 'Mattheüs',
    'mar': 'Markus',
    'luk': 'Lukas',
    'joh': 'Johannes',
    'act': 'Handelingen',
    'rom': 'Romeinen',
    '1co': '1 Korinthe',
    '2co': '2 Korinthe',
    'gal': 'Galaten',
    'eph': 'Efeze',
    'phi': 'Filippenzen',
    'col': 'Kolossenzen',
    '1th': '1 Thessalonica',
    '2th': '2 Thessalonica',
    '1ti': '1 Timotheüs',
    '2ti': '2 Timotheüs',
    'tit': 'Titus',
    'phm': 'Filemon',
    'heb': 'Hebreeën',
    'jam': 'Jakobus',
    '1pe': '1 Petrus',
    '2pe': '2 Petrus',
    '1jo': '1 Johannes',
    '2jo': '2 Johannes',
    '3jo': '3 Johannes',
    'jud': 'Judas',
    'rev': 'Openbaring',
  };

  /// Get the full name of a Bible book by its ID
  static String getBookName(String bookId) {
    return bookNames[bookId] ?? bookId;
  }

  /// Get all book IDs
  static List<String> getAllBookIds() {
    return bookNames.keys.toList();
  }

  /// Get all book names
  static List<String> getAllBookNames() {
    return bookNames.values.toList();
  }

  /// Check if a book ID exists
  static bool hasBook(String bookId) {
    return bookNames.containsKey(bookId);
  }

  /// Convert abbreviated book ID to numeric ID for API calls
  static String getNumericBookId(String abbreviatedBookId) {
    return _abbreviatedToNumeric[abbreviatedBookId] ?? abbreviatedBookId;
  }

  /// Convert numeric book ID back to abbreviated ID
  static String getAbbreviatedBookId(String numericBookId) {
    final entry = _abbreviatedToNumeric.entries
        .firstWhere((entry) => entry.value == numericBookId,
                    orElse: () => MapEntry('', numericBookId));
    return entry.key;
  }

  /// Get books by testament
  static List<String> getOldTestamentBooks() {
    return bookNames.keys.where((bookId) {
      return !bookId.startsWith(RegExp(r'[123456789]')) || bookId.startsWith(RegExp(r'[123456789][a-z]+'));
    }).toList();
  }

  static List<String> getNewTestamentBooks() {
    return bookNames.keys.where((bookId) {
      return bookId.startsWith(RegExp(r'[123456789]'));
    }).toList();
  }
}