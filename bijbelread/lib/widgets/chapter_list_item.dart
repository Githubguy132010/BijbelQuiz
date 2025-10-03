import 'package:flutter/material.dart';
import '../models/bible_chapter.dart';

/// Widget for displaying a Bible chapter in a list
class ChapterListItem extends StatelessWidget {
  final BibleChapter chapter;
  final VoidCallback onTap;
  final bool isSelected;

  const ChapterListItem({
    super.key,
    required this.chapter,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
      child: ListTile(
        title: Text(
          'Hoofdstuk ${chapter.chapter}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Theme.of(context).primaryColor : null,
          ),
        ),
        subtitle: Text(
          '${chapter.verseCount} ${chapter.verseCount == 1 ? 'vers' : 'verzen'}',
          style: TextStyle(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade600,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade400,
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}