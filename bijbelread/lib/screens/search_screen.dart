import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bible_provider.dart';
import '../models/search_result.dart';
import '../models/bible_book.dart';
import '../widgets/search_result_item.dart';
import '../widgets/search_filter_chips.dart';
import '../l10n/strings_nl.dart' as strings;

/// Enhanced search screen with real-time search and filtering
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _showFilters = false;
  final bool _showHistory = true;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zoeken in de Bijbel'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildSearchBar(),
        ),
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () => setState(() => _showFilters = !_showFilters),
            tooltip: _showFilters ? 'Verberg filters' : 'Toon filters',
          ),
        ],
      ),
      body: Consumer<BibleProvider>(
        builder: (context, bibleProvider, child) {
          if (bibleProvider.isLoading && _searchController.text.isNotEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_searchController.text.isEmpty) {
            return _buildSearchSuggestions();
          }

          final filteredResults = bibleProvider.getFilteredSearchResults();

          if (filteredResults.isEmpty) {
            return _buildNoResults();
          }

          return _buildSearchResults(filteredResults, bibleProvider);
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          hintText: strings.AppStrings.searchHint,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<BibleProvider>().clearSearchResults();
                    setState(() {});
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        ),
        onChanged: (value) {
          if (value.length >= 2) {
            _performSearch(value);
          } else {
            context.read<BibleProvider>().clearSearchResults();
          }
          setState(() {});
        },
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    return Consumer<BibleProvider>(
      builder: (context, bibleProvider, child) {
        final history = bibleProvider.searchHistory;

        if (history.isEmpty) {
          return _buildInitialSuggestions();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_showHistory) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recente zoekopdrachten',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () => context.read<BibleProvider>().clearSearchHistory(),
                      child: const Text('Wis alles'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final entry = history[index];
                    return ListTile(
                      leading: const Icon(Icons.history),
                      title: Text(entry.query),
                      subtitle: Text('${entry.resultCount} resultaten • ${_formatTime(entry.timestamp)}'),
                      onTap: () => _performSearchFromHistory(entry.query),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => context.read<BibleProvider>().removeFromSearchHistory(entry.query),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildInitialSuggestions() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Zoek in de Bijbel',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Voer minimaal 2 karakters in om te zoeken',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 32),
          _buildQuickSearchSuggestions(),
        ],
      ),
    );
  }

  Widget _buildQuickSearchSuggestions() {
    final suggestions = [
      'Jezus',
      'liefde',
      'genade',
      'geloof',
      'hoop',
      'vrede',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: suggestions.map((suggestion) {
        return ActionChip(
          label: Text(suggestion),
          onPressed: () => _performSearchFromHistory(suggestion),
        );
      }).toList(),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            strings.AppStrings.noResults,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Probeer andere zoektermen of controleer de spelling',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(List<SearchResult> results, BibleProvider bibleProvider) {
    return Column(
      children: [
        if (_showFilters) _buildFiltersSection(bibleProvider),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '${results.length} resultaten voor "${_searchController.text}"',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final result = results[index];
                    return SearchResultItem(
                      result: result,
                      onTap: () => _navigateToVerse(result),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersSection(BibleProvider bibleProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filters',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SearchFilterChips(
            activeFilters: bibleProvider.activeFilters,
            onFiltersChanged: (filters) {
              bibleProvider.applySearchFilters(filters);
            },
          ),
        ],
      ),
    );
  }

  void _performSearch(String query) {
    context.read<BibleProvider>().searchBible(query);
  }

  void _performSearchFromHistory(String query) {
    _searchController.text = query;
    _performSearch(query);
    setState(() {});
  }

  void _navigateToVerse(SearchResult result) {
    // Navigate to the verse in the reader
    // This would need to be implemented based on the existing navigation pattern
    Navigator.of(context).pop(); // Close search screen
    // TODO: Navigate to specific verse in reader
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} dag${difference.inDays > 1 ? 'en' : ''} geleden';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} uur geleden';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} min geleden';
    } else {
      return 'Zojuist';
    }
  }
}