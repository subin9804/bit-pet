import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_input_styles.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/confirm_modal.dart';
import '../../../core/widgets/month_grid_calendar.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/toast_message.dart';
import '../data/models/feed_models.dart';
import '../providers/feed_provider.dart';
import '../providers/record_provider.dart';
import 'widgets/feed_items_editor.dart';
import '../../pet/providers/pet_provider.dart';

// ── 먹이 종류 → 색상 매핑 ──────────────────────────────────
const _foodColorKey = {
  '귀뚜라미': 'coral',
  '슈퍼웜':   'sage',
  '밀웜':     'butter',
  '버터웜':   'sky',
  '핑키마우스':'lilac',
};

const _foodDot = {
  'coral':  AppColors.petCoralInk,
  'sage':   AppColors.petSageInk,
  'butter': AppColors.petButterInk,
  'sky':    AppColors.petSkyInk,
  'lilac':  AppColors.petLilacInk,
};

const _foodChip = {
  'coral':  AppColors.petCoral,
  'sage':   AppColors.petSage,
  'butter': AppColors.petButter,
  'sky':    AppColors.petSky,
  'lilac':  AppColors.petLilac,
};

Color _dotColor(String food) =>
    _foodDot[_foodColorKey[food] ?? 'sage'] ?? AppColors.petSageInk;
Color _chipColor(String food) =>
    _foodChip[_foodColorKey[food] ?? 'sage'] ?? AppColors.petSage;

const _foods = ['귀뚜라미', '슈퍼웜', '밀웜', '버터웜', '핑키마우스'];
const _weekKo = ['일','월','화','수','목','금','토'];

// ── 메인 화면 ───────────────────────────────────────────────
class FeedDetailScreen extends ConsumerStatefulWidget {
  final int petId;
  const FeedDetailScreen({super.key, required this.petId});

  @override
  ConsumerState<FeedDetailScreen> createState() => _FeedDetailScreenState();
}

class _FeedDetailScreenState extends ConsumerState<FeedDetailScreen> {
  int _tabIndex = 0; // 0: 캘린더, 1: 리스트
  FeedEditorState? _editor;

  void _openAdd(String? date) {
    final sorted = ref
        .read(sortedFeedSessionsProvider(widget.petId))
        .whenOrNull(data: (l) => l);
    final defaultDate = date ??
        (sorted != null && sorted.isNotEmpty
            ? _shiftDate(sorted.first.date, 1)
            : _todayIso());
    setState(() {
      _editor = FeedEditorState(
        isEdit: false, editId: null,
        date: defaultDate, time: '21:00',
        items: [], memo: '',
      );
    });
  }

  void _openEdit(FeedSession s) {
    setState(() {
      _editor = FeedEditorState(
        isEdit: true, editId: s.id,
        date: s.date, time: s.time,
        items: List.from(s.items), memo: s.memo,
      );
    });
  }

  Future<void> _save() async {
    final e = _editor;
    if (e == null || e.items.isEmpty) return;
    final notifier = ref.read(feedSessionsProvider(widget.petId).notifier);
    if (e.isEdit && e.editId != null) {
      await notifier.update(FeedSession(
        id: e.editId!, date: e.date, time: e.time,
        items: e.items, memo: e.memo,
      ));
    } else {
      await notifier.add(FeedSession(
        id: '', date: e.date, time: e.time,
        items: e.items, memo: e.memo,
      ));
    }
    if (mounted) {
      setState(() => _editor = null);
      showToast(context,
          e.isEdit ? '수정되었습니다.' : '기록이 추가되었습니다.',
          type: ToastType.success);
    }
  }

