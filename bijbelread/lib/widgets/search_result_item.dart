import 'package:flutter/material.dart';
import '../models/search_result.dart';

/// Widget for displaying a single search result
class SearchResultItem extends StatelessWidget {
  final SearchResult result;
  final VoidCallback onTap;

  const SearchResultItem({
    super.key,
    required this.result,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Reference and testament indicator
              Row(
                children: [
                  Expanded(
                    child: Text(
                      result.reference,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildTestamentChip(result.testament),
                ],
              ),
              const SizedBox(height: 8),

              // Verse text
              Text(
                result.text,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // Book and chapter info
              Text(
                '${result.bookName} • Hoofdstuk ${result.chapter}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestamentChip(String testament) {
    final isOldTestament = testament.toLowerCase() == 'old';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isOldTestament
            ? Colors.blue.shade100
            : Colors.green.shade100
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isOldTestament
              ? Colors.blue.shade300
              : Colors.green.shade300
          ),
        ),
      ),
      child: Text(
        isOldTestament ? 'OT' : 'NT',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: (isOldTestament
              ? Colors.blue.shade700
              : Colors.green.shade700
          ),
        ),
      ),
    );
  }
}