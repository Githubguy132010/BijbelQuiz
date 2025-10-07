import 'package:http/http.dart' as http;

void main() async {
  print('Testing Bible API...');

  // Test different endpoints
  final baseUrl = 'https://www.online-bijbel.nl/api.php';

  try {
    // Test books list
    print('\n1. Testing books list...');
    final booksResponse = await http.get(Uri.parse('$baseUrl?p=boekenlijst'));
    print('Books status: ${booksResponse.statusCode}');
    print('Books response length: ${booksResponse.body.length}');
    if (booksResponse.body.isNotEmpty) {
      print('Books response (first 300 chars): ${booksResponse.body.substring(0, booksResponse.body.length > 300 ? 300 : booksResponse.body.length)}');
    }

    // Test specific chapter with verse range (NEW API FORMAT for full chapters)
    print('\n2. Testing Deuteronomy chapter 1 (new format: b=5&h=1&v=1-200)...');
    final verseResponse = await http.get(Uri.parse('$baseUrl?b=5&h=1&v=1-200'));
    print('Verse status: ${verseResponse.statusCode}');
    print('Verse response length: ${verseResponse.body.length}');
    if (verseResponse.body.isNotEmpty) {
      print('Verse response (first 500 chars): ${verseResponse.body.substring(0, verseResponse.body.length > 500 ? 500 : verseResponse.body.length)}');
    } else {
      print('Verse response is EMPTY!');
    }

    // Test Genesis chapter 1 for comparison (NEW API FORMAT for full chapters)
    print('\n3. Testing Genesis chapter 1 (new format: b=1&h=1&v=1-200)...');
    final genesisResponse = await http.get(Uri.parse('$baseUrl?b=1&h=1&v=1-200'));
    print('Genesis status: ${genesisResponse.statusCode}');
    print('Genesis response length: ${genesisResponse.body.length}');
    if (genesisResponse.body.isNotEmpty) {
      print('Genesis response (first 500 chars): ${genesisResponse.body.substring(0, genesisResponse.body.length > 500 ? 500 : genesisResponse.body.length)}');
    } else {
      print('Genesis response is EMPTY!');
    }

    // Test with verse parameter
    print('\n4. Testing Genesis chapter 1 verses 1-3 (b=1&h=1&v=1-3)...');
    final verseRangeResponse = await http.get(Uri.parse('$baseUrl?b=1&h=1&v=1-3'));
    print('VerseRange status: ${verseRangeResponse.statusCode}');
    print('VerseRange response length: ${verseRangeResponse.body.length}');
    if (verseRangeResponse.body.isNotEmpty) {
      print('VerseRange response (first 500 chars): ${verseRangeResponse.body.substring(0, verseRangeResponse.body.length > 500 ? 500 : verseRangeResponse.body.length)}');
    } else {
      print('VerseRange response is EMPTY!');
    }

    // Test fallback API
    print('\n4. Testing fallback API (bible-api.com)...');
    try {
      final fallbackResponse = await http.get(
        Uri.parse('https://bible-api.com/genesis+1?translation=kjv'),
        headers: {'Accept': 'application/json'},
      );
      print('Fallback status: ${fallbackResponse.statusCode}');
      print('Fallback response length: ${fallbackResponse.body.length}');
      if (fallbackResponse.body.isNotEmpty) {
        print('Fallback response (first 500 chars): ${fallbackResponse.body.substring(0, fallbackResponse.body.length > 500 ? 500 : fallbackResponse.body.length)}');
      }
    } catch (e) {
      print('Fallback API error: $e');
    }

  } catch (e) {
    print('Error testing API: $e');
  }
}