  Future<void> _delete(String id) async {
    final ok = await ConfirmModal.show(
      context,
      title: '기록 삭제',
      message: '이 급여 기록을 삭제할까요?\n삭제하면 복구할 수 없습니다.',
      confirmLabel: '삭제',
      isDangerous: true,
    );
    if (!ok) return;
    try {
      await ref.read(feedSessionsProvider(widget.petId).notifier).delete(id);
      ref.invalidate(petCalendarProvider);
      if (mounted) {
        setState(() => _editor = null);
        showToast(context, '기록이 삭제되었습니다.', type: ToastType.info);
      }
    } catch (e) {
      if (mounted) showToast(context, '삭제 실패: $e', type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final petAsync     = ref.watch(petDetailProvider(widget.petId));
    final sessionsAsync = ref.watch(sortedFeedSessionsProvider(widget.petId));
    final petName = petAsync.whenOrNull(data: (p) => p.name) ?? '';

    return Scaffold(
      backgroundColor: AppColors.paleBg,
      body: Stack(
        children: [
          Column(
            children: [
              // TopBar
              SafeArea(
                bottom: false,
                child: _TopBar(
                  onBack:  () => context.pop(),
                  petName: petName,
                  onAdd:   () => _openAdd(null),
                ),
              ),
              // 세그먼트 탭
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 2, 22, 12),
                child: _FeedSegment(
                  index: _tabIndex,
                  onChanged: (i) => setState(() => _tabIndex = i),
                ),
              ),
              // 본문
              Expanded(
                child: sessionsAsync.when(
                  loading: () => const SkeletonCardList(),
                  error:   (e, _) => Center(child: Text(e.toString())),
                  data:    (sessions) => _tabIndex == 0
                      ? _CalendarView(
                          sessions: sessions,
                          onEdit:   _openEdit,
                          onAdd:    _openAdd,
                        )
                      : _ListView(
                          sessions: sessions,
                          onEdit:   _openEdit,
                        ),
                ),
              ),
            ],
          ),

          // 편집 시트 오버레이
          if (_editor != null)
            FeedEditorSheet(
              editor:    _editor!,
              onChanged: (e) => setState(() => _editor = e),
              onSave:    _save,
              onDelete:  _delete,
              onClose:   () => setState(() => _editor = null),
            ),
        ],
      ),
    );
  }

  static String _todayIso() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
  }

  static String _shiftDate(String iso, int days) {
    final parts = iso.split('-').map(int.parse).toList();
    final dt = DateTime(parts[0], parts[1], parts[2] + days);
    return '${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')}';
  }
}

// ── TopBar ──────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  final String petName;
  final VoidCallback onAdd;

  const _TopBar({required this.onBack, required this.petName, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.card,
                border: Border.all(color: AppColors.paleLine),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  size: 16, color: AppColors.primary),
            ),
          ),
          const Spacer(),
          Column(children: [
            const Text('급여 기록',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                    color: AppColors.primary, letterSpacing: -0.2)),
            if (petName.isNotEmpty)
              Text(petName.toUpperCase(), style: AppTextStyles.monoXs),
          ]),
          const Spacer(),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              height: 36, padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.zero,
              ),
              child: Row(
                children: [
                  const Icon(Icons.add, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text('기록',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                          color: AppColors.paleBg)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 세그먼트 (캘린더/리스트) ──────────────────────────────────
class _FeedSegment extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const _FeedSegment({required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paleBgAlt,
        borderRadius: BorderRadius.zero,
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _Tab(label: '캘린더', icon: Icons.calendar_today_outlined,
              active: index == 0, onTap: () => onChanged(0)),
          const SizedBox(width: 4),
          _Tab(label: '리스트', icon: Icons.list_outlined,
              active: index == 1, onTap: () => onChanged(1)),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _Tab({required this.label, required this.icon,
      required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? AppColors.card : Colors.transparent,
            border: active ? Border.all(color: AppColors.paleLine) : null,
            borderRadius: BorderRadius.zero,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16,
                  color: active ? AppColors.primary : AppColors.paleInk3),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: active ? AppColors.primary : AppColors.paleInk2)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 세션 카드 (캘린더·리스트 공용) ──────────────────────────
class SessionCard extends StatelessWidget {
  final FeedSession session;
  final VoidCallback onEdit;
  final bool showDate;

  const SessionCard({
    super.key,
    required this.session,
    required this.onEdit,
    this.showDate = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.paleLine),
        borderRadius: BorderRadius.zero,
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 날짜 컬럼
          if (showDate)
            SizedBox(
              width: 42,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    session.date.substring(8), // dd
                    style: AppTextStyles.monoBody,
                  ),
                  Text(
                    '${int.parse(session.date.substring(5,7))}월',
                    style: AppTextStyles.monoXxs,
                  ),
                  const SizedBox(height: 3),
                  Text(session.time, style: AppTextStyles.monoXxs),
                ],
              ),
            ),
          if (showDate) const SizedBox(width: 12),
          // 아이템 목록
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...session.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 8, height: 8,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: _dotColor(item.food),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(item.detail,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600,
                                color: AppColors.primary)),
                      ),
                    ],
                  ),
                )),
                if (session.memo.isNotEmpty)
                  Text(session.memo,
                      style: TextStyle(
                          fontSize: 12, color: AppColors.paleInk2)),
              ],
            ),
          ),
          // 수정 버튼
          GestureDetector(
            onTap: onEdit,
            child: Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: AppColors.paleBg,
                border: Border.all(color: AppColors.paleLine),
                borderRadius: BorderRadius.zero,
              ),
              child: const Icon(Icons.edit_outlined,
                  size: 14, color: AppColors.paleInk2),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 캘린더 뷰 ───────────────────────────────────────────────
