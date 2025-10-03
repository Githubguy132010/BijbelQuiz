import 'package:flutter/material.dart';
import '../models/bible_verse.dart';

/// Widget for displaying a single Bible verse
class VerseWidget extends StatelessWidget {
  final BibleVerse verse;
  final bool showVerseNumber;
  final bool isHighlighted;
  final VoidCallback? onTap;

  const VerseWidget({
    super.key,
    required this.verse,
    this.showVerseNumber = true,
    this.isHighlighted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        decoration: BoxDecoration(
          color: isHighlighted ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
          border: isHighlighted
              ? Border(
                  left: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 3,
                  ),
                )
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Verse number
            if (showVerseNumber) ...[
              Container(
                width: 32,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.only(right: 8, top: 2),
                child: Text(
                  '${verse.verse}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isHighlighted
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
            // Verse text
            Expanded(
              child: Text(
                verse.text,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: isHighlighted ? Theme.of(context).primaryColor : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}