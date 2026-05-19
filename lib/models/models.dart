import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum Gender { male, female }

enum PaymentStatus { unpaid, partial, paid, free }

enum SessionStatus { settled, hasDebt, loss }

class AppSettings {
  double defaultMalePrice;
  double defaultFemalePrice;
  String currency;
  String? bankQrPath;
  String? tngQrPath;

  AppSettings({
    this.defaultMalePrice = 23,
    this.defaultFemalePrice = 20,
    this.currency = 'RM',
    this.bankQrPath,
    this.tngQrPath,
  });

  Map<String, dynamic> toJson() => {
        'defaultMalePrice': defaultMalePrice,
        'defaultFemalePrice': defaultFemalePrice,
        'currency': currency,
        'bankQrPath': bankQrPath,
        'tngQrPath': tngQrPath,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        defaultMalePrice: (j['defaultMalePrice'] as num?)?.toDouble() ?? 23,
        defaultFemalePrice: (j['defaultFemalePrice'] as num?)?.toDouble() ?? 20,
        currency: j['currency'] as String? ?? 'RM',
        bankQrPath: j['bankQrPath'] as String?,
        tngQrPath: j['tngQrPath'] as String?,
      );
}

class Expense {
  final String id;
  String category;
  double amount;
  String note;

  Expense({
    String? id,
    required this.category,
    required this.amount,
    this.note = '',
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toJson() =>
      {'id': id, 'category': category, 'amount': amount, 'note': note};

  factory Expense.fromJson(Map<String, dynamic> j) => Expense(
        id: j['id'] as String,
        category: j['category'] as String,
        amount: (j['amount'] as num).toDouble(),
        note: j['note'] as String? ?? '',
      );
}

class PaymentRecord {
  final String id;
  double amount;
  String method;
  String note;
  DateTime paidAt;

  PaymentRecord({
    String? id,
    required this.amount,
    required this.method,
    this.note = '',
    DateTime? paidAt,
  })  : id = id ?? _uuid.v4(),
        paidAt = paidAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'method': method,
        'note': note,
        'paidAt': paidAt.toIso8601String(),
      };

  factory PaymentRecord.fromJson(Map<String, dynamic> j) => PaymentRecord(
        id: j['id'] as String,
        amount: (j['amount'] as num).toDouble(),
        method: j['method'] as String,
        note: j['note'] as String? ?? '',
        paidAt: DateTime.parse(j['paidAt'] as String),
      );
}

class SessionPlayer {
  final String id;
  String name;
  Gender gender;
  double amountDue;
  bool isOverride;
  bool isFree;
  List<PaymentRecord> payments;

  SessionPlayer({
    String? id,
    required this.name,
    required this.gender,
    required this.amountDue,
    this.isOverride = false,
    this.isFree = false,
    List<PaymentRecord>? payments,
  })  : id = id ?? _uuid.v4(),
        payments = payments ?? [];

  double get totalPaid => payments.fold(0, (s, p) => s + p.amount);
  double get remaining => isFree ? 0 : amountDue - totalPaid;

  PaymentStatus get status {
    if (isFree) return PaymentStatus.free;
    if (totalPaid <= 0) return PaymentStatus.unpaid;
    if (totalPaid >= amountDue) return PaymentStatus.paid;
    return PaymentStatus.partial;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'gender': gender.name,
        'amountDue': amountDue,
        'isOverride': isOverride,
        'isFree': isFree,
        'payments': payments.map((p) => p.toJson()).toList(),
      };