class _CalendarView extends StatefulWidget {
  final List<FeedSession> sessions;
  final ValueChanged<FeedSession> onEdit;
  final ValueChanged<String?> onAdd;

  const _CalendarView({
    required this.sessions, required this.onEdit, required this.onAdd});

  @override
  State<_CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<_CalendarView> {
  // 진입 시엔 항상 **이번 달 / 오늘**. 기록이 있는 마지막 달로 점프하지 않는다
  // — 대부분의 진입 목적이 "오늘 뭐 줬더라 / 오늘 기록 남기기" 이기 때문.
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  late String _selDate = todayIso();

  List<FeedSession> get _monthSessions =>
      widget.sessions.where((s) => s.date.startsWith(_ymStr)).toList();

  Map<String, List<FeedSession>> get _byDate {
    final map = <String, List<FeedSession>>{};
    for (final s in _monthSessions) {
      map.putIfAbsent(s.date, () => []).add(s);
    }
    return map;
  }

  String get _ymStr =>
      '${_month.year}-${_month.month.toString().padLeft(2,'0')}';

  /// 셀 안에 들어갈 급여 요약. 기록이 없으면 null.
  Widget? _cellContent(Map<String, List<FeedSession>> byDate, String date) {
    final recs = byDate[date];
    if (recs == null || recs.isEmpty) return null;
    final items = recs.expand((s) => s.items).toList();
    if (items.isEmpty) return null;
    const maxLines = 3;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final it in items.take(maxLines))
          CalendarCellLine(
            dotColor: it.isRefused ? AppColors.paleInk3 : _dotColor(it.food),
            label: it.isRefused
                ? '거식'
                : (it.amt > 1 ? '${it.food} ${it.amt}' : it.food),
            muted: it.isRefused,
          ),
        if (items.length > maxLines) CalendarCellMore(items.length - maxLines),
      ],
    );
  }

  void _openDaySheet(String date, List<FeedSession> recs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _DaySheet(
        date: date,
        sessions: recs,
        // 편집 오버레이는 이 화면(Stack) 소유라, 시트를 먼저 닫고 띄운다
        onEdit: (s) {
          Navigator.pop(sheetCtx);
          widget.onEdit(s);
        },
        onAdd: () {
          Navigator.pop(sheetCtx);
          widget.onAdd(date);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final byDate = _byDate;
    return Column(
      children: [
        Expanded(
          child: MonthGridCalendar(
            month: _month,
            selectedDate: _selDate,
            monthSummary: '${_monthSessions.length}회 급여',
            accent: AppColors.petButter,
            onMonthChanged: (m) => setState(() => _month = m),
            onDayTap: (ds) {
              setState(() => _selDate = ds);
              _openDaySheet(ds, byDate[ds] ?? const []);
            },
            cellBuilder: (ds) => _cellContent(byDate, ds),
          ),
        ),
        // 범례 — 셀이 좁아 라벨이 잘릴 때 색으로 구분할 수 있게 남겨둔다
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: AppColors.paleBgAlt,
            border: Border(top: BorderSide(color: AppColors.paleLine)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _foods.map((f) => Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: _dotColor(f), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    Text(f, style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        color: AppColors.paleInk2)),
                  ],
                ),
              )).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

// ── 날짜별 상세 바텀시트 ─────────────────────────────────────
class _DaySheet extends StatelessWidget {
  final String date;
  final List<FeedSession> sessions;
  final ValueChanged<FeedSession> onEdit;
  final VoidCallback onAdd;

  const _DaySheet({
    required this.date,
    required this.sessions,
    required this.onEdit,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: sessions.isEmpty ? 0.34 : 0.55,
      minChildSize: 0.28,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.paleBg,
          border: Border(top: BorderSide(color: AppColors.paleLine, width: 1.5)),
        ),
        child: Column(
          children: [
            // 핸들
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              color: AppColors.paleLine,
            ),
            // 헤더
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: TextSpan(
                      style: AppTextStyles.paleSectionTitle,
                      children: [
                        TextSpan(text:
                          '${int.parse(date.substring(5,7))}.${int.parse(date.substring(8))} '),
                        TextSpan(
                          text: '(${_weekKo[DateTime.parse(date).weekday % 7]})',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.paleInk2),
                        ),
                      ],
                    ),
                  ),
                  Text('${sessions.length}회', style: AppTextStyles.monoSm),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
                children: [
                  if (sessions.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 22),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.paleLine, width: 1.5),
                        borderRadius: BorderRadius.zero,
                      ),
                      child: const Text('이 날의 급여 기록이 없어요',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.paleInk3)),
                    )
                  else
                    ...sessions.map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: SessionCard(
                              session: s,
                              onEdit: () => onEdit(s),
                              showDate: false),
                        )),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: onAdd,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        border: Border.all(color: AppColors.paleLine),
                        borderRadius: BorderRadius.zero,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, size: 16, color: AppColors.primary),
                          SizedBox(width: 6),
                          Text('이 날 기록 추가',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700,
                                  color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 리스트 뷰 (무한 스크롤) ──────────────────────────────────
class _ListView extends StatefulWidget {
  final List<FeedSession> sessions;
  final ValueChanged<FeedSession> onEdit;

  const _ListView({required this.sessions, required this.onEdit});

  @override
  State<_ListView> createState() => _ListViewState();
}

class _ListViewState extends State<_ListView> {
  static const _page = 8;
  int _count = _page;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 120) {
      setState(() => _count =
          (_count + _page).clamp(0, widget.sessions.length));
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = widget.sessions.take(_count).toList();

    // 월 구분선 삽입
    final items = <_ListItem>[];
    String? lastMonth;
    for (final s in visible) {
      final mk = s.date.substring(0, 7);
      if (mk != lastMonth) {
        items.add(_ListItem.month(mk));
        lastMonth = mk;
      }
      items.add(_ListItem.session(s));
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 110),
      itemCount: items.length + 1, // +1 footer
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('전체 급여 기록',
                    style: AppTextStyles.paleSectionTitle),
                Text('${widget.sessions.length}회',
                    style: AppTextStyles.monoSm),
              ],
            ),
          );
        }
        final item = items[i - 1];
        if (item.isMonth) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(2, 8, 2, 2),
            child: Row(
              children: [
                Text(
                  item.monthKey!.replaceAll('-', '.'),
                  style: AppTextStyles.monoSm,
                ),
                const SizedBox(width: 10),
                Expanded(child: Container(height: 1,
                    color: AppColors.paleLineSoft)),
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SessionCard(
            session: item.session!,
            onEdit: () => widget.onEdit(item.session!),
          ),
        );
      },
    );
  }
}

