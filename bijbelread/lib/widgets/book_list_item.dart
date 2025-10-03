import 'package:flutter/material.dart';
import '../models/bible_book.dart';
import '../l10n/strings_nl.dart' as strings;

/// Widget for displaying a Bible book in a list
class BookListItem extends StatelessWidget {
  final BibleBook book;
  final VoidCallback onTap;

  const BookListItem({
    super.key,
    required this.book,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        title: Text(
          book.name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          '${book.chapterCount} ${strings.AppStrings.chapter}${book.chapterCount != 1 ? 's' : ''}',
          style: TextStyle(
            color: Colors.grey.shade600,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Theme.of(context).primaryColor,
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}