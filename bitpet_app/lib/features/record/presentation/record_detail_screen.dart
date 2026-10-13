import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_input_styles.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/confirm_modal.dart';
import '../../../core/widgets/month_grid_calendar.dart';
import '../../../core/widgets/selected_day_card.dart';
import '../../../core/widgets/underline_tabs.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/toast_message.dart';
import '../data/models/record_models.dart';
import '../data/record_repository.dart';
import '../providers/record_invalidation.dart';
import '../providers/record_provider.dart';
import '../../pet/providers/pet_provider.dart';
import '../../pet/data/pet_repository.dart';
import '../../pet/data/models/pet_models.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/pet_avatar.dart';
import '../../../core/widgets/sex_icon.dart';

const _weekKo = ['일', '월', '화', '수', '목', '금', '토'];

// ── 타입 메타 ──────────────────────────────────────────────────
class _TypeMeta {
  final String label;
  final String calendarCat;
  final Color accent;
  // 아이콘은 들고 있지 않다 — 필요하면 calendarCat 을 [RecordTypeIcon] 에 넘긴다.
  const _TypeMeta(this.label, this.calendarCat, this.accent);
}

const _typeMeta = {
  'cleaning': _TypeMeta('청소 기록',  'CLEANING', AppColors.petSkyInk),
  'memo':     _TypeMeta('메모',       'MEMO',     AppColors.petLilacInk),
  'mating':   _TypeMeta('교배 기록',  'MATING',   AppColors.petCoralInk),
  'laying':   _TypeMeta('산란 기록',  'LAYING',   AppColors.petClayInk),
};

// ── 통합 기록 엔트리 ────────────────────────────────────────────
class RecordEntry {
  final int id;
  final String dateStr;   // YYYY-MM-DD
  final String timeStr;   // HH:mm
  final String summary;
  final dynamic raw;

  const RecordEntry({
    required this.id,
    required this.dateStr,
    required this.timeStr,
    required this.summary,
    required this.raw,
  });
}

// ── 에디터 상태 ─────────────────────────────────────────────────
class _EditorState {
  final bool isEdit;
  final int? editId;
  final String dateStr;
  final Map<String, dynamic> form;

  const _EditorState({
    required this.isEdit,
    required this.editId,
    required this.dateStr,
    required this.form,
  });

  _EditorState copyWith({String? dateStr, Map<String, dynamic>? form}) =>
      _EditorState(
        isEdit: isEdit, editId: editId,
        dateStr: dateStr ?? this.dateStr,
        form: form ?? this.form,
      );
}

// ── 메인 화면 ────────────────────────────────────────────────────
class RecordDetailScreen extends ConsumerStatefulWidget {
  final int petId;
  final String recordType; // cleaning, memo, mating, laying

  const RecordDetailScreen({
    super.key,
    required this.petId,
    required this.recordType,
  });

  @override
  ConsumerState<RecordDetailScreen> createState() =>
      _RecordDetailScreenState();
}

class _RecordDetailScreenState extends ConsumerState<RecordDetailScreen> {
  int _tabIndex = 0;
  _EditorState? _editor;

  _TypeMeta get _meta => _typeMeta[widget.recordType]!;

  // 각 타입 provider → RecordEntry 리스트
  AsyncValue<List<RecordEntry>> get _entriesAsync {
    switch (widget.recordType) {
      case 'cleaning':
        return ref.watch(cleaningListProvider(widget.petId)).whenData(
            (l) => l.map(_fromCleaning).toList());
      case 'memo':
        return ref.watch(memoListProvider(widget.petId)).whenData(
            (l) => l.map(_fromMemo).toList());
      case 'mating':
        return ref.watch(matingListProvider(widget.petId)).whenData(
            (l) => l.map(_fromMating).toList());
      case 'laying':
        return ref.watch(layingListProvider(widget.petId)).whenData(
            (l) => l.map(_fromLaying).toList());
      default:
        return const AsyncData([]);
    }
  }

  void _invalidate() => invalidatePetRecords(ref, widget.petId);

  void _openAdd(String? dateStr) {
    setState(() {
      _editor = _EditorState(
        isEdit: false, editId: null,
        dateStr: dateStr ?? _todayStr(),
        form: _defaultForm(),
      );
    });
  }

  void _openEdit(RecordEntry entry) {
    setState(() {
      _editor = _EditorState(
        isEdit: true, editId: entry.id,
        dateStr: entry.dateStr,
        form: _entryToForm(entry),
      );
    });
  }