class _ListItem {
  final bool isMonth;
  final String? monthKey;
  final FeedSession? session;

  const _ListItem._({this.isMonth = false, this.monthKey, this.session});

  factory _ListItem.month(String key) =>
      _ListItem._(isMonth: true, monthKey: key);
  factory _ListItem.session(FeedSession s) =>
      _ListItem._(session: s);
}

// ── 편집 바텀시트 ────────────────────────────────────────────
class FeedEditorSheet extends StatefulWidget {
  final FeedEditorState editor;
  final ValueChanged<FeedEditorState> onChanged;
  final VoidCallback onSave;
  final ValueChanged<String> onDelete;
  final VoidCallback onClose;

  const FeedEditorSheet({
    super.key,
    required this.editor,
    required this.onChanged,
    required this.onSave,
    required this.onDelete,
    required this.onClose,
  });

  @override
  State<FeedEditorSheet> createState() => _FeedEditorSheetState();
}

class _FeedEditorSheetState extends State<FeedEditorSheet> {
  final _memoCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _memoCtrl.text = widget.editor.memo;
  }

  @override
  void dispose() {
    _memoCtrl.dispose();
    super.dispose();
  }

  void _shiftDate(int days) {
    final parts = widget.editor.date.split('-').map(int.parse).toList();
    final dt = DateTime(parts[0], parts[1], parts[2] + days);
    widget.onChanged(widget.editor.copyWith(
      date: '${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')}',
    ));
  }

  @override
  Widget build(BuildContext context) {
    final e   = widget.editor;
    final dt  = DateTime.parse(e.date);

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          GestureDetector(
            onTap: widget.onClose,
            child: Container(color: Colors.black.withValues(alpha: 0.45)),
          ),
          Positioned(
            left: 0, right: 0, bottom: 0,
            top: 70,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 1, end: 0),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              builder: (context, t, child) =>
                  FractionalTranslation(translation: Offset(0, t), child: child),
              child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: Container(
              decoration: const BoxDecoration(
                color: AppColors.paleBg,
                border: Border(top: BorderSide(color: AppColors.paleLine)),
              ),
              child: Column(
                children: [
                  // drag handle
                  Container(
                    width: 44, height: 4, margin: const EdgeInsets.only(top: 8, bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.paleLine,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // 헤더 + 날짜 스테퍼
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 2, 22, 12),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              e.isEdit ? '급여 기록 수정' : '급여 기록 추가',
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w700,
                                  color: AppColors.primary, letterSpacing: -0.4),
                            ),
                            GestureDetector(
                              onTap: widget.onClose,
                              child: Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.card,
                                  border: Border.all(color: AppColors.paleLine),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close,
                                    size: 16, color: AppColors.paleInk2),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // 날짜 스테퍼
                        Row(
                          children: [
                            AppNavButton(onTap: () => _shiftDate(-1)),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 9),
                                decoration: BoxDecoration(
                                  color: AppColors.card,
                                  border: Border.all(color: AppColors.paleLine),
                                  borderRadius: BorderRadius.zero,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      e.date.replaceAll('-', '.'),
                                      style: AppTextStyles.mono(14, FontWeight.w700),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '(${_weekKo[dt.weekday % 7]})',
                                      style: TextStyle(
                                          fontSize: 12, fontWeight: FontWeight.w600,
                                          color: AppColors.paleInk2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            AppNavButton(forward: true, onTap: () => _shiftDate(1)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // 스크롤 본문
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                          22, 4, 22,
                          MediaQuery.of(context).viewInsets.bottom + 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 공용 리치 컴포저 (FAB·루틴 완료와 동일 폼)
                          FeedItemsEditor(
                            items: e.items.map((i) => i.toForm()).toList(),
                            bandColor: _chipColor('귀뚜라미'),
                            onChanged: (forms) => widget.onChanged(
                              e.copyWith(
                                items: forms.map(FeedItem.fromForm).toList(),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),
                          // 메모
                          Row(
                            children: [
                              const Text('메모',
                                  style: TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.w700,
                                      color: AppColors.primary)),
                              const SizedBox(width: 6),
                              Text('OPTIONAL',
                                  style: AppTextStyles.monoXxs),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _memoCtrl,
                            onChanged: (v) => widget.onChanged(
                                e.copyWith(memo: v)),
                            maxLines: 2,
                            decoration: AppInputStyles.textarea(
                              hintText: '예: 1마리 남김 · 식욕 좋음 · 더스팅',
                            ),
                          ),

                          // 삭제 버튼 (수정 모드)
                          if (e.isEdit && e.editId != null) ...[
                            const SizedBox(height: 14),
                            GestureDetector(
                              onTap: () => widget.onDelete(e.editId!),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: const Color(0x66E53935)),
                                  borderRadius: BorderRadius.zero,
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.delete_outline,
                                        size: 16, color: AppColors.error),
                                    SizedBox(width: 6),
                                    Text('이 기록 삭제',
                                        style: TextStyle(
                                            fontSize: 13, fontWeight: FontWeight.w700,
                                            color: AppColors.error)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  // 푸터
                  Container(
                    padding: EdgeInsets.fromLTRB(
                        22, 12, 22,
                        MediaQuery.of(context).padding.bottom + 12),
                    decoration: const BoxDecoration(
                      color: AppColors.paleBg,
                      border: Border(
                          top: BorderSide(color: AppColors.paleLineSoft)),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: widget.onClose,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              border: Border.all(color: AppColors.paleLine),
                              borderRadius: BorderRadius.zero,
                            ),
                            child: const Text('취소',
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w700,
                                    color: AppColors.primary)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: e.items.isEmpty ? null : widget.onSave,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: e.items.isEmpty
                                    ? AppColors.paleLine
                                    : AppColors.primary,
                                borderRadius: BorderRadius.zero,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check,
                                      size: 16,
                                      color: e.items.isEmpty
                                          ? AppColors.paleInk3
                                          : AppColors.paleBg),
                                  const SizedBox(width: 8),
                                  Text(
                                    e.isEdit ? '수정 완료' : '저장',
                                    style: TextStyle(
                                        fontSize: 14, fontWeight: FontWeight.w700,
                                        color: e.items.isEmpty
                                            ? AppColors.paleInk3
                                            : AppColors.paleBg),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ),
            ),
          ),
        ],
      ),
    );
  }
}

