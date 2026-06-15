import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'data/activity_catalog.dart';
import 'models/activity_definition.dart';
import 'models/activity_report_entry.dart';
import 'widgets/activity_report_row.dart';
import 'widgets/activity_report_tab_header.dart';
import 'widgets/activity_search_bar.dart';

class ActivityReportPage extends StatefulWidget {
  const ActivityReportPage({super.key});

  @override
  State<ActivityReportPage> createState() => _ActivityReportPageState();
}

class _ActivityReportPageState extends State<ActivityReportPage> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final Map<String, ActivityReportEntry> _entries = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _initDefaultFavorites();
  }

  void _initDefaultFavorites() {
    for (final id in ActivityCatalog.defaultFavoriteIds) {
      final definition = ActivityCatalog.findById(id);
      if (definition == null) continue;
      _entries[id] = ActivityReportEntry(
        definition: definition,
        isFavorite: true,
      );
    }
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() => setState(() {});

  List<ActivityReportEntry> get _visibleEntries {
    final list = _entries.values.where((e) => e.isVisible).toList();
    list.sort((a, b) {
      if (a.isFavorite != b.isFavorite) {
        return a.isFavorite ? -1 : 1;
      }
      return a.name.compareTo(b.name);
    });
    return list;
  }

  List<ActivityDefinition> get _searchResults {
    final query = _searchController.text.trim();
    if (query.isEmpty) return const [];

    final visibleIds = _visibleEntries.map((e) => e.id).toSet();
    return ActivityCatalog.all
        .where(
          (item) =>
              item.name.contains(query) && !visibleIds.contains(item.id),
        )
        .toList();
  }

  ActivityReportEntry _entryFor(ActivityDefinition definition) {
    return _entries.putIfAbsent(
      definition.id,
      () => ActivityReportEntry(definition: definition),
    );
  }

  void _toggleFavorite(String id) {
    setState(() {
      final entry = _entries[id]!;
      entry.isFavorite = !entry.isFavorite;
      if (!entry.isVisible) {
        _entries.remove(id);
      }
    });
  }

  void _addFromSearch(ActivityDefinition definition) {
    setState(() {
      final entry = _entryFor(definition);
      entry.isAdded = true;
      _searchController.clear();
      _searchFocusNode.unfocus();
    });
  }

  void _increment(String id) {
    setState(() => _entries[id]!.count++);
  }

  void _decrement(String id) {
    setState(() {
      final entry = _entries[id]!;
      if (entry.count > 0) entry.count--;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() {});
  }

  void _submit() {
    final reported = _visibleEntries.where((e) => e.count > 0).toList();
    if (reported.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('보고할 활동 횟수를 1개 이상 입력해 주세요.')),
      );
      return;
    }

    final summary = reported.map((e) => '${e.name} ${e.count}회').join(', ');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('쁘레시디움에 제출되었습니다.\n$summary'),
        duration: const Duration(seconds: 3),
      ),
    );

    // TODO: 주 회합 집계 API 연동
    setState(() {
      for (final entry in reported) {
        entry.count = 0;
        if (!entry.isFavorite) {
          entry.isAdded = false;
          _entries.remove(entry.id);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = _searchResults;
    final visibleEntries = _visibleEntries;

    return ColoredBox(
      color: AppColors.backgroundMid,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ActivityReportTabHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: ActivitySearchBar(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: (_) => setState(() {}),
              onClear: _clearSearch,
            ),
          ),
          if (searchResults.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _SearchResultsPanel(
                results: searchResults,
                onSelect: _addFromSearch,
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Text(
                  '보고 목록',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.title,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(width: 6),
                Text(
                  '★ 즐겨찾기는 항상 표시',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.subtitle.withValues(alpha: 0.75),
                      ),
                ),
              ],
            ),
          ),
          Expanded(
            child: visibleEntries.isEmpty
                ? _EmptyReportList(
                    hasSearchQuery: _searchController.text.trim().isNotEmpty,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: visibleEntries.length,
                    itemBuilder: (context, index) {
                      final entry = visibleEntries[index];
                      return ActivityReportRow(
                        entry: entry,
                        onFavoriteToggle: () => _toggleFavorite(entry.id),
                        onIncrement: () => _increment(entry.id),
                        onDecrement: () => _decrement(entry.id),
                      );
                    },
                  ),
          ),
          _SubmitBar(onSubmit: _submit),
        ],
      ),
    );
  }
}

class _SearchResultsPanel extends StatelessWidget {
  const _SearchResultsPanel({
    required this.results,
    required this.onSelect,
  });

  final List<ActivityDefinition> results;
  final ValueChanged<ActivityDefinition> onSelect;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      shadowColor: AppColors.shadow.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(12),
      color: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 220),
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: results.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            color: AppColors.shadow.withValues(alpha: 0.06),
          ),
          itemBuilder: (context, index) {
            final item = results[index];
            return ListTile(
              dense: true,
              title: Text(
                item.name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.title,
                    ),
              ),
              trailing: Icon(
                Icons.add_circle_outline,
                color: AppColors.accent,
                size: 22,
              ),
              onTap: () => onSelect(item),
            );
          },
        ),
      ),
    );
  }
}

class _EmptyReportList extends StatelessWidget {
  const _EmptyReportList({required this.hasSearchQuery});

  final bool hasSearchQuery;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.edit_note_outlined,
              size: 56,
              color: AppColors.accent.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 16),
            Text(
              hasSearchQuery
                  ? '검색 결과에서 활동을 선택해\n보고 목록에 추가하세요.'
                  : '상단 검색으로 활동을 찾아 추가하거나\n★ 즐겨찾기로 항상 표시할 수 있어요.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.subtitle.withValues(alpha: 0.85),
                    height: 1.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubmitBar extends StatelessWidget {
  const _SubmitBar({required this.onSubmit});

  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: AppColors.shadow.withValues(alpha: 0.08),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: onSubmit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '쁘레시디움 제출',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
