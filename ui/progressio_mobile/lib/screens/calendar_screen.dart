import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:progressio_mobile/model/calendar_item.dart';
import 'package:progressio_mobile/providers/calendar_provider.dart';
import 'package:progressio_mobile/utils/app_colors.dart';
import 'package:progressio_mobile/widgets/app_ui.dart';
import 'package:progressio_mobile/widgets/skeleton_loader.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Month view state
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDay;
  List<CalendarItem> _monthItems = [];
  bool _loadingMonth = false;

  // Today view state
  List<CalendarItem> _todayItems = [];
  bool _loadingToday = false;

  // Upcoming view state
  List<CalendarItem> _upcomingItems = [];
  bool _loadingUpcoming = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        switch (_tabController.index) {
          case 0:
            if (_todayItems.isEmpty && !_loadingToday) _loadToday();
            break;
          case 1:
            if (_monthItems.isEmpty && !_loadingMonth) _loadMonth();
            break;
          case 2:
            if (_upcomingItems.isEmpty && !_loadingUpcoming) _loadUpcoming();
            break;
        }
      }
    });
    _loadToday();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadToday() async {
    if (!mounted) return;
    setState(() => _loadingToday = true);
    try {
      final items =
          await context.read<CalendarProvider>().getToday();
      if (mounted) setState(() => _todayItems = items);
    } catch (e) {
      debugPrint('Calendar today error: $e');
    } finally {
      if (mounted) setState(() => _loadingToday = false);
    }
  }

  Future<void> _loadMonth() async {
    if (!mounted) return;
    setState(() => _loadingMonth = true);
    try {
      final items = await context
          .read<CalendarProvider>()
          .getMonth(_focusedMonth.year, _focusedMonth.month);
      if (mounted) setState(() => _monthItems = items);
    } catch (e) {
      debugPrint('Calendar month error: $e');
    } finally {
      if (mounted) setState(() => _loadingMonth = false);
    }
  }

  Future<void> _loadUpcoming() async {
    if (!mounted) return;
    setState(() => _loadingUpcoming = true);
    try {
      final items = await context
          .read<CalendarProvider>()
          .getUpcoming(days: 30);
      if (mounted) setState(() => _upcomingItems = items);
    } catch (e) {
      debugPrint('Calendar upcoming error: $e');
    } finally {
      if (mounted) setState(() => _loadingUpcoming = false);
    }
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth =
          DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
      _monthItems = [];
      _selectedDay = null;
    });
    _loadMonth();
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth =
          DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
      _monthItems = [];
      _selectedDay = null;
    });
    _loadMonth();
  }

  List<CalendarItem> _itemsForDay(DateTime day) {
    return _monthItems.where((item) {
      return item.airDate.year == day.year &&
          item.airDate.month == day.month &&
          item.airDate.day == day.day;
    }).toList();
  }

  List<CalendarItem> get _selectedDayItems {
    if (_selectedDay == null) return [];
    return _itemsForDay(_selectedDay!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text(
          'Calendar',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'Monthly'),
            Tab(text: 'Upcoming'),
          ],
        ),
      ),
      body: AppShellBackground(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildTodayTab(),
            _buildMonthTab(),
            _buildUpcomingTab(),
          ],
        ),
      ),
    );
  }

  // ── TODAY TAB ───────────────────────────────────────────────────────────────

  Widget _buildTodayTab() {
    if (_loadingToday) {
      return ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => const _SkeletonCalendarCard(),
      );
    }

    if (_todayItems.isEmpty) {
      return _buildEmptyState(
        icon: Icons.today_outlined,
        message: 'No releases today.\nCheck back tomorrow!',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadToday,
      color: AppColors.primary,
      backgroundColor: AppColors.card,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: _todayItems.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, i) => _CalendarItemCard(item: _todayItems[i]),
      ),
    );
  }

  // ── MONTH TAB ───────────────────────────────────────────────────────────────

  Widget _buildMonthTab() {
    return RefreshIndicator(
      onRefresh: _loadMonth,
      color: AppColors.primary,
      backgroundColor: AppColors.card,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildMonthHeader()),
          SliverToBoxAdapter(child: _buildCalendarGrid()),
          if (_selectedDay != null) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
                child: Text(
                  _formatDayLabel(_selectedDay!),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (_selectedDayItems.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    'No releases on this day.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CalendarItemCard(item: _selectedDayItems[i]),
                    ),
                    childCount: _selectedDayItems.length,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildMonthHeader() {
    final monthName = _monthNames[_focusedMonth.month - 1];
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon:
                const Icon(Icons.chevron_left, color: AppColors.textSecondary),
            onPressed: _previousMonth,
          ),
          Text(
            '$monthName ${_focusedMonth.year}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right,
                color: AppColors.textSecondary),
            onPressed: _nextMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    if (_loadingMonth) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    // weekday: 1=Mon, 7=Sun — we want Sun-first (0-indexed), shift accordingly
    final startOffset = (firstDay.weekday % 7); // Sun=0,Mon=1,...Sat=6
    final today = DateTime.now();

    final cells = <Widget>[];

    // Day-of-week headers
    for (final d in ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']) {
      cells.add(Center(
        child: Text(d,
            style: const TextStyle(
                color: AppColors.textFaint,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
      ));
    }

    // Empty leading cells
    for (var i = 0; i < startOffset; i++) {
      cells.add(const SizedBox.shrink());
    }

    // Day cells
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
      final hasItems = _itemsForDay(date).isNotEmpty;
      final isToday = date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
      final isSelected = _selectedDay != null &&
          date.year == _selectedDay!.year &&
          date.month == _selectedDay!.month &&
          date.day == _selectedDay!.day;

      cells.add(GestureDetector(
        onTap: () => setState(() {
          _selectedDay = isSelected ? null : date;
        }),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : isToday
                    ? AppColors.primarySoft
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$day',
                style: TextStyle(
                  color: isSelected
                      ? Colors.black
                      : isToday
                          ? AppColors.primary
                          : AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: isToday || isSelected
                      ? FontWeight.w700
                      : FontWeight.w400,
                ),
              ),
              if (hasItems)
                Container(
                  width: 4,
                  height: 4,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.black54 : AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ));
    }

    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1,
        children: cells,
      ),
    );
  }

  // ── UPCOMING TAB ────────────────────────────────────────────────────────────

  Widget _buildUpcomingTab() {
    if (_loadingUpcoming) {
      return ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => const _SkeletonCalendarCard(),
      );
    }

    if (_upcomingItems.isEmpty) {
      return _buildEmptyState(
        icon: Icons.upcoming_outlined,
        message: 'No upcoming releases\nin the next 30 days.',
      );
    }

    // Group by date
    final grouped = <String, List<CalendarItem>>{};
    for (final item in _upcomingItems) {
      final key = _formatDayLabel(item.airDate);
      grouped.putIfAbsent(key, () => []).add(item);
    }

    final keys = grouped.keys.toList();

    return RefreshIndicator(
      onRefresh: _loadUpcoming,
      color: AppColors.primary,
      backgroundColor: AppColors.card,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: keys.length,
        itemBuilder: (ctx, gi) {
          final key = keys[gi];
          final dayItems = grouped[key]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(
                  key,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ...dayItems.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _CalendarItemCard(item: item),
                  )),
              const SizedBox(height: 6),
            ],
          );
        },
      ),
    );
  }

  // ── HELPERS ─────────────────────────────────────────────────────────────────

  Widget _buildEmptyState(
      {required IconData icon, required String message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textFaint, size: 52),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDayLabel(DateTime d) {
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    if (d.year == today.year &&
        d.month == today.month &&
        d.day == today.day) {
      return 'Today';
    }
    if (d.year == tomorrow.year &&
        d.month == tomorrow.month &&
        d.day == tomorrow.day) {
      return 'Tomorrow';
    }
    final monthAbbr = _monthNames[d.month - 1].substring(0, 3);
    return '${_weekdayNames[d.weekday - 1]}, $monthAbbr ${d.day}';
  }

  static const List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static const List<String> _weekdayNames = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];
}

