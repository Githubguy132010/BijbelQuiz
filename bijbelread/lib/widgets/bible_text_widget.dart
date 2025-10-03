import 'package:flutter/material.dart';
import '../models/bible_verse.dart';

/// Widget for displaying Bible text with verse numbers
class BibleTextWidget extends StatelessWidget {
  final List<BibleVerse> verses;
  final double fontSize;
  final bool showVerseNumbers;

  const BibleTextWidget({
    super.key,
    required this.verses,
    this.fontSize = 16,
    this.showVerseNumbers = true,
  });

  @override
  Widget build(BuildContext context) {
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
              if (showVerseNumbers) ...[
                Container(
                  width: 32,
                  alignment: Alignment.topRight,
                  padding: const EdgeInsets.only(right: 8, top: 2),
                  child: Text(
                    '${verse.verse}',
                    style: TextStyle(
                      fontSize: fontSize - 2,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
              // Verse text
              Expanded(
                child: Text(
                  verse.text,
                  style: TextStyle(
                    fontSize: fontSize,
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
}