  factory SessionPlayer.fromJson(Map<String, dynamic> j) => SessionPlayer(
        id: j['id'] as String,
        name: j['name'] as String,
        gender: Gender.values.byName(j['gender'] as String),
        amountDue: (j['amountDue'] as num).toDouble(),
        isOverride: j['isOverride'] as bool? ?? false,
        isFree: j['isFree'] as bool? ?? false,
        payments: (j['payments'] as List<dynamic>?)
                ?.map((e) => PaymentRecord.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

// Parses "8:30 PM", "20:30", "8pm" → minutes from midnight. Returns null if unparseable.
int? _timeToMinutes(String t) {
  final s = t.trim().toUpperCase();
  final isPm = s.contains('PM');
  final isAm = s.contains('AM');
  final clean = s.replaceAll(RegExp(r'[APM\s]'), '');
  final parts = clean.split(':');
  if (parts.isEmpty || parts[0].isEmpty) return null;
  int hour = int.tryParse(parts[0]) ?? 0;
  int minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
  if (isPm && hour != 12) hour += 12;
  if (isAm && hour == 12) hour = 0;
  return hour * 60 + minute;
}

double sessionHoursBetween(String start, String end) {
  final s = _timeToMinutes(start);
  final e = _timeToMinutes(end);
  if (s == null || e == null) return 2.0;
  int diff = e - s;
  if (diff <= 0) diff += 24 * 60;
  return diff / 60.0;
}

class Session {
  final String id;
  String name;
  DateTime date;
  String startTime;
  String endTime;
  String location;
  String note;
  String shuttleModel;
  double shuttlePricePerTube;
  int tubeCount;
  double courtFeePerHour;
  int courtCount;
  double courtHoursBooked;
  List<Expense> extraExpenses;
  List<SessionPlayer> players;
  bool isFinalized;
  int? finalShuttlecocksUsed;

  Session({
    String? id,
    this.name = '',
    required this.date,
    this.startTime = '',
    this.endTime = '',
    required this.location,
    this.note = '',
    this.shuttleModel = 'G2',
    this.shuttlePricePerTube = 90,
    this.tubeCount = 2,
    this.courtFeePerHour = 0,
    this.courtCount = 1,
    this.courtHoursBooked = 2.0,
    List<Expense>? extraExpenses,
    List<SessionPlayer>? players,
    this.isFinalized = false,
    this.finalShuttlecocksUsed,
  })  : id = id ?? _uuid.v4(),
        extraExpenses = extraExpenses ?? [],
        players = players ?? [];

  int get totalShuttlecocks => finalShuttlecocksUsed ?? (tubeCount * 12);

  double get sessionHours => sessionHoursBetween(startTime, endTime);
  double get shuttleCost => finalShuttlecocksUsed != null
      ? (shuttlePricePerTube / 12) * finalShuttlecocksUsed!
      : shuttlePricePerTube * tubeCount;
  double get courtCost => courtFeePerHour * courtHoursBooked;
  double get totalCost => shuttleCost + courtCost + extraExpenses.fold(0, (s, e) => s + e.amount);
  double get totalDue => players.where((p) => !p.isFree).fold(0, (s, p) => s + p.amountDue);
  double get totalCollected => players.where((p) => !p.isFree).fold(0, (s, p) => s + p.totalPaid);
  double get totalUnpaid => players.where((p) => !p.isFree).fold(0, (s, p) => s + p.remaining);
  double get profit => totalCollected - totalCost;

  List<SessionPlayer> get unpaidPlayers =>
      players.where((p) => !p.isFree && p.status != PaymentStatus.paid).toList();

  SessionStatus get status {
    if (profit < 0) return SessionStatus.loss;
    if (unpaidPlayers.isNotEmpty) return SessionStatus.hasDebt;
    return SessionStatus.settled;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'date': date.toIso8601String(),
        'startTime': startTime,
        'endTime': endTime,
        'location': location,
        'note': note,
        'shuttleModel': shuttleModel,
        'shuttlePricePerTube': shuttlePricePerTube,
        'tubeCount': tubeCount,
        'courtFeePerHour': courtFeePerHour,
        'courtCount': courtCount,
        'courtHoursBooked': courtHoursBooked,
        'extraExpenses': extraExpenses.map((e) => e.toJson()).toList(),
        'players': players.map((p) => p.toJson()).toList(),
        'isFinalized': isFinalized,
        'finalShuttlecocksUsed': finalShuttlecocksUsed,
      };

  factory Session.fromJson(Map<String, dynamic> j) {
    final startTime = j['startTime'] as String? ?? j['time'] as String? ?? '';
    final endTime = j['endTime'] as String? ?? '';
    return Session(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        date: DateTime.parse(j['date'] as String),
        startTime: startTime,
        endTime: endTime,
        location: j['location'] as String,
        note: j['note'] as String? ?? '',
        shuttleModel: j['shuttleModel'] as String? ?? 'G2',
        shuttlePricePerTube: (j['shuttlePricePerTube'] as num?)?.toDouble() ?? 90,
        tubeCount: j['tubeCount'] as int? ?? 2,
        courtFeePerHour: (j['courtFeePerHour'] as num?)?.toDouble() ??
            (j['courtFee'] as num?)?.toDouble() ?? 0,
        courtCount: j['courtCount'] as int? ?? 1,
        courtHoursBooked: (j['courtHoursBooked'] as num?)?.toDouble() ??
            sessionHoursBetween(startTime, endTime),
        extraExpenses: (j['extraExpenses'] as List<dynamic>?)
                ?.map((e) => Expense.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        players: (j['players'] as List<dynamic>?)
                ?.map((e) => SessionPlayer.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        isFinalized: j['isFinalized'] as bool? ?? false,
        finalShuttlecocksUsed: j['finalShuttlecocksUsed'] as int?,
      );
  }
}

class CapitalEntry {
  final String id;
  double amount;
  String note;
  DateTime date;

  CapitalEntry({
    String? id,
    required this.amount,
    this.note = '',
    DateTime? date,
  })  : id = id ?? _uuid.v4(),
        date = date ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'note': note,
        'date': date.toIso8601String(),
      };

  factory CapitalEntry.fromJson(Map<String, dynamic> j) => CapitalEntry(
        id: j['id'] as String,
        amount: (j['amount'] as num).toDouble(),
        note: j['note'] as String? ?? '',
        date: DateTime.parse(j['date'] as String),
      );
}

class PlayerRecord {
  final String id;
  String name;
  Gender gender;
  List<String> sessionIds;

  PlayerRecord({
    String? id,
    required this.name,
    required this.gender,
    List<String>? sessionIds,
  })  : id = id ?? _uuid.v4(),
        sessionIds = sessionIds ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'gender': gender.name,
        'sessionIds': sessionIds,
      };

  factory PlayerRecord.fromJson(Map<String, dynamic> j) => PlayerRecord(
        id: j['id'] as String,
        name: j['name'] as String,
        gender: Gender.values.byName(j['gender'] as String),
        sessionIds: List<String>.from(j['sessionIds'] as List? ?? []),
      );
}

class Template {
  final String id;
  String name;
  String location;
  double malePrice;
  double femalePrice;
  double courtFee;
  double shuttlePrice;
  int tubeCount;

  Template({
    String? id,
    required this.name,
    required this.location,
    this.malePrice = 23,
    this.femalePrice = 20,
    this.courtFee = 0,
    this.shuttlePrice = 90,
    this.tubeCount = 2,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'location': location,
        'malePrice': malePrice,
        'femalePrice': femalePrice,
        'courtFee': courtFee,
        'shuttlePrice': shuttlePrice,
        'tubeCount': tubeCount,
      };

  factory Template.fromJson(Map<String, dynamic> j) => Template(
        id: j['id'] as String,
        name: j['name'] as String,
        location: j['location'] as String,
        malePrice: (j['malePrice'] as num?)?.toDouble() ?? 23,
        femalePrice: (j['femalePrice'] as num?)?.toDouble() ?? 20,
        courtFee: (j['courtFee'] as num?)?.toDouble() ?? 0,
        shuttlePrice: (j['shuttlePrice'] as num?)?.toDouble() ?? 90,
        tubeCount: j['tubeCount'] as int? ?? 2,
      );
}
