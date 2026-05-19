import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class AppProvider extends ChangeNotifier {
  // ─── In-memory state ────────────────────────────────────────────────────
  List<Session> _sessions = [];
  List<Template> _templates = [];
  List<PlayerRecord> _players = [];
  List<CapitalEntry> _capitalEntries = [];
  AppSettings _settings = AppSettings();
  bool _loading = false;

  // ─── Stream subscriptions ────────────────────────────────────────────────
  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot>? _sessionsSub;
  StreamSubscription<QuerySnapshot>? _templatesSub;
  StreamSubscription<QuerySnapshot>? _playersSub;
  StreamSubscription<QuerySnapshot>? _capitalSub;
  StreamSubscription<DocumentSnapshot>? _settingsSub;

  // Tracks which collections have emitted their first snapshot
  final Set<String> _firstLoads = {};
  static const _allCollections = {
    'sessions', 'templates', 'players', 'capital', 'settings'
  };

  // ─── Public getters ──────────────────────────────────────────────────────
  List<Session> get sessions => List.unmodifiable(_sessions);
  List<Template> get templates => List.unmodifiable(_templates);
  List<PlayerRecord> get players => List.unmodifiable(_players);
  List<CapitalEntry> get capitalEntries => List.unmodifiable(_capitalEntries);
  AppSettings get settings => _settings;
  bool get loading => _loading;

  // ─── Firestore references ─────────────────────────────────────────────────
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  DocumentReference get _userDoc =>
      FirebaseFirestore.instance.collection('users').doc(_uid);

  CollectionReference get _sessionsRef => _userDoc.collection('sessions');
  CollectionReference get _templatesRef => _userDoc.collection('templates');
  CollectionReference get _playersRef => _userDoc.collection('players');
  CollectionReference get _capitalRef =>
      _userDoc.collection('capital_entries');
  DocumentReference get _settingsRef =>
      _userDoc.collection('settings').doc('default');

  // ─── Constructor — self-manages auth + Firestore lifecycle ───────────────
  AppProvider() {
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        _loading = true;
        _firstLoads.clear();
        notifyListeners();
        await _migrateFromSharedPrefs(user.uid);
        _setupListeners();
      } else {
        _tearDownListeners();
        _clearAll();
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _tearDownListeners();
    super.dispose();
  }

  // ─── Firestore stream setup / teardown ────────────────────────────────────

  void _setupListeners() {
    if (_uid == null) return;

    // Sessions — ordered newest first
    _sessionsSub = _sessionsRef
        .orderBy('date', descending: true)
        .snapshots()
        .listen((snap) {
      _sessions = snap.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Session.fromJson({...data, 'id': doc.id});
      }).toList();
      _onFirstLoad('sessions');
    }, onError: (e) => debugPrint('Sessions stream error: $e'));

    // Templates
    _templatesSub = _templatesRef.snapshots().listen((snap) {
      _templates = snap.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Template.fromJson({...data, 'id': doc.id});
      }).toList();
      _onFirstLoad('templates');
    }, onError: (e) => debugPrint('Templates stream error: $e'));

    // Players
    _playersSub = _playersRef.snapshots().listen((snap) {
      _players = snap.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return PlayerRecord.fromJson({...data, 'id': doc.id});
      }).toList();
      _onFirstLoad('players');
    }, onError: (e) => debugPrint('Players stream error: $e'));

    // Capital entries — ordered newest first
    _capitalSub = _capitalRef
        .orderBy('date', descending: true)
        .snapshots()
        .listen((snap) {
      _capitalEntries = snap.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return CapitalEntry.fromJson({...data, 'id': doc.id});
      }).toList();
      _onFirstLoad('capital');
    }, onError: (e) => debugPrint('Capital stream error: $e'));

    // Settings (single doc)
    _settingsSub = _settingsRef.snapshots().listen((snap) {
      // Preserve QR paths — they live in payment_qr, not here
      final prevBank = _settings.bankQrPath;
      final prevTng = _settings.tngQrPath;
      if (snap.exists) {
        _settings =
            AppSettings.fromJson(snap.data() as Map<String, dynamic>);
      }
      _settings.bankQrPath = prevBank;
      _settings.tngQrPath = prevTng;
      _onFirstLoad('settings');
    }, onError: (e) => debugPrint('Settings stream error: $e'));
  }

  void _tearDownListeners() {
    _sessionsSub?.cancel();
    _templatesSub?.cancel();
    _playersSub?.cancel();
    _capitalSub?.cancel();
    _settingsSub?.cancel();
    _sessionsSub = null;
    _templatesSub = null;
    _playersSub = null;
    _capitalSub = null;
    _settingsSub = null;
  }

  void _onFirstLoad(String collection) {
    _firstLoads.add(collection);
    if (_firstLoads.containsAll(_allCollections)) {
      _loading = false;
    }
    notifyListeners();
  }

  void _clearAll() {
    _sessions = [];
    _templates = [];
    _players = [];
    _capitalEntries = [];
    _settings = AppSettings();
    _loading = false;
    _firstLoads.clear();
    notifyListeners();
  }

  // ─── Migration: SharedPreferences → Firestore (runs once on first login) ─

  Future<void> _migrateFromSharedPrefs(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = prefs.getString('sessions');
      if (sessionsJson == null) return; // Nothing to migrate

      // Check if Firestore already has data — skip if so
      final existing =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('sessions')
              .limit(1)
              .get();
      if (existing.docs.isNotEmpty) {
        await prefs.clear(); // Already migrated — clean up
        return;
      }

      debugPrint('Migrating local data to Firestore...');
      final db = FirebaseFirestore.instance;
      final userBase = db.collection('users').doc(uid);

      // Migrate sessions
      final sessionsList =
          jsonDecode(sessionsJson) as List<dynamic>;
      for (final s in sessionsList) {
        final session = Session.fromJson(s as Map<String, dynamic>);
        await userBase.collection('sessions').doc(session.id).set(
            _stripNulls(session.toJson()));
      }

      // Migrate templates
      final templatesJson = prefs.getString('templates');
      if (templatesJson != null) {
        final list = jsonDecode(templatesJson) as List<dynamic>;
        for (final t in list) {
          final tmpl = Template.fromJson(t as Map<String, dynamic>);
          await userBase.collection('templates').doc(tmpl.id).set(
              _stripNulls(tmpl.toJson()));
        }
      }

      // Migrate players (PlayerRecord)
      final playersJson = prefs.getString('players');
      if (playersJson != null) {
        final list = jsonDecode(playersJson) as List<dynamic>;
        for (final p in list) {
          final player = PlayerRecord.fromJson(p as Map<String, dynamic>);
          await userBase.collection('players').doc(player.id).set(
              _stripNulls(player.toJson()));
        }
      }

      // Migrate capital entries
      final capitalJson = prefs.getString('capitalEntries');
      if (capitalJson != null) {
        final list = jsonDecode(capitalJson) as List<dynamic>;
        for (final c in list) {
          final entry = CapitalEntry.fromJson(c as Map<String, dynamic>);
          await userBase.collection('capital_entries').doc(entry.id).set(
              _stripNulls(entry.toJson()));
        }
      }

      // Migrate settings (pricing only — not QR paths)
      final settingsJson = prefs.getString('settings');
      if (settingsJson != null) {
        final s =
            AppSettings.fromJson(jsonDecode(settingsJson) as Map<String, dynamic>);
        await userBase.collection('settings').doc('default').set({
          'defaultMalePrice': s.defaultMalePrice,
          'defaultFemalePrice': s.defaultFemalePrice,
          'currency': s.currency,
        });
      }

      await prefs.clear();
      debugPrint('Migration complete.');
    } catch (e) {
      debugPrint('Migration error (non-fatal): $e');
    }
  }

  /// Removes null values from a map so Firestore doesn't complain.
  Map<String, dynamic> _stripNulls(Map<String, dynamic> m) =>
      Map.fromEntries(m.entries.where((e) => e.value != null));

  // ─── Compatibility shim — called from main.dart ───────────────────────────
  /// No-op: the provider now self-initialises via the auth state listener.
  Future<void> load() async {}

  // ─── Derived stats ────────────────────────────────────────────────────────

  double get totalCapital =>
      _capitalEntries.fold(0.0, (acc, e) => acc + e.amount);

  double get allTimeCollected =>
      _sessions.fold(0.0, (acc, s) => acc + s.totalCollected);

  double get allTimeCost =>
      _sessions.fold(0.0, (acc, s) => acc + s.totalCost);

  double get allTimeProfit =>
      _sessions.fold(0.0, (acc, s) => acc + s.profit);

  double get bankBalance => totalCapital + allTimeProfit;

  double get monthlyProfit {
    final now = DateTime.now();
    return _sessions
        .where((s) =>
            s.date.year == now.year && s.date.month == now.month)
        .fold(0.0, (acc, s) => acc + s.profit);
  }

  double get monthlyCollected {
    final now = DateTime.now();
    return _sessions
        .where((s) =>
            s.date.year == now.year && s.date.month == now.month)
        .fold(0.0, (acc, s) => acc + s.totalCollected);
  }

  double get monthlyCost {
    final now = DateTime.now();
    return _sessions
        .where((s) =>
            s.date.year == now.year && s.date.month == now.month)
        .fold(0.0, (acc, s) => acc + s.totalCost);
  }

  List<Session> get debtSessions =>
      _sessions.where((s) => s.unpaidPlayers.isNotEmpty).toList();

  int get uniquePlayersCount {
    final names = <String>{};
    for (final s in _sessions) {
      for (final p in s.players) {
        names.add(p.name.toLowerCase());
      }
    }
    return names.length;
  }

  int get totalShuttlecocksUsed =>
      _sessions.fold(0, (acc, s) => acc + s.totalShuttlecocks);

  // ─── Sessions ─────────────────────────────────────────────────────────────

  Future<void> addSession(Session session) async {
    if (_uid == null) return;
    await _sessionsRef.doc(session.id).set(_stripNulls(session.toJson()));
    // Stream handles notifyListeners()
  }

  Future<void> updateSession(Session session) async {
    if (_uid == null) return;
    await _sessionsRef
        .doc(session.id)
        .set(_stripNulls(session.toJson()), SetOptions(merge: false));
  }

  Future<void> deleteSession(String id) async {
    if (_uid == null) return;
    await _sessionsRef.doc(id).delete();
  }

  Session? getSession(String id) {
    try {
      return _sessions.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  // ─── Templates ────────────────────────────────────────────────────────────

  Future<void> addTemplate(Template t) async {
    if (_uid == null) return;
    await _templatesRef.doc(t.id).set(_stripNulls(t.toJson()));
  }

  Future<void> updateTemplate(Template t) async {
    if (_uid == null) return;
    await _templatesRef.doc(t.id).set(_stripNulls(t.toJson()));
  }

  Future<void> deleteTemplate(String id) async {
    if (_uid == null) return;
    await _templatesRef.doc(id).delete();
  }

  // ─── Player records ───────────────────────────────────────────────────────

  Future<void> upsertPlayer(PlayerRecord p) async {
    if (_uid == null) return;
    await _playersRef.doc(p.id).set(_stripNulls(p.toJson()));
  }

  double totalDebtForPlayer(String playerName) {
    double debt = 0;
    for (final s in _sessions) {
      for (final p in s.players) {
        if (p.name.toLowerCase() == playerName.toLowerCase()) {
          debt += p.remaining;
        }
      }
    }
    return debt;
  }

  /// Returns aggregated stats for a player across all sessions.
  Map<String, dynamic> statsForPlayer(String playerName) {
    final lower = playerName.toLowerCase();
    final joined = _sessions.where(
      (s) => s.players.any((p) => p.name.toLowerCase() == lower),
    ).toList();

    double totalPaid = 0;
    double totalDue = 0;
    int paidFullCount = 0;
    DateTime? lastSeen;
    DateTime? firstSeen;

    for (final s in joined) {
      if (lastSeen == null || s.date.isAfter(lastSeen)) lastSeen = s.date;
      if (firstSeen == null || s.date.isBefore(firstSeen)) firstSeen = s.date;
      for (final p in s.players) {
        if (p.name.toLowerCase() == lower) {
          totalPaid += p.totalPaid;
          totalDue += p.amountDue;
          if (p.status == PaymentStatus.paid || p.status == PaymentStatus.free) {
            paidFullCount++;
          }
        }
      }
    }

    final total = joined.length;
    return {
      'totalSessions': total,
      'totalPaid': totalPaid,
      'totalDue': totalDue,
      'paymentRate': total > 0 ? (paidFullCount / total * 100).round() : 0,
      'lastSeen': lastSeen,
      'firstSeen': firstSeen,
    };
  }

  List<Map<String, dynamic>> paymentHistoryForPlayer(String playerName) {
    final history = <Map<String, dynamic>>[];
    for (final s in _sessions) {
      for (final p in s.players) {
        if (p.name.toLowerCase() == playerName.toLowerCase()) {
          history.add({'session': s, 'player': p});
        }
      }
    }
    history.sort((a, b) {
      final sa = a['session'] as Session;
      final sb = b['session'] as Session;
      return sb.date.compareTo(sa.date);
    });
    return history;
  }

  // ─── Capital ──────────────────────────────────────────────────────────────

  Future<void> addCapitalEntry(CapitalEntry entry) async {
    if (_uid == null) return;
    await _capitalRef.doc(entry.id).set(_stripNulls(entry.toJson()));
  }

  Future<void> deleteCapitalEntry(String id) async {
    if (_uid == null) return;
    await _capitalRef.doc(id).delete();
  }

  // ─── Settings ─────────────────────────────────────────────────────────────

  Future<void> updateSettings(AppSettings s) async {
    _settings = s;
    notifyListeners(); // Immediate local update for snappy UI
    if (_uid == null) return;
    // Only persist pricing to Firestore; QR paths live in payment_qr collection
    await _settingsRef.set({
      'defaultMalePrice': s.defaultMalePrice,
      'defaultFemalePrice': s.defaultFemalePrice,
      'currency': s.currency,
    }, SetOptions(merge: true));
  }

  // ─── Monthly chart data ───────────────────────────────────────────────────

  List<Map<String, dynamic>> last6MonthsProfit() {
    final result = <Map<String, dynamic>>[];
    final now = DateTime.now();
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final profit = _sessions
          .where((s) =>
              s.date.year == month.year && s.date.month == month.month)
          .fold(0.0, (acc, s) => acc + s.profit);
      result.add({'month': month, 'profit': profit});
    }
    return result;
  }

  List<Map<String, dynamic>> last6MonthsIncomeExpense() {
    final result = <Map<String, dynamic>>[];
    final now = DateTime.now();
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthSessions = _sessions.where(
          (s) => s.date.year == month.year && s.date.month == month.month);
      final income =
          monthSessions.fold(0.0, (acc, s) => acc + s.totalCollected);
      final expense =
          monthSessions.fold(0.0, (acc, s) => acc + s.totalCost);
      result.add({'month': month, 'income': income, 'expense': expense});
    }
    return result;
  }
}
