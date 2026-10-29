import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import 'notice_detail_page.dart';
import 'notice_form_page.dart';
import 'notice_service.dart';
import 'notice_tile.dart';

/// 공지사항 전체 (최신순, 무한 스크롤). 4간부는 등록할 수 있다.
class NoticeListPage extends StatefulWidget {
  const NoticeListPage({super.key, required this.canManage});

  final bool canManage;

  @override
  State<NoticeListPage> createState() => _NoticeListPageState();
}

class _NoticeListPageState extends State<NoticeListPage> {
  static const _pageSize = 20;

  final _service = const NoticeService();
  final _scrollController = ScrollController();
  final List<Notice> _items = [];

  int _nextPage = 0;
  bool _hasNext = true;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.extentAfter < 400) _loadMore();
    });
    _reload();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    try {
      final page = await _service.fetchPage(page: 0, size: _pageSize);
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(page.items);
        _nextPage = 1;
        _hasNext = page.hasNext;
        _isLoading = false;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.message;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasNext) return;
    setState(() => _isLoadingMore = true);
    try {
      final page = await _service.fetchPage(page: _nextPage, size: _pageSize);
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _nextPage++;
        _hasNext = page.hasNext;
      });
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _openDetail(Notice notice) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => NoticeDetailPage(notice: notice, canManage: widget.canManage)),
    );
    if (changed == true) await _reload();
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<Notice>(
      MaterialPageRoute(builder: (_) => const NoticeFormPage()),
    );
    if (created != null) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundMid,
      appBar: AppBar(title: const Text('공지사항')),
      floatingActionButton: widget.canManage
          ? FloatingActionButton.extended(
              onPressed: _openCreate,
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('공지 등록'),
            )
          : null,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(32), child: Text(_error!)));
    }

    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        itemCount: _items.isEmpty ? 1 : _items.length + 1,
        separatorBuilder: (context, index) => Divider(height: 1, color: AppColors.shadow.withValues(alpha: 0.1)),
        itemBuilder: (context, index) {
          if (_items.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 80),
              child: Text(
                widget.canManage ? '공지사항이 없어요.\n아래 「공지 등록」으로 공지를 올려 보세요.' : '공지사항이 없어요.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.subtitle, height: 1.5),
              ),
            );
          }
          if (index == _items.length) {
            return _isLoadingMore
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
                  )
                : const SizedBox(height: 8);
          }
          final notice = _items[index];
          return NoticeTile(notice: notice, showPreview: true, onTap: () => _openDetail(notice));
        },
      ),
    );
  }
}