  Future<void> _save() async {
    final e = _editor;
    if (e == null) return;
    final repo = ref.read(recordRepositoryProvider);
    try {
      final dateTime = DateTime.parse(e.dateStr).toUtc().toIso8601String();
      if (widget.recordType == 'cleaning') {
        final ct = e.form['cleaningType'] as CleaningType;
        final memo = (e.form['memo'] as String).trim();
        if (e.isEdit && e.editId != null) {
          await repo.updateCleaning(e.editId!, {
            'cleaningType': ct.name,
            'cleanedAt': dateTime,
            if (memo.isNotEmpty) 'memo': memo,
          });
        } else {
          await repo.addCleaning(widget.petId, ct, DateTime.parse(e.dateStr),
              memo.isEmpty ? null : memo);
        }
      } else if (widget.recordType == 'memo') {
        final tags = List<String>.from(e.form['tags'] as List? ?? const []);
        final rawContent = (e.form['content'] as String).trim();
        // 내용이 없어도 분류를 골랐으면 그 라벨로 저장 (FAB 메모 폼과 동일)
        final tagMatches = tags.isEmpty
            ? const <MemoTag>[]
            : (ref.read(memoTagsProvider).valueOrNull ?? const <MemoTag>[])
                .where((t) => t.code == tags.first)
                .toList();
        final tagLabel = tagMatches.isEmpty ? null : tagMatches.first.labelKo;
        final content = rawContent.isNotEmpty ? rawContent : (tagLabel ?? '');
        // 추가할 때만 내용을 요구한다. 수정은 **날짜만** 고치는 경우가 있어서 통과시킨다
        // (메모 없이 완료한 루틴 기록 — 빈 내용이 정상 상태다).
        if (content.isEmpty && !e.isEdit) {
          showToast(context, '내용을 입력하거나 분류를 선택하세요',
              type: ToastType.error);
          return;
        }
        final data = <String, dynamic>{
          'content': content,
          'loggedAt': dateTime,
          'tags': tags, // PUT은 태그 전체 교체 — 항상 전송해야 기존 태그가 보존됨
        };
        // VET 태그 메모는 vetExt 필수 (기존 값 보존, 없으면 빈 객체)
        if (tags.contains('VET')) {
          final vetExt = e.form['vetExt'] as MemoVetExt?;
          data['vetExt'] = {
            'clinicName': vetExt?.clinicName,
            'cost': vetExt?.cost,
            'nextVisitAt': vetExt?.nextVisitAt?.toUtc().toIso8601String(),
          };
        }
        if (e.isEdit && e.editId != null) {
          await repo.updateMemo(e.editId!, data);
        } else {
          await repo.addMemo(widget.petId, data);
        }
      } else if (widget.recordType == 'mating') {
        final memo = (e.form['memo'] as String).trim();

        // 서버는 petIdMale/petIdFemale 중 **최소 하나가 내 개체**여야 받아준다
        // (`MATING_OWNER_REQUIRED`). 예전엔 둘 다 안 보내서 무조건 400 이었다.
        // 이 화면의 개체를 제 성별 자리에 넣고, 반대편에 파트너를 넣는다.
        final self = ref.read(petDetailProvider(widget.petId)).valueOrNull;
        final gender = self?.gender;
        if (gender != 'MALE' && gender != 'FEMALE') {
          showToast(context,
              '개체의 성별이 정해져야 교배를 기록할 수 있어요. 개체 정보에서 성별을 먼저 지정해 주세요.',
              type: ToastType.warning);
          return;
        }
        final partnerId = e.form['partnerPetId'] as int?;
        final malePetId   = gender == 'MALE'   ? widget.petId : partnerId;
        final femalePetId = gender == 'FEMALE' ? widget.petId : partnerId;

        final data = {
          if (malePetId != null) 'petIdMale': malePetId,
          if (femalePetId != null) 'petIdFemale': femalePetId,
          'triedAt': dateTime,
          'seasonLabel': DateTime.parse(e.dateStr).year.toString(),
          if (e.form['isSuccessful'] != null)
            'isSuccessful': e.form['isSuccessful'],
          if (memo.isNotEmpty) 'memo': memo,
        };
        if (e.isEdit && e.editId != null) {
          await repo.updateMating(e.editId!, data);
        } else {
          await repo.addMating(widget.petId, data);
        }
      } else if (widget.recordType == 'laying') {
        final cnt = e.form['totalCount'] as int;
        final fertile = e.form['fertileCount'] as int?;
        final memo = (e.form['memo'] as String).trim();
        if (cnt <= 0) {
          showToast(context, '알 총 개수를 적어주세요', type: ToastType.error);
          return;
        }
        // 서버도 막지만(`LAYING_FERTILE_EXCEEDS_TOTAL`) 400 을 받고 나서
        // 알려 주는 건 늦다 — 숫자 두 개를 나란히 적는 폼이라 뒤바꿔 적는 일이 잦다.
        if (fertile != null && fertile > cnt) {
          showToast(context, '유정란 수가 총 개수보다 많아요', type: ToastType.error);
          return;
        }
        final data = {
          'laidAt': dateTime,
          // 서버 필드명은 `eggCountTotal`(@NotNull @Min(1)).
          // `totalCount` 로 보내면 알맹이가 없는 요청이 되어 400 이 떨어진다.
          'eggCountTotal': cnt,
          // 수정일 때는 **null 도 보낸다** — 잘못 적은 유정란 수를 지워
          // '미확인'으로 되돌릴 방법이 있어야 한다.
          if (fertile != null || e.isEdit) 'eggCountFertile': fertile,
          if (memo.isNotEmpty) 'memo': memo,
        };
        if (e.isEdit && e.editId != null) {
          await repo.updateLaying(e.editId!, data);
        } else {
          await repo.addLaying(widget.petId, data);
        }
      }
      _invalidate();
      if (mounted) {
        setState(() => _editor = null);
        showToast(context, e.isEdit ? '수정되었습니다.' : '기록이 추가되었습니다.',
            type: ToastType.success);
      }
    } catch (err) {
      if (mounted) showToast(context, err.toString(), type: ToastType.error);
    }
  }

