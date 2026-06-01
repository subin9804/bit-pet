// 05b 급여 기록 도메인 모델 — feed-data.json 구조 그대로 반영
// 추후 API 응답이 같은 구조를 따름

class FeedItem {
  final String food; // 먹이 종류 (귀뚜라미, 슈퍼웜, ...)
  final int amt;     // 마리수

  const FeedItem({required this.food, required this.amt});

  factory FeedItem.fromJson(Map<String, dynamic> json) => FeedItem(
        food: json['food'] as String,
        amt:  json['amt']  as int,
      );

  Map<String, dynamic> toJson() => {'food': food, 'amt': amt};

  FeedItem copyWith({String? food, int? amt}) =>
      FeedItem(food: food ?? this.food, amt: amt ?? this.amt);
}

class FeedSession {
  final String id;
  final String date; // "YYYY-MM-DD"
  final String time; // "HH:mm"
  final List<FeedItem> items;
  final String memo;

  const FeedSession({
    required this.id,
    required this.date,
    required this.time,
    required this.items,
    required this.memo,
  });

  factory FeedSession.fromJson(Map<String, dynamic> json) => FeedSession(
        id:    json['id']   as String,
        date:  json['date'] as String,
        time:  json['time'] as String? ?? '21:00',
        items: (json['items'] as List)
            .map((e) => FeedItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        memo:  json['memo'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id':    id,
        'date':  date,
        'time':  time,
        'items': items.map((i) => i.toJson()).toList(),
        'memo':  memo,
      };

  int get totalAmt => items.fold(0, (s, i) => s + i.amt);

  FeedSession copyWith({
    String? date, String? time,
    List<FeedItem>? items, String? memo,
  }) =>
      FeedSession(
        id:    id,
        date:  date  ?? this.date,
        time:  time  ?? this.time,
        items: items ?? this.items,
        memo:  memo  ?? this.memo,
      );
}

// 편집 시트 상태 DTO
class FeedEditorState {
  final bool isEdit;
  final String? editId;
  final String date;
  final String time;
  final List<FeedItem> items;
  final String memo;

  const FeedEditorState({
    required this.isEdit,
    this.editId,
    required this.date,
    required this.time,
    required this.items,
    required this.memo,
  });

  FeedEditorState copyWith({
    String? date, String? time,
    List<FeedItem>? items, String? memo,
  }) =>
      FeedEditorState(
        isEdit: isEdit,
        editId: editId,
        date:   date  ?? this.date,
        time:   time  ?? this.time,
        items:  items ?? this.items,
        memo:   memo  ?? this.memo,
      );
}
