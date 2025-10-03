import 'package:flutter/material.dart';
import '../models/search_result.dart';

/// Widget for displaying and managing search filters
class SearchFilterChips extends StatefulWidget {
  final List<SearchFilter> activeFilters;
  final Function(List<SearchFilter>) onFiltersChanged;

  const SearchFilterChips({
    super.key,
    required this.activeFilters,
    required this.onFiltersChanged,
  });

  @override
  State<SearchFilterChips> createState() => _SearchFilterChipsState();
}

class _SearchFilterChipsState extends State<SearchFilterChips> {
  late List<SearchFilter> _availableFilters;
  late List<SearchFilter> _selectedFilters;

  @override
  void initState() {
    super.initState();
    _selectedFilters = List.from(widget.activeFilters);
    _loadAvailableFilters();
  }

  @override
  void didUpdateWidget(SearchFilterChips oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeFilters != oldWidget.activeFilters) {
      _selectedFilters = List.from(widget.activeFilters);
    }
  }

  Future<void> _loadAvailableFilters() async {
    // Create testament filters
    final testamentFilters = [
      const SearchFilter(
        type: 'testament',
        value: 'old',
        label: 'Oude Testament',
      ),
      const SearchFilter(
        type: 'testament',
        value: 'new',
        label: 'Nieuwe Testament',
      ),
    ];

    // In a real implementation, you would load book filters from the BibleProvider
    // For now, we'll use a few common books as examples
    final bookFilters = [
      const SearchFilter(
        type: 'book',
        value: 'genesis',
        label: 'Genesis',
      ),
      const SearchFilter(
        type: 'book',
        value: 'psalms',
        label: 'Psalmen',
      ),
      const SearchFilter(
        type: 'book',
        value: 'matthew',
        label: 'Mattheüs',
      ),
      const SearchFilter(
        type: 'book',
        value: 'john',
        label: 'Johannes',
      ),
    ];

    setState(() {
      _availableFilters = [...testamentFilters, ...bookFilters];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_availableFilters.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _availableFilters.map((filter) {
        final isSelected = _selectedFilters.contains(filter);

        return FilterChip(
          label: Text(filter.label),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedFilters.add(filter);
              } else {
                _selectedFilters.remove(filter);
              }
            });

            widget.onFiltersChanged(_selectedFilters);
          },
          backgroundColor: Theme.of(context).colorScheme.surface,
          selectedColor: Theme.of(context).colorScheme.primaryContainer,
          checkmarkColor: Theme.of(context).colorScheme.primary,
        );
      }).toList(),
    );
  }
}