// ── CALENDAR ITEM CARD ───────────────────────────────────────────────────────

class _CalendarItemCard extends StatelessWidget {
  final CalendarItem item;

  const _CalendarItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppDecorations.panel(),
      child: Row(
        children: [
          _buildThumbnail(),
          const SizedBox(width: 12),
          Expanded(child: _buildInfo()),
          _buildTypeDot(),
        ],
      ),
    );
  }

  Widget _buildThumbnail() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 52,
        height: 72,
        child: item.contentTitle.isNotEmpty
            ? Container(
                color: AppColors.surface,
                child: const Icon(Icons.movie_outlined,
                    color: AppColors.textFaint, size: 24),
              )
            : Container(color: AppColors.surface),
      ),
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.contentTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          item.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            if (item.releaseDetails.isNotEmpty) ...[
              _buildChip(item.releaseDetails, AppColors.primarySoft,
                  AppColors.primary),
              const SizedBox(width: 6),
            ],
            if (item.durationMinutes != null)
              _buildChip('${item.durationMinutes}m', AppColors.surfaceElevated,
                  AppColors.textMuted),
          ],
        ),
      ],
    );
  }

  Widget _buildChip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTypeDot() {
    final isEpisode = item.itemType.toLowerCase() == 'episode';
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: isEpisode ? AppColors.info : AppColors.warning,
        shape: BoxShape.circle,
      ),
    );
  }
}

// ── SKELETON ────────────────────────────────────────────────────────────────

class _SkeletonCalendarCard extends StatelessWidget {
  const _SkeletonCalendarCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppDecorations.panel(),
      child: Row(
        children: [
          SkeletonBox(width: 52, height: 72, radius: 8),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonBox(width: 80, height: 11),
                SizedBox(height: 6),
                SkeletonBox(width: 160, height: 14),
                SizedBox(height: 6),
                SkeletonBox(width: 60, height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}