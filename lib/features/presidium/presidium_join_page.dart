import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/angela_page_background.dart';
import 'models/curia_item.dart';
import 'models/parish_summary.dart';
import 'models/presidium_item.dart';
import 'presidium_service.dart';
import 'widgets/create_presidium_sheet.dart';
import 'widgets/parish_search_bar.dart';

class PresidiumJoinPage extends StatefulWidget {
  const PresidiumJoinPage({super.key});

  @override
  State<PresidiumJoinPage> createState() => _PresidiumJoinPageState();
}

class _PresidiumJoinPageState extends State<PresidiumJoinPage> {
  final _service = const PresidiumService();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  Timer? _debounce;
  ParishSummary? _selectedParish;
  List<ParishSummary> _searchResults = const [];
  List<PresidiumItem> _presidiums = const [];
  List<CuriaItem> _curias = const [];

  bool _isSearching = false;
  bool _isLoadingList = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
    _debounce?.cancel();
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() => _searchResults = const []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _runSearch(query));
  }

  Future<void> _runSearch(String query) async {
    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });
    try {
      final results = await _service.searchParishes(query);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } on PresidiumServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _searchResults = const [];
        _isSearching = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searchResults = const [];
        _isSearching = false;
        _errorMessage = '본당 검색 중 오류가 발생했습니다.';
      });
    }
  }

  Future<void> _selectParish(ParishSummary parish) async {
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() {
      _selectedParish = parish;
      _searchResults = const [];
      _isLoadingList = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _service.listByParish(parish.id),
        _service.listCurias(parish.id),
      ]);
      if (!mounted) return;
      setState(() {
        _presidiums = results[0] as List<PresidiumItem>;
        _curias = results[1] as List<CuriaItem>;
        _isLoadingList = false;
      });
    } on PresidiumServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _presidiums = const [];
        _curias = const [];
        _isLoadingList = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _presidiums = const [];
        _curias = const [];
        _isLoadingList = false;
        _errorMessage = '쁘레시디움 목록을 불러오지 못했습니다.';
      });
    }
  }

  Future<void> _openCreateSheet() async {
    final parish = _selectedParish;
    if (parish == null) return;

    final joined = await showCreatePresidiumSheet(
      context: context,
      parish: parish,
      curias: _curias,
      service: _service,
    );
    if (!mounted || joined == null) return;

    Navigator.of(context).pop(joined);
  }

  Future<void> _joinPresidium(PresidiumItem item) async {
    try {
      final joined = await _service.joinPresidium(item.id);
      if (!mounted) return;
      Navigator.of(context).pop(joined);
    } on PresidiumServiceException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('쁘레시디움 가입에 실패했습니다.')),
      );
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() => _searchResults = const []);
  }

  @override
  Widget build(BuildContext context) {
    final showSearchResults =
        _selectedParish == null && _searchController.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('쁘레시디움 가입'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.title,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: AngelaPageBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: ParishSearchBar(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onClear: _clearSearch,
                ),
              ),
              if (_selectedParish != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _SelectedParishChip(
                    parish: _selectedParish!,
                    onClear: () => setState(() {
                      _selectedParish = null;
                      _presidiums = const [];
                      _curias = const [];
                    }),
                  ),
                ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Color(0xFFD9534F), fontSize: 13),
                  ),
                ),
              Expanded(
                child: _buildBody(showSearchResults),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _selectedParish == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _openCreateSheet,
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Pr 만들기'),
            ),
    );
  }

  Widget _buildBody(bool showSearchResults) {
    if (showSearchResults) {
      if (_isSearching) {
        return const Center(child: CircularProgressIndicator());
      }
      if (_searchResults.isEmpty) {
        return Center(
          child: Text(
            '검색 결과가 없습니다.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.subtitle,
                ),
          ),
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        itemCount: _searchResults.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final parish = _searchResults[index];
          return _ParishResultTile(
            parish: parish,
            onTap: () => _selectParish(parish),
          );
        },
      );
    }

    if (_selectedParish == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            '소속 본당을 검색해 주세요.\n본당을 선택하면 쁘레시디움 목록이 표시됩니다.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.subtitle.withValues(alpha: 0.85),
                  height: 1.5,
                ),
          ),
        ),
      );
    }

    if (_isLoadingList) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_presidiums.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.groups_outlined,
                size: 56,
                color: AppColors.accent.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 16),
              Text(
                '등록된 쁘레시디움이 없어요',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.title,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '아래 Pr 만들기 버튼으로\n새 쁘레시디움을 등록할 수 있어요.',
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

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 88),
      itemCount: _presidiums.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = _presidiums[index];
        return _PresidiumListTile(
          item: item,
          onTap: () => _joinPresidium(item),
        );
      },
    );
  }
}

class _SelectedParishChip extends StatelessWidget {
  const _SelectedParishChip({required this.parish, required this.onClear});

  final ParishSummary parish;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.church_outlined, size: 20, color: AppColors.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              parish.displayLabel,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.title,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.close, size: 20),
            color: AppColors.subtitle,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _ParishResultTile extends StatelessWidget {
  const _ParishResultTile({required this.parish, required this.onTap});

  final ParishSummary parish;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      parish.name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.title,
                          ),
                    ),
                    if (parish.districtName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        parish.districtName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.subtitle,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.subtitle.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PresidiumListTile extends StatelessWidget {
  const _PresidiumListTile({required this.item, required this.onTap});

  final PresidiumItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.title,
                          height: 1.35,
                        ),
                    children: [
                      TextSpan(
                        text: item.curiaName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(
                        text: ' Cu > ',
                        style: TextStyle(
                          color: AppColors.subtitle.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text: item.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text: ' Pr',
                        style: TextStyle(
                          color: AppColors.subtitle.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Text(
                '${item.sessionNumber}차',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