  Future<void> _delete(int id) async {
    final ok = await ConfirmModal.show(
      context,
      title: '기록 삭제',
      message: '이 기록을 삭제할까요?\n삭제하면 복구할 수 없습니다.',
      confirmLabel: '삭제',
      isDangerous: true,
    );
    if (!ok) return;
    final repo = ref.read(recordRepositoryProvider);
    try {
      switch (widget.recordType) {
        case 'cleaning': await repo.deleteCleaning(id);
        case 'memo':     await repo.deleteMemo(id);
        case 'mating':   await repo.deleteMating(id);
        case 'laying':   await repo.deleteLaying(id);
      }
      _invalidate();
      if (mounted) {
        setState(() => _editor = null);
        showToast(context, '기록이 삭제되었습니다.', type: ToastType.info);
      }
    } catch (err) {
      if (mounted) showToast(context, err.toString(), type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final petAsync = ref.watch(petDetailProvider(widget.petId));
    final petName = petAsync.whenOrNull(data: (p) => p.name) ?? '';

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Stack(
        children: [
          Column(
            children: [
              SafeArea(
                bottom: false,
                child: _TopBar(
                  onBack: () => context.pop(),
                  title: _meta.label,
                  petName: petName,
                  onAdd: () => _openAdd(null),
                ),
              ),
              // 보고 있는 페이지는 밑줄 — 알약 세그먼트는 '설정'의 모양이다
              AppUnderlineTabs(
                labels: const ['캘린더', '리스트'],
                index: _tabIndex,
                onChanged: (i) => setState(() => _tabIndex = i),
                horizontalPadding: AppSpacing.screenH,
              ),
              Expanded(
                child: _entriesAsync.when(
                  loading: () => const SkeletonCardList(),
                  error: (e, _) => Center(child: Text(e.toString())),
                  data: (entries) => _tabIndex == 0
                      ? _CalendarView(
                          petId: widget.petId,
                          recordType: widget.recordType,
                          calendarCat: _meta.calendarCat,
                          accentColor: _meta.accent,
                          entries: entries,
                          onEdit: _openEdit,
                          onAdd: _openAdd,
                        )
                      : _RecordListView(
                          recordType: widget.recordType,
                          accentColor: _meta.accent,
                          entries: entries,
                          onEdit: _openEdit,
                        ),
                ),
              ),
            ],
          ),
          if (_editor != null)
            _EditorSheet(
              petId: widget.petId,
              recordType: widget.recordType,
              editor: _editor!,
              accentColor: _meta.accent,
              onChanged: (e) => setState(() => _editor = e),
              onSave: _save,
              onDelete: _delete,
              onClose: () => setState(() => _editor = null),
            ),
        ],
      ),
    );
  }

  // ── 변환 헬퍼 ────────────────────────────────────────────────
  RecordEntry _fromCleaning(CleaningRecord r) {
    final label = switch (r.cleaningType) {
      CleaningType.FULL => '전체 청소',
      CleaningType.PARTIAL => '부분 청소',
      CleaningType.WATER_CHANGE => '물 교체',
    };
    return RecordEntry(
      id: r.id, dateStr: _dateStr(r.cleanedAt),
      timeStr: _timeStr(r.cleanedAt), summary: label, raw: r);
  }

  RecordEntry _fromMemo(Memo r) => RecordEntry(
    id: r.id, dateStr: _dateStr(r.loggedAt),
    timeStr: _timeStr(r.loggedAt), summary: r.displayContent, raw: r);

  /// 교배는 **상대가 있어야 성립**하는 유일한 기록이다. 결과(성공/실패)만 적어두면
  /// 같은 철에 여러 번 합사한 목록이 전부 똑같아 보여서 어느 줄이 뭔지 구분이 안 된다.
  /// 파트너는 이 개체의 **반대쪽**이다 — 내가 수컷 칸이면 암컷 칸이 상대다.
  /// 모델이 `petMaleSummary`/`petFemaleSummary` 의 이름을 이미 들고 있어 서버를 더
  /// 부르지 않는다. 우리 개체가 아니면 `externalPartnerText`(외부 개체).
  String? _matingPartnerName(MatingRecord r) {
    if (r.malePetId == widget.petId) {
      return r.femalePetName ?? r.externalPartnerText;
    }
    if (r.femalePetId == widget.petId) {
      return r.malePetName ?? r.externalPartnerText;
    }
    return r.externalPartnerText;
  }

  RecordEntry _fromMating(MatingRecord r) {
    final result = r.isSuccessful == true
        ? '성공'
        : r.isSuccessful == false ? '실패' : '결과 미정';
    // 파트너를 앞에 둔다 — 눈이 먼저 닿는 자리가 "누구와" 여야 요약으로 읽힌다.
    // 파트너가 없으면(한쪽만 기록) 가운뎃점만 남지 않게 결과만 적는다.
    final partner = _matingPartnerName(r);
    final label = partner == null || partner.isEmpty
        ? result
        : '$partner · $result';
    return RecordEntry(
      id: r.id, dateStr: _dateStr(r.triedAt),
      timeStr: _timeStr(r.triedAt), summary: label, raw: r);
  }

  RecordEntry _fromLaying(LayingRecord r) => RecordEntry(
    id: r.id, dateStr: _dateStr(r.laidAt), timeStr: _timeStr(r.laidAt),
    // 유정란 수를 적어 둔 기록이면 함께 보여 준다 — 목록에서 '몇 개 낳았나'
    // 다음으로 궁금한 게 '그중 몇 개가 유정이냐'다.
    summary: r.fertileCount == null
        ? '${r.totalCount}개'
        : '${r.totalCount}개 · 유정 ${r.fertileCount}',
    raw: r);

  Map<String, dynamic> _defaultForm() => switch (widget.recordType) {
    'cleaning' => {'cleaningType': CleaningType.FULL, 'memo': ''},
    'memo'     => {'content': '', 'tags': <String>[], 'memo': ''},
    'mating'   => {'isSuccessful': null, 'partnerPetId': null,
                   'partnerLabel': null, 'memo': ''},
    'laying'   => {'totalCount': 1, 'fertileCount': null, 'memo': ''},
    _ => {},
  };

  Map<String, dynamic> _entryToForm(RecordEntry entry) {
    switch (widget.recordType) {
      case 'cleaning':
        final r = entry.raw as CleaningRecord;
        return {'cleaningType': r.cleaningType, 'memo': r.memo ?? ''};
      case 'memo':
        final r = entry.raw as Memo;
        // VET 태그·vetExt는 이 폼에서 편집하지 않지만 저장 시 보존해야 함
        return {
          'content': r.content,
          'tags': List<String>.from(r.tags),
          'vetExt': r.vetExt,
          'memo': '',
        };
      case 'mating':
        final r = entry.raw as MatingRecord;
        // 파트너 = 이 기록에서 '내 개체가 아닌 쪽'. 성별을 따지지 않아도
        // 어느 칸에 내가 들어가 있는지만 보면 반대편이 곧 파트너다.
        final isMale = r.malePetId == widget.petId;
        return {
          'isSuccessful': r.isSuccessful,
          'partnerPetId': isMale ? r.femalePetId : r.malePetId,
          'partnerLabel': isMale ? r.femalePetName : r.malePetName,
          'memo': r.memo ?? '',
        };
      case 'laying':
        final r = entry.raw as LayingRecord;
        return {
          'totalCount': r.totalCount,
          'fertileCount': r.fertileCount,
          'memo': r.memo ?? '',
        };
      default:
        return {};
    }
  }

  // 서버 시각은 UTC — 로컬(KST) 벽시계로 변환해 표시 (이미 로컬이면 무해)
  static String _dateStr(DateTime dt) {
    final d = dt.toLocal();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  static String _timeStr(DateTime dt) {
    final d = dt.toLocal();
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  static String _todayStr() => _dateStr(DateTime.now());
}

// ── TopBar ────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  final String title;
  final String petName;
  final VoidCallback onAdd;

  const _TopBar({required this.onBack, required this.title,
      required this.petName, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(children: [
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
          Text(title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                  color: AppColors.primary, letterSpacing: -0.2)),
          if (petName.isNotEmpty)
            Text(petName.toUpperCase(), style: AppTextStyles.monoXs),
        ]),
        const Spacer(),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: AppRadius.brMd,
            ),
            child: Row(children: [
              const Icon(Icons.add, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text('기록', style: TextStyle(fontSize: 13,
                  fontWeight: FontWeight.w700, color: AppColors.paleBg)),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ── 기록 카드 ────────────────────────────────────────────────────
//
// `bare` = 테두리·배경 없는 **맨 몸** 행. 카드 안에 들어갈 때 쓴다
// (카드 안의 카드는 깊이를 두 번 세는 셈이라 금지).
class _RecordCard extends StatelessWidget {
  final RecordEntry entry;
  final Color accentColor;
  final VoidCallback onEdit;

  final bool bare;

  /// 카드 머리말이 이미 날짜를 말하는 자리 — 시각만 남긴다
  final bool timeOnly;

  const _RecordCard({required this.entry, required this.accentColor,
      required this.onEdit,
      this.bare = false, this.timeOnly = false});

  @override
  Widget build(BuildContext context) {
    final body = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 날짜(또는 시각) 컬럼 — 일/시각을 **한 줄**로 둔다.
        //
        // 세로로 쌓으면 글자 배율을 키운 기기에서 카드가 그만큼 길어지고,
        // 폭을 52로 주면 시각('14:30')이 간당간당해 줄바꿈까지 된다.
        // FittedBox(scaleDown) 이면 좁아질 때 줄바꿈 대신 함께 줄어든다.
        SizedBox(
            width: timeOnly ? 46 : 76,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: timeOnly
                    ? Text(entry.timeStr,
                        maxLines: 1, softWrap: false,
                        style: AppTextStyles.monoSm)
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(entry.dateStr.substring(8), // dd
                              maxLines: 1, softWrap: false,
                              style: AppTextStyles.monoBody),
                          const SizedBox(width: 6),
                          Text(entry.timeStr,
                              maxLines: 1, softWrap: false,
                              style: AppTextStyles.monoXxs),
                        ],
                      ),
              ),
            ),
          ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 7, height: 7,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                      color: accentColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.summary,
                    style: const TextStyle(fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
              // Memo line (if applicable)
              Builder(builder: (_) {
                String? memo;
                final raw = entry.raw;
                if (raw is CleaningRecord && raw.memo != null) memo = raw.memo;
                else if (raw is MatingRecord && raw.memo != null) memo = raw.memo;
                else if (raw is LayingRecord && raw.memo != null) memo = raw.memo;
                if (memo == null || memo.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(memo,
                      style: AppTextStyles.caption,
                      overflow: TextOverflow.ellipsis),
                );
              }),
            ],
          ),
        ),
        // 기록은 전부 수정할 수 있다 — "수정 못 하는 기록" 같은 건 없다.
        GestureDetector(
          onTap: onEdit,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: bare ? Colors.transparent : AppColors.bgAlt,
              border: bare ? null : Border.all(color: AppColors.line),
              borderRadius: AppRadius.brMd,
            ),
            child: const Icon(Icons.edit_outlined,
                size: 16, color: AppColors.ink3),
          ),
        ),
      ],
    );

    if (bare) return body;

    return Container(
      decoration: AppDecor.card,
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: body,
    );
  }
}

