// 해칭일 · 입양일 기념일.
//
// 캘린더에 얹는 이 표시는 **기록이 아니라 파생값**이다. 서버 캘린더 집계
// (`/calendar`, `/pets/{id}/calendar`)는 그 달에 실제로 쌓인 행을 세는 것이라
// "매년 돌아오는 날"을 담을 자리가 없다. 반면 해칭일·입양일은 개체 응답에
// 이미 실려 오므로(`Pet.hatchingDate` / `Pet.adoptionDate`) 앱에서 월/일만
// 맞춰 보면 된다 — 서버 왕복도, 배포도 필요 없다.

import '../data/models/pet_models.dart';

enum AnniversaryKind {
  /// 해칭일 — 생일
  hatching,

  /// 입양일 — 우리집에 온 날
  adoption,
}

class Anniversary {
  final int petId;
  final String petName;
  final AnniversaryKind kind;

  /// 원래 날짜 (해칭일 / 입양일 그 자체)
  final DateTime origin;

  /// 몇 번째 해인가. 0 = 그 날 당일(해칭한 해, 데려온 해).
  final int years;

  const Anniversary({
    required this.petId,
    required this.petName,
    required this.kind,
    required this.origin,
    required this.years,
  });

  /// '2주년' / '해칭' / '입양'
  String get badge {
    if (years == 0) {
      return kind == AnniversaryKind.hatching ? '해칭' : '입양';
    }
    return '$years주년';
  }

  /// '레오 2주년' — 목록 한 줄에 쓰는 문구
  String get label => '$petName $badge';

  String get kindLabel =>
      kind == AnniversaryKind.hatching ? '해칭일' : '입양일';
}

/// [month] 가 속한 달의 기념일을 'YYYY-MM-DD' → 목록으로 돌려준다.
///
/// 규칙:
/// - 해칭일은 **일(day)까지 정확한 것만**(`hatchingDatePrecision == 'DAY'`) 센다.
///   월 단위로만 아는 개체에 특정 날짜를 찍으면 없는 사실을 만들어내는 꼴이다.
/// - 이별한 개체는 **이별일 이후의 기념일을 띄우지 않는다.** 과거 달로 넘겨 보면
///   그때의 기념일은 그대로 남는다 — 지난 일까지 지울 이유는 없다.
/// - 2/29 생은 평년에 2/28 로 당겨 표시한다(3/1 로 미루면 달이 바뀐다).
Map<String, List<Anniversary>> anniversariesInMonth(
    List<Pet> pets, DateTime month) {
  final result = <String, List<Anniversary>>{};

  void add(Pet pet, AnniversaryKind kind, DateTime origin) {
    final occurrence = _occurrenceIn(month, origin);
    if (occurrence == null) return;

    // 해칭 전 / 데려오기 전의 달에는 아무것도 없다
    final years = occurrence.year - origin.year;
    if (years < 0) return;

    final deceased = pet.deceasedAt;
    if (deceased != null && occurrence.isAfter(deceased)) return;

    final key = '${occurrence.year}-'
        '${occurrence.month.toString().padLeft(2, '0')}-'
        '${occurrence.day.toString().padLeft(2, '0')}';

    result.putIfAbsent(key, () => []).add(Anniversary(
          petId: pet.id,
          petName: pet.name,
          kind: kind,
          origin: origin,
          years: years,
        ));
  }

  for (final pet in pets) {
    final hatched = pet.hatchingDate;
    if (hatched != null && pet.hatchingDatePrecision == 'DAY') {
      add(pet, AnniversaryKind.hatching, hatched);
    }
    final adopted = pet.adoptionDate;
    if (adopted != null) {
      add(pet, AnniversaryKind.adoption, adopted);
    }
  }

  // 같은 날에 여럿이면 해칭 먼저, 그다음 이름순 — 표시 순서가 매번 흔들리지 않게
  for (final list in result.values) {
    list.sort((a, b) {
      final byKind = a.kind.index.compareTo(b.kind.index);
      return byKind != 0 ? byKind : a.petName.compareTo(b.petName);
    });
  }

  return result;
}

/// 개체 한 마리의 기념일만 (개체 상세 캘린더 탭용)
Map<String, List<Anniversary>> petAnniversariesInMonth(
        Pet? pet, DateTime month) =>
    pet == null ? const {} : anniversariesInMonth([pet], month);

/// [origin] 의 월/일이 [month] 안에서 떨어지는 날. 다른 달이면 null.
DateTime? _occurrenceIn(DateTime month, DateTime origin) {
  if (origin.month != month.month) return null;

  final lastDay = DateTime(month.year, month.month + 1, 0).day;
  final day = origin.day > lastDay ? lastDay : origin.day; // 2/29 → 평년 2/28
  return DateTime(month.year, month.month, day);
}
