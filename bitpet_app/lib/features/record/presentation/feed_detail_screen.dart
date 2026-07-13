import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_input_styles.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/toast_message.dart';
import '../data/models/feed_models.dart';
import '../providers/feed_provider.dart';
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
    await ref.read(feedSessionsProvider(widget.petId).notifier).delete(id);
    if (mounted) {
      setState(() => _editor = null);
      showToast(context, '기록이 삭제되었습니다.', type: ToastType.info);
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
            const Text('피딩 기록',
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
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          color: _dotColor(item.food),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(item.food,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600,
                                color: AppColors.primary)),
                      ),
                      Text(
                        '×${item.amt}',
                        style: AppTextStyles.monoBody,
                      ),
                      Text(' 마리',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.paleInk2)),
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
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  String? _selDate;

  @override
  void initState() {
    super.initState();
    // 가장 최근 달로 초기화
    if (widget.sessions.isNotEmpty) {
      final d = widget.sessions.first.date;
      _month = DateTime(int.parse(d.substring(0,4)), int.parse(d.substring(5,7)));
    }
  }

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

  String get _selOrLatest {
    if (_selDate != null && _selDate!.startsWith(_ymStr)) return _selDate!;
    final dates = _byDate.keys.toList()..sort();
    if (dates.isEmpty) return '$_ymStr-01';
    return dates.last;
  }

  @override
  Widget build(BuildContext context) {
    final byDate    = _byDate;
    final selDate   = _selOrLatest;
    final selRecs   = byDate[selDate] ?? [];
    final monthCount = _monthSessions.length;
    final firstWD   = DateTime(_month.year, _month.month, 1).weekday % 7;
    final dim       = DateTime(_month.year, _month.month + 1, 0).day;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 캘린더 카드
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              border: Border.all(color: AppColors.paleLine),
              borderRadius: BorderRadius.zero,
            ),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              children: [
                // 월 이동
                Row(
                  children: [
                    AppNavButton(
                      onTap: () => setState(() =>
                          _month = DateTime(_month.year, _month.month - 1)),
                    ),
                    const Spacer(),
                    Column(children: [
                      Text(
                        '${_month.year}.${_month.month.toString().padLeft(2,'0')}',
                        style: AppTextStyles.mono(15, FontWeight.w700),
                      ),
                      Text('$monthCount회 피딩', style: AppTextStyles.monoXxs),
                    ]),
                    const Spacer(),
                    AppNavButton(
                      forward: true,
                      onTap: () => setState(() =>
                          _month = DateTime(_month.year, _month.month + 1)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // 요일 헤더
                Row(
                  children: List.generate(7, (i) => Expanded(
                    child: Text(
                      _weekKo[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: i == 0
                            ? AppColors.petCoralInk
                            : i == 6 ? AppColors.petSkyInk : AppColors.paleInk3,
                      ),
                    ),
                  )),
                ),
                const SizedBox(height: 4),
                // 날짜 그리드
                ...() {
                  final cells = [
                    ...List.generate(firstWD, (_) => null),
                    ...List.generate(dim, (i) => i + 1),
                  ];
                  final rows = <Widget>[];
                  for (int r = 0; r < (cells.length / 7).ceil(); r++) {
                    rows.add(Row(
                      children: List.generate(7, (c) {
                        final idx = r * 7 + c;
                        if (idx >= cells.length || cells[idx] == null) {
                          return const Expanded(child: SizedBox(height: 42));
                        }
                        final d   = cells[idx]!;
                        final ds  = '$_ymStr-${d.toString().padLeft(2,'0')}';
                        final sel = ds == selDate;
                        final recs = byDate[ds] ?? [];
                        final foods = recs.expand((s) => s.items.map((i) => i.food))
                            .toSet().take(3).toList();
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selDate = ds),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Column(
                                children: [
                                  Container(
                                    width: 30, height: 30,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: sel
                                          ? AppColors.primary
                                          : recs.isNotEmpty
                                              ? AppColors.paleBgAlt
                                              : Colors.transparent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '$d',
                                      style: AppTextStyles.mono(
                                        13, sel ? FontWeight.w700 : FontWeight.w600,
                                        color: sel
                                            ? AppColors.paleBg
                                            : AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  SizedBox(
                                    height: 5,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: foods.map((f) => Container(
                                        width: 4, height: 4,
                                        margin: const EdgeInsets.symmetric(horizontal: 1),
                                        decoration: BoxDecoration(
                                          color: _dotColor(f),
                                          borderRadius: BorderRadius.zero,
                                        ),
                                      )).toList(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ));
                  }
                  return rows;
                }(),

                // 범례
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12, runSpacing: 6,
                  children: _foods.map((f) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          color: _dotColor(f), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Text(f, style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600,
                          color: AppColors.paleInk2)),
                    ],
                  )).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 선택일 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  style: AppTextStyles.paleSectionTitle,
                  children: [
                    TextSpan(text:
                      '${int.parse(selDate.substring(5,7))}.${int.parse(selDate.substring(8))} '),
                    TextSpan(
                      text: '(${_weekKo[DateTime.parse(selDate).weekday % 7]})',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.paleInk2),
                    ),
                  ],
                ),
              ),
              Text('${selRecs.length}회',
                  style: AppTextStyles.monoSm),
            ],
          ),
          const SizedBox(height: 10),

          // 선택일 세션 목록
          if (selRecs.isEmpty)
            GestureDetector(
              onTap: () => widget.onAdd(selDate),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 22),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.paleLine, width: 1.5,
                      style: BorderStyle.solid),
                  borderRadius: BorderRadius.zero,
                ),
                child: Column(
                  children: [
                    Text('이 날의 피딩 기록이 없어요',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                            color: AppColors.paleInk3)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.paleBgAlt,
                        borderRadius: BorderRadius.zero,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add, size: 14, color: AppColors.primary),
                          const SizedBox(width: 5),
                          const Text('기록 추가',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700,
                                  color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            ...selRecs.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SessionCard(
                session: s, onEdit: () => widget.onEdit(s), showDate: false),
            )),
            GestureDetector(
              onTap: () => widget.onAdd(selDate),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  border: Border.all(color: AppColors.paleLine,
                      style: BorderStyle.solid),
                  borderRadius: BorderRadius.zero,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add, size: 16, color: AppColors.paleInk2),
                    const SizedBox(width: 6),
                    Text('이 날 기록 더 추가',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700,
                            color: AppColors.paleInk2)),
                  ],
                ),
              ),
            ),
          ],
        ],
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
                Text('전체 피딩 기록',
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
  String _draftFood = '귀뚜라미';
  int    _draftAmt  = 5;
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

  void _addItem() {
    if (_draftAmt < 1) return;
    widget.onChanged(widget.editor.copyWith(
      items: [...widget.editor.items, FeedItem(food: _draftFood, amt: _draftAmt)],
    ));
  }

  void _removeItem(int idx) {
    final items = [...widget.editor.items]..removeAt(idx);
    widget.onChanged(widget.editor.copyWith(items: items));
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
    final total = e.items.fold(0, (s, i) => s + i.amt);
    final bg  = _chipColor('귀뚜라미');

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
                      borderRadius: BorderRadius.zero,
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
                              e.isEdit ? '피딩 기록 수정' : '피딩 기록 추가',
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
                          // 컴포저 카드
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              border: Border.all(color: AppColors.paleLine),
                              borderRadius: BorderRadius.zero,
                            ),
                            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('피딩 추가',
                                    style: TextStyle(
                                        fontSize: 12, fontWeight: FontWeight.w700,
                                        color: AppColors.primary)),
                                const SizedBox(height: 10),
                                // 먹이 선택
                                DropdownButtonFormField<String>(
                                  value: _draftFood,
                                  onChanged: (v) =>
                                      setState(() => _draftFood = v!),
                                  items: _foods.map((f) => DropdownMenuItem(
                                    value: f,
                                    child: Row(children: [
                                      Container(
                                        width: 8, height: 8,
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                            color: _dotColor(f),
                                            shape: BoxShape.circle),
                                      ),
                                      Text(f),
                                    ]),
                                  )).toList(),
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 11),
                                    border: UnderlineInputBorder(
                                      borderRadius: BorderRadius.zero,
                                      borderSide: const BorderSide(
                                          color: AppColors.paleLine),
                                    ),
                                    enabledBorder: UnderlineInputBorder(
                                      borderRadius: BorderRadius.zero,
                                      borderSide: const BorderSide(
                                          color: AppColors.paleLine),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // 마리수 스테퍼
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.paleLine),
                                    borderRadius: BorderRadius.zero,
                                  ),
                                  child: Row(
                                    children: [
                                      AppStepperButton('−',
                                          onTap: () => setState(() =>
                                              _draftAmt = (_draftAmt - 1).clamp(1, 99))),
                                      Expanded(
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              '$_draftAmt',
                                              style: AppTextStyles.mono(
                                                  20, FontWeight.w700),
                                            ),
                                            const SizedBox(width: 6),
                                            Text('마리',
                                                style: TextStyle(
                                                    fontSize: 13,
                                                    color: AppColors.paleInk2)),
                                          ],
                                        ),
                                      ),
                                      AppStepperButton('+',
                                          onTap: () => setState(
                                              () => _draftAmt = (_draftAmt + 1).clamp(1, 99))),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // 프리셋 버튼
                                Wrap(
                                  spacing: 6,
                                  children: [1, 3, 5, 7, 10].map((n) {
                                    final active = _draftAmt == n;
                                    return GestureDetector(
                                      onTap: () => setState(() => _draftAmt = n),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: active ? bg : AppColors.paleBg,
                                          border: Border.all(
                                              color: active
                                                  ? Colors.transparent
                                                  : AppColors.paleLine),
                                          borderRadius: BorderRadius.zero,
                                        ),
                                        child: Text('$n마리',
                                            style: AppTextStyles.mono(
                                                11, FontWeight.w700)),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 12),
                                // 목록에 추가 버튼
                                GestureDetector(
                                  onTap: _addItem,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: bg,
                                      border: Border.all(color: AppColors.primary, width: 1.5),
                                      borderRadius: BorderRadius.zero,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.add, size: 16,
                                            color: AppColors.primary),
                                        const SizedBox(width: 8),
                                        const Text('목록에 추가',
                                            style: TextStyle(
                                                fontSize: 14, fontWeight: FontWeight.w700,
                                                color: AppColors.primary)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 이 끼니의 급여 목록
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('이 끼니의 피딩',
                                  style: TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w700,
                                      color: AppColors.primary)),
                              Text(
                                '${e.items.length}종 · 총 ${total}마리',
                                style: AppTextStyles.mono(11, FontWeight.w700,
                                    color: AppColors.paleInk2),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          if (e.items.isEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.paleLine,
                                    width: 1.5, style: BorderStyle.solid),
                                borderRadius: BorderRadius.zero,
                              ),
                              child: Text(
                                '위에서 피딩을 골라 추가해 주세요',
                                style: TextStyle(fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.paleInk3),
                              ),
                            )
                          else
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                border: Border.all(color: AppColors.paleLine),
                                borderRadius: BorderRadius.zero,
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 2),
                              child: Column(
                                children: e.items.asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  final item = entry.value;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(vertical: 11),
                                    decoration: BoxDecoration(
                                      border: idx < e.items.length - 1
                                          ? const Border(bottom: BorderSide(
                                              color: AppColors.paleLineSoft))
                                          : null,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 8, height: 8,
                                          decoration: BoxDecoration(
                                            color: _dotColor(item.food),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(item.food,
                                              style: const TextStyle(
                                                  fontSize: 14, fontWeight: FontWeight.w600,
                                                  color: AppColors.primary)),
                                        ),
                                        Text(
                                          '×${item.amt}',
                                          style: AppTextStyles.monoBody,
                                        ),
                                        Text(' 마리',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: AppColors.paleInk2)),
                                        const SizedBox(width: 4),
                                        GestureDetector(
                                          onTap: () => _removeItem(idx),
                                          child: Container(
                                            width: 26, height: 26,
                                            alignment: Alignment.center,
                                            child: const Icon(Icons.close,
                                                size: 16, color: AppColors.paleInk3),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
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
        ],
      ),
    );
  }
}

