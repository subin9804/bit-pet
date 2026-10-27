/// 기록 종류(서버 RecordCategory) → 그 종류의 기록 상세 화면 경로.
/// 급여·체중만 전용 화면이고 나머지는 `/records/:type` 한 화면이 받는다.
/// 상세 화면이 없는 종류는 null.
String? recordDetailPath(int petId, String category) => switch (category) {
      'FEEDING' => '/pets/$petId/feeding',
      'WEIGHT' => '/pets/$petId/weight',
      'CLEANING' => '/pets/$petId/records/cleaning',
      'MEMO' => '/pets/$petId/records/memo',
      'MATING' => '/pets/$petId/records/mating',
      'LAYING' => '/pets/$petId/records/laying',
      _ => null,
    };