// ── 캘린더 뷰 ────────────────────────────────────────────────────
class _CalendarView extends ConsumerStatefulWidget {
  final int petId;
  final String recordType;
  final String calendarCat;
  final Color accentColor;
  final List<RecordEntry> entries;
  final ValueChanged<RecordEntry> onEdit;
  final ValueChanged<String?> onAdd;

  const _CalendarView({
    required this.petId, required this.recordType,
    required this.calendarCat, required this.accentColor,
    required this.entries, required this.onEdit, required this.onAdd,
  });

  @override
  ConsumerState<_CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends ConsumerState<_CalendarView> {
  // 진입 시엔 항상 **이번 달 / 오늘** — 기록이 있는 마지막 달로 점프하지 않는다
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  late String _selDate = todayIso();

  String get _ymStr =>
      '${_month.year}-${_month.month.toString().padLeft(2, '0')}';

  Map<String, List<RecordEntry>> get _byDate {
    final map = <String, List<RecordEntry>>{};
    for (final e in widget.entries) {
      if (e.dateStr.startsWith(_ymStr)) {
        map.putIfAbsent(e.dateStr, () => []).add(e);
      }
    }
    return map;
  }

  /// 셀 본문. 기록이 없으면 null.
  ///
  /// [catDays] 는 서버 월별 집계라 목록(entries)보다 넓을 수 있다.
  /// 집계에는 있는데 목록에 없는 날은 내용 대신 점만 찍어 "뭔가 있음"을 알린다.
  Widget? _cellContent(
      Map<String, List<RecordEntry>> byDate, Set<String> catDays, String date) {
    final recs = byDate[date];
    if (recs == null || recs.isEmpty) {
      if (!catDays.contains(date)) return null;
      return Padding(
        padding: const EdgeInsets.only(left: 2, top: 1),
        child: Container(
          width: 5, height: 5,
          decoration: BoxDecoration(
              color: widget.accentColor, shape: BoxShape.circle),
        ),
      );
    }
    const maxLines = 3;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final e in recs.take(maxLines))
          CalendarCellLine(
            dotColor: widget.accentColor,
            label: e.summary.isEmpty ? e.timeStr : e.summary,
          ),
        if (recs.length > maxLines) CalendarCellMore(recs.length - maxLines),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final calAsync = ref.watch(petCalendarProvider(PetYearMonth(widget.petId, _ymStr)));
    final byDate = _byDate;
    final monthEntries =
        widget.entries.where((e) => e.dateStr.startsWith(_ymStr)).toList();
    final selected = widget.entries.where((e) => e.dateStr == _selDate).toList()
      ..sort((a, b) => a.timeStr.compareTo(b.timeStr));

    // calendar days with this category
    final catDays = <String>{};
    calAsync.whenOrNull(data: (days) {
      for (final d in days) {
        if (d.categories.contains(widget.calendarCat)) catDays.add(d.date);
      }
    });

    // 요약은 **면 없는 캡션 한 줄**이다 — 개체 상세의 히어로 카드와 같은 모양을
    // 하위 화면에서 또 쓰면 어느 화면인지가 흐려진다.
    final days = monthEntries.map((e) => e.dateStr).toSet();
    final summary = <MonthSummaryItem>[
      MonthSummaryItem('기록', '${monthEntries.length}건'),
      MonthSummaryItem('기록한 날', '${days.length}일'),
    ];

    // 고른 날 기록은 시트가 아니라 캘린더 **바로 아래**에 펼친다. 칸을 눌러
    // 시트를 열고 닫는 두 번의 조작이 그 날 내용을 보는 유일한 길이면 안 된다.
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MonthGridCalendar(
            month: _month,
            selectedDate: _selDate,
            summary: summary,
            onMonthChanged: (m) => setState(() => _month = m),
            onDayTap: (ds) => setState(() => _selDate = ds),
            cellBuilder: (ds) => _cellContent(byDate, catDays, ds),
            onToday: () => setState(() {
              final now = DateTime.now();
              _month = DateTime(now.year, now.month);
              _selDate = todayIso();
            }),
          ),
          const SizedBox(height: AppSpacing.cardGap),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
            child: SelectedDayCard(
              date: _selDate,
              countLabel: '${selected.length}건',
              onAdd: () => widget.onAdd(_selDate),
              rows: [
                for (final e in selected)
                  _RecordCard(
                    entry: e,
                    accentColor: widget.accentColor,
                    onEdit: () => widget.onEdit(e),
                    bare: true,
                    timeOnly: true,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 리스트 뷰 ─────────────────────────────────────────────────
class _RecordListView extends StatefulWidget {
  final String recordType;
  final Color accentColor;
  final List<RecordEntry> entries;
  final ValueChanged<RecordEntry> onEdit;

  const _RecordListView({required this.recordType, required this.accentColor,
      required this.entries, required this.onEdit});

  @override
  State<_RecordListView> createState() => _RecordListViewState();
}

class _RecordListViewState extends State<_RecordListView> {
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
      setState(() =>
          _count = (_count + _page).clamp(0, widget.entries.length));
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = widget.entries.take(_count).toList();

    // 월 단위로 묶는다. 행마다 카드를 주면 목록이 카드 더미가 되고 **덩어리가
    // 안 보인다** — 한 장 안에서 얇은 선으로만 나눈다 (선은 칸막이지 테두리가 아니다).
    final groups = <String, List<RecordEntry>>{};
    for (final e in visible) {
      groups.putIfAbsent(e.dateStr.substring(0, 7), () => []).add(e);
    }
    final monthKeys = groups.keys.toList();

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH, AppSpacing.md, AppSpacing.screenH, 110),
      itemCount: monthKeys.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('전체 기록', style: AppTextStyles.subheading),
                Text('${widget.entries.length}건', style: AppTextStyles.monoSm),
              ],
            ),
          );
        }
        final mk = monthKeys[i - 1];
        final rows = groups[mk]!;
        final ym = mk.split('-');
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.cardGap),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm, left: 2),
                child: Row(
                  children: [
                    Text('${ym[0]}. ${ym[1]}',
                        style: AppTextStyles.mono(14, FontWeight.w700)),
                    const SizedBox(width: AppSpacing.sm),
                    Text('${rows.length}건', style: AppTextStyles.monoXs),
                  ],
                ),
              ),
              Container(
                decoration: AppDecor.cardRaised,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var k = 0; k < rows.length; k++)
                      Container(
                        decoration: k == 0
                            ? null
                            : const BoxDecoration(
                                border: Border(
                                    top: BorderSide(color: AppColors.bgAlt)),
                              ),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        child: _RecordCard(
                          entry: rows[k],
                          accentColor: widget.accentColor,
                          onEdit: () => widget.onEdit(rows[k]),
                          bare: true,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── 에디터 시트 ──────────────────────────────────────────────────
class _EditorSheet extends StatefulWidget {
  final int petId;
  final String recordType;
  final _EditorState editor;
  final Color accentColor;
  final ValueChanged<_EditorState> onChanged;
  final VoidCallback onSave;
  final ValueChanged<int> onDelete;
  final VoidCallback onClose;

  const _EditorSheet({
    required this.petId, required this.recordType, required this.editor,
    required this.accentColor, required this.onChanged,
    required this.onSave, required this.onDelete, required this.onClose,
  });

  @override
  State<_EditorSheet> createState() => _EditorSheetState();
}

class _EditorSheetState extends State<_EditorSheet> {
  late final TextEditingController _memoCtrl;
  late final TextEditingController _contentCtrl;

  // 산란 — FAB 산란 폼과 같은 칸 두 개.
  // ⛔ 예전엔 −/+ 스테퍼 + '1·3·5·10·20개' 빠른 칩이었는데, 유정란 칸이
  // 아예 없어서 FAB 로 적은 기록을 여기서 고치면 유정란 수가 사라졌다.
  // 같은 데이터를 적는 폼이 두 모양이면 어느 쪽이 맞는지 알 수 없다.
  late final TextEditingController _totalCtrl;
  late final TextEditingController _fertileCtrl;

  @override
  void initState() {
    super.initState();
    _memoCtrl = TextEditingController(
        text: widget.editor.form['memo'] as String? ?? '');
    _contentCtrl = TextEditingController(
        text: widget.editor.form['content'] as String? ?? '');
    final total = widget.editor.form['totalCount'] as int? ?? 1;
    _totalCtrl = TextEditingController(text: total > 0 ? '$total' : '');
    final fertile = widget.editor.form['fertileCount'] as int?;
    _fertileCtrl =
        TextEditingController(text: fertile == null ? '' : '$fertile');
  }

  @override
  void dispose() {
    _memoCtrl.dispose();
    _contentCtrl.dispose();
    _totalCtrl.dispose();
    _fertileCtrl.dispose();
    super.dispose();
  }

  void _shiftDate(int days) {
    final parts = widget.editor.dateStr.split('-').map(int.parse).toList();
    final dt = DateTime(parts[0], parts[1], parts[2] + days);
    widget.onChanged(widget.editor.copyWith(
      dateStr: '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}',
    ));
  }

  Widget _eggLabel(String text, {required bool required}) => Row(
        children: [
          Text(text,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary)),
          if (required)
            const Text(' *',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error)),
        ],
      );

  void _updateForm(String key, dynamic value) {
    widget.onChanged(widget.editor.copyWith(
      form: {...widget.editor.form, key: value},
    ));
  }

  bool get _canSave {
    if (widget.recordType == 'memo') {
      // 내용을 적었거나, 분류를 하나 골랐으면 저장 가능 (FAB 메모 폼과 동일)
      // 수정일 때는 빈 내용도 저장 가능 — 날짜만 고치는 경우가 있다
      if (widget.editor.isEdit) return true;
      final hasContent =
          (widget.editor.form['content'] as String? ?? '').trim().isNotEmpty;
      final hasTag =
          (widget.editor.form['tags'] as List? ?? const []).isNotEmpty;
      return hasContent || hasTag;
    }
    if (widget.recordType == 'laying') {
      return (widget.editor.form['totalCount'] as int? ?? 0) > 0;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.editor;
    final dt = DateTime.parse(e.dateStr);
    final title = e.isEdit ? '기록 수정' : '기록 추가';

    return Material(
      color: Colors.transparent,
      child: Stack(children: [
        GestureDetector(
          onTap: widget.onClose,
          child: Container(color: Colors.black.withValues(alpha: 0.45)),
        ),
        Positioned(
          left: 0, right: 0, bottom: 0, top: 70,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 1, end: 0),
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            builder: (context, t, child) =>
                FractionalTranslation(translation: Offset(0, t), child: child),
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                color: AppColors.paleBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Column(children: [
              // drag handle
              Container(
                width: 44, height: 4,
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                decoration: BoxDecoration(
                    color: AppColors.paleLine,
                    borderRadius: BorderRadius.circular(2)),
              ),
              // 헤더 + 날짜 스테퍼
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Column(children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w700,
                              color: AppColors.primary, letterSpacing: -0.4)),
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
                  const SizedBox(height: 8),
                  // 날짜 스테퍼
                  Row(children: [
                    AppNavButton(onTap: () => _shiftDate(-1)),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          border: Border.all(color: AppColors.paleLine),
                          borderRadius: AppRadius.brMd,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(e.dateStr.replaceAll('-', '.'),
                                style: AppTextStyles.mono(14, FontWeight.w700)),
                            const SizedBox(width: 8),
                            Text('(${_weekKo[dt.weekday % 7]})',
                                style: TextStyle(fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.paleInk2)),
                          ],
                        ),
                      ),
                    ),
                    AppNavButton(forward: true, onTap: () => _shiftDate(1)),
                  ]),
                ]),
              ),
              // 폼 본문
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── 청소 종류 (FAB 기록 시트와 동일한 폼) ──
                      if (widget.recordType == 'cleaning') ...[
                        const Text('청소 종류',
                            style: TextStyle(fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary)),
                        const SizedBox(height: 8),
                        Row(
                          children: const [
                            (CleaningType.FULL, '전체 청소',
                                AppIcons.cleanFull),
                            (CleaningType.PARTIAL, '부분 청소',
                                AppIcons.cleanPartial),
                            (CleaningType.WATER_CHANGE, '물 교체',
                                AppIcons.cleanWater),
                          ].map((t) {
                            final sel = e.form['cleaningType'] == t.$1;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () => _updateForm('cleaningType', t.$1),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 120),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: sel ? AppColors.petSky : AppColors.card,
                                      border: Border.all(
                                          color: sel
                                              ? AppColors.petSkyInk
                                              : AppColors.paleLine,
                                          width: sel ? 1.5 : 1),
                                      borderRadius: AppRadius.brMd,
                                    ),
                                    child: Column(
                                      children: [
                                        AppIcon(t.$3, size: 20,
                                            color: sel
                                                ? AppColors.petSkyInk
                                                : AppColors.paleInk2),
                                        const SizedBox(height: 4),
                                        Text(t.$2,
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: sel
                                                    ? AppColors.petSkyInk
                                                    : AppColors.paleInk2)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],

                      // ── 메모(메모 기록) ───────────────────
                      if (widget.recordType == 'memo') ...[
                        // ── 분류 (병원/탈피/배변/행동/기타 — 단일 선택 라디오, FAB 메모 폼과 동일) ──
                        Row(children: [
                          const Text('분류',
                              style: TextStyle(fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary)),
                          const SizedBox(width: 8),
                          Text('OPTIONAL', style: AppTextStyles.monoXxs),
                        ]),
                        const SizedBox(height: 8),
                        Consumer(builder: (context, ref, _) {
                          final tags = ref.watch(memoTagsProvider).valueOrNull ??
                              const <MemoTag>[];
                          if (tags.isEmpty) return const SizedBox.shrink();
                          final selected = List<String>.from(
                              e.form['tags'] as List? ?? const []);
                          final selectedCode =
                              selected.isEmpty ? null : selected.first;
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: tags.map((t) {
                              final sel = selectedCode == t.code;
                              return GestureDetector(
                                onTap: () => _updateForm(
                                    'tags', sel ? <String>[] : [t.code]),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: sel
                                        ? AppColors.petLilac
                                        : AppColors.card,
                                    border: Border.all(
                                        color: sel
                                            ? AppColors.petLilacInk
                                            : AppColors.paleLine,
                                        width: sel ? 1.5 : 1),
                                    borderRadius: AppRadius.brMd,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // 라디오 원 대신 태그 그림 — 기록 시트와 같은 칩이다.
                                      AppIcon(
                                        AppIcons.memoTag(t.code),
                                        size: 16,
                                        color: sel
                                            ? AppColors.petLilacInk
                                            : AppColors.paleInk2,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(t.labelKo,
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: sel
                                                  ? AppColors.petLilacInk
                                                  : AppColors.paleInk2)),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        }),
                        const SizedBox(height: 16),

                        const Text('내용',
                            style: TextStyle(fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _contentCtrl,
                          maxLines: 4,
                          onChanged: (v) => _updateForm('content', v),
                          decoration: AppInputStyles.textarea(
                            hintText: '관찰한 내용을 기록해요 (선택)',
                          ),
                        ),
                      ],

                      // ── 교배 ──────────────────────────────
                      if (widget.recordType == 'mating') ...[
                        // 파트너를 지정해야 상대 개체의 기록탭에도 같은 교배가 뜬다
                        // (서버는 암수 어느 쪽이든 걸려 있으면 목록에 포함시킨다).
                        _MatingPartnerField(
                          petId: widget.petId,
                          partnerPetId: e.form['partnerPetId'] as int?,
                          partnerLabel: e.form['partnerLabel'] as String?,
                          onPicked: (id, label) {
                            widget.onChanged(e.copyWith(form: {
                              ...e.form,
                              'partnerPetId': id,
                              'partnerLabel': label,
                            }));
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text('결과',
                            style: TextStyle(fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: AppChip(
                                label: '미정',
                                selected: e.form['isSuccessful'] == null,
                                selectedColor: AppColors.paleBgAlt,
                                selectedBorderColor: AppColors.paleLine,
                                selectedTextColor: AppColors.paleInk2,
                                centered: true,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                onTap: () => _updateForm('isSuccessful', null),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: AppChip(
                                label: '성공',
                                selected: e.form['isSuccessful'] == true,
                                selectedColor: AppColors.petClay,
                                selectedTextColor: AppColors.primary,
                                centered: true,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                onTap: () => _updateForm('isSuccessful', true),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: AppChip(
                                label: '실패',
                                selected: e.form['isSuccessful'] == false,
                                selectedColor: AppColors.petCoral,
                                selectedTextColor: AppColors.primary,
                                centered: true,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                onTap: () => _updateForm('isSuccessful', false),
                              ),
                            ),
                          ],
                        ),
                      ],

                      // ── 산란 ──────────────────────────────
                      // FAB 산란 폼(`fab_record_sheet.dart` 의 'lay')과 같은
                      // 칸·같은 순서다. 한쪽만 고치지 말 것.
                      if (widget.recordType == 'laying') ...[
                        _eggLabel('알 총 개수', required: true),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _totalCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary),
                          decoration: const InputDecoration(
                            hintText: '0',
                            suffixText: '개',
                            suffixStyle: TextStyle(
                                fontSize: 14, color: AppColors.paleInk2),
                          ),
                          onChanged: (v) => setState(() => _updateForm(
                              'totalCount', int.tryParse(v.trim()) ?? 0)),
                        ),
                        const SizedBox(height: 16),
                        _eggLabel('유정란 수', required: false),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _fertileCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                              fontSize: 14, color: AppColors.primary),
                          decoration: const InputDecoration(
                            hintText: '미확인 시 비워두세요',
                            suffixText: '개',
                            suffixStyle: TextStyle(
                                fontSize: 14, color: AppColors.paleInk2),
                          ),
                          // 비우면 null — '전부 무정(0)'과 구별해야 한다.
                          onChanged: (v) => _updateForm('fertileCount',
                              v.trim().isEmpty ? null : int.tryParse(v.trim())),
                        ),
                      ],

                      // ── 공통 메모 (memo 타입 제외) ─────────
                      if (widget.recordType != 'memo') ...[
                        const SizedBox(height: 16),
                        Row(children: [
                          const Text('메모',
                              style: TextStyle(fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary)),
                          const SizedBox(width: 8),
                          Text('OPTIONAL', style: AppTextStyles.monoXxs),
                        ]),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _memoCtrl,
                          onChanged: (v) => _updateForm('memo', v),
                          maxLines: 2,
                          decoration: AppInputStyles.textarea(
                            hintText: '메모 (선택)',
                          ),
                        ),
                      ],

                      // 삭제 버튼
                      if (e.isEdit && e.editId != null) ...[
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () => widget.onDelete(e.editId!),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.errorLine),
                              borderRadius: AppRadius.brMd,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                                SizedBox(width: 8),
                                Text('이 기록 삭제',
                                    style: TextStyle(fontSize: 13,
                                        fontWeight: FontWeight.w700,
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
                    20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
                decoration: const BoxDecoration(
                  color: AppColors.paleBg,
                  border: Border(top: BorderSide(color: AppColors.paleLineSoft)),
                ),
                child: Row(children: [
                  GestureDetector(
                    onTap: widget.onClose,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        border: Border.all(color: AppColors.paleLine),
                        borderRadius: AppRadius.brLg,
                      ),
                      child: const Text('취소',
                          style: TextStyle(fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: _canSave ? widget.onSave : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _canSave ? AppColors.primary : AppColors.paleLine,
                          borderRadius: AppRadius.brLg,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check, size: 16,
                                color: _canSave ? AppColors.paleBg : AppColors.paleInk3),
                            const SizedBox(width: 8),
                            Text(e.isEdit ? '수정 완료' : '저장',
                                style: TextStyle(fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _canSave ? AppColors.paleBg : AppColors.paleInk3)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ]),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── 교배 파트너 선택 ────────────────────────────────────────────
//
// FAB 기록 시트에만 있던 것을 기록 상세의 추가/수정 폼으로도 옮겨 왔다.
// 서버는 `petIdMale`/`petIdFemale` 중 최소 하나가 내 개체여야 기록을 받고,
// 목록 쿼리는 암수 **어느 쪽이든** 그 개체가 걸린 교배를 돌려준다
// (`MatingDtlSpecs.filter`). 즉 여기서 파트너를 지정하면 그 개체의
// 기록탭에도 같은 교배가 자동으로 뜬다 — 같은 기록을 두 번 쓰지 않는다.
class _MatingPartnerField extends ConsumerStatefulWidget {
  final int petId;
  final int? partnerPetId;
  final String? partnerLabel;
  final void Function(int? id, String? label) onPicked;

  const _MatingPartnerField({
    required this.petId,
    required this.partnerPetId,
    required this.partnerLabel,
    required this.onPicked,
  });

  @override
  ConsumerState<_MatingPartnerField> createState() =>
      _MatingPartnerFieldState();
}

class _MatingPartnerFieldState extends ConsumerState<_MatingPartnerField> {
  final _serialCtrl = TextEditingController();
  bool _external = false;
  bool _searching = false;
  String? _searchError;

  @override
  void dispose() {
    _serialCtrl.dispose();
    super.dispose();
  }

  // 일련번호로 남의 개체 찾기 — 정확히 일치해야만 열린다 (목록 열람은 없다)
  Future<void> _search(String speciesName) async {
    final q = _serialCtrl.text.trim().toUpperCase();
    if (q.isEmpty) return;
    setState(() {
      _searching = true;
      _searchError = null;
    });
    try {
      final found = await ref.read(petRepositoryProvider).findBySerial(q);
      if (!mounted) return;
      if (found == null) {
        setState(() => _searchError = '검색 결과 없음 (비공개이거나 없는 일련번호)');
      } else if (speciesName.isNotEmpty && found.speciesName != speciesName) {
        setState(() =>
            _searchError = '같은 종만 파트너로 지정할 수 있어요 (${found.speciesName})');
      } else {
        widget.onPicked(found.id, found.name);
      }
    } catch (_) {
      if (mounted) setState(() => _searchError = '검색 중 오류가 발생했어요');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final self = ref.watch(petDetailProvider(widget.petId)).valueOrNull;
    final myPets =
        ref.watch(petListProvider).whenOrNull(data: (l) => l) ?? const <Pet>[];

    // 성별이 없으면 서버가 암수 어느 칸에도 넣어주지 않는다(400).
    // 파트너를 고르게 두기 전에 이 사실부터 알린다.
    if (self != null && self.gender != 'MALE' && self.gender != 'FEMALE') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.paleBgAlt,
          border: Border.all(color: AppColors.paleLine),
          borderRadius: AppRadius.brMd,
        ),
        child: const Text(
          '이 개체의 성별이 지정되어 있지 않아 교배를 기록할 수 없어요.\n'
          '개체 정보에서 성별을 먼저 지정해 주세요.',
          style: TextStyle(fontSize: 12, color: AppColors.paleInk2, height: 1.5),
        ),
      );
    }

    // 후보: 같은 종 · 반대 성별 · 자기 자신 제외
    final wantMale = self?.gender == 'FEMALE';
    final candidates = myPets
        .where((p) =>
            p.id != widget.petId &&
            (self == null || p.speciesName == self.speciesName) &&
            p.gender == (wantMale ? 'MALE' : 'FEMALE'))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Text('파트너',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                  color: AppColors.primary)),
          const SizedBox(width: 8),
          Text('OPTIONAL', style: AppTextStyles.monoXxs),
        ]),
        const SizedBox(height: 8),

        // 이미 고른 파트너 — 한 줄로 보여주고 해제만 시킨다
        if (widget.partnerPetId != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.card,
              border: Border.all(color: AppColors.paleLine),
              borderRadius: AppRadius.brMd,
            ),
            child: Row(children: [
              const Icon(Icons.favorite, size: 14, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.partnerLabel ?? '개체 #${widget.partnerPetId}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13,
                      fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              ),
              GestureDetector(
                onTap: () {
                  _serialCtrl.clear();
                  widget.onPicked(null, null);
                },
                child: const Icon(Icons.close, size: 16,
                    color: AppColors.paleInk2),
              ),
            ]),
          )
        else ...[
          Row(children: [
            Expanded(
              child: AppChip(
                label: '내 개체',
                selected: !_external,
                centered: true,
                padding: const EdgeInsets.symmetric(vertical: 10),
                onTap: () => setState(() {
                  _external = false;
                  _searchError = null;
                }),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppChip(
                label: '외부 개체',
                selected: _external,
                centered: true,
                padding: const EdgeInsets.symmetric(vertical: 10),
                onTap: () => setState(() {
                  _external = true;
                  _searchError = null;
                }),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          if (_external) ...[
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _serialCtrl,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(fontSize: 14, color: AppColors.primary),
                  decoration:
                      AppInputStyles.textarea(hintText: '일련번호 (예: AB12CD34)'),
                  onChanged: (_) => setState(() => _searchError = null),
                  onSubmitted: (_) => _search(self?.speciesName ?? ''),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _searching ? null : () => _search(self?.speciesName ?? ''),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: AppRadius.brMd,
                  ),
                  child: _searching
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.search, size: 20, color: Colors.white),
                ),
              ),
            ]),
            if (_searchError != null) ...[
              const SizedBox(height: 6),
              Text(_searchError!,
                  style: const TextStyle(fontSize: 12,
                      color: AppColors.warning)),
            ],
          ] else
            Container(
              constraints: const BoxConstraints(maxHeight: 168),
              decoration: BoxDecoration(
                color: AppColors.card,
                border: Border.all(color: AppColors.paleLine),
                borderRadius: AppRadius.brMd,
              ),
              child: candidates.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      child: Center(
                        child: Text('같은 종의 반대 성별 개체가 없어요',
                            style: TextStyle(fontSize: 12,
                                color: AppColors.paleInk3)),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      // ⚠️ padding 을 안 주면 주변 MediaQuery 의 패딩(바텀시트 하단
                      // safe-area)을 그대로 먹어서, 항목이 한둘이어도 박스 아래가 붕 뜬다.
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      physics: const ClampingScrollPhysics(),
                      itemCount: candidates.length,
                      separatorBuilder: (_, __) => const Divider(
                          height: 1, color: AppColors.paleLineSoft),
                      itemBuilder: (_, i) {
                        final p = candidates[i];
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => widget.onPicked(p.id, p.name),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Row(children: [
                              PetAvatar(
                                imageUrl: p.profileImageUrl,
                                size: 30,
                                background: AppColors.paleBgAlt,
                                iconColor: AppColors.paleInk2,
                                subcategory: p.speciesSubcategory,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(p.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary)),
                              ),
                              SexIcon.fromCode(p.gender, size: 13),
                            ]),
                          ),
                        );
                      },
                    ),
            ),
        ],
      ],
    );
  }
}

