import '../util/dates.dart';

/// What happened on a given day.
///
/// [full] and [floor] both count as showing up — that is the whole point of the
/// floor. [rest] is spent deliberately and is neutral: it leaves consistency
/// untouched rather than dinging it. [missed] only exists once the person has
/// tagged a reason; an untagged gap is simply an absent entry.
enum DayKind { full, floor, rest, missed }

/// The four one-word reasons offered in the blameless miss review.
enum MissReason { forgot, noTime, tired, away }

extension MissReasonLabel on MissReason {
  String get label => switch (this) {
        MissReason.forgot => 'Forgot',
        MissReason.noTime => 'No time',
        MissReason.tired => 'Tired',
        MissReason.away => 'Away',
      };
}

MissReason? missReasonFromName(String? name) {
  if (name == null) return null;
  for (final r in MissReason.values) {
    if (r.name == name) return r;
  }
  return null;
}

class DayEntry {
  DayEntry({
    required DateTime date,
    required this.kind,
    this.reason,
    DateTime? loggedAt,
  })  : date = dateOnly(date),
        loggedAt = loggedAt ?? DateTime.now();

  final DateTime date;
  final DayKind kind;
  final MissReason? reason;
  final DateTime loggedAt;

  bool get isShowingUp => kind == DayKind.full || kind == DayKind.floor;

  Map<String, dynamic> toJson() => {
        'date': dateKey(date),
        'kind': kind.name,
        if (reason != null) 'reason': reason!.name,
        'loggedAt': loggedAt.toIso8601String(),
      };

  static DayEntry fromJson(Map<String, dynamic> json) => DayEntry(
        date: parseDateKey(json['date'] as String),
        kind: DayKind.values.firstWhere(
          (k) => k.name == json['kind'],
          orElse: () => DayKind.full,
        ),
        reason: missReasonFromName(json['reason'] as String?),
        loggedAt:
            DateTime.tryParse(json['loggedAt'] as String? ?? '') ?? DateTime.now(),
      );
}
