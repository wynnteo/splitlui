import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'receipt_capture.dart';

/// A durable, author-scoped outbox. Server remains authoritative.
/// Fund withdrawals and repayments deliberately do not use this queue.
class OfflineExpenseOutbox {
  OfflineExpenseOutbox._();
  static final instance = OfflineExpenseOutbox._();
  final _uuid = const Uuid();
  Database? _database;
  Future<Database>? _opening;
  bool _syncing = false;

  Future<Database> get database async {
    if (_database != null) return _database!;
    return _opening ??= _open();
  }

  Future<Database> _open() async {
    try {
    final root = await getApplicationDocumentsDirectory();
    final db = await openDatabase(p.join(root.path, 'splitlui_outbox.db'),
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE offline_expenses(
            operation_id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            group_id TEXT NOT NULL,
            title TEXT NOT NULL,
            amount TEXT NOT NULL,
            currency TEXT NOT NULL,
            rate_to_spending TEXT NOT NULL,
            paid_by TEXT NOT NULL,
            participants_json TEXT NOT NULL,
            receipt_path TEXT,
            receipt_date TEXT,
            remote_expense_id TEXT,
            status TEXT NOT NULL DEFAULT 'pending',
            last_error TEXT,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE INDEX offline_expenses_owner_group
          ON offline_expenses(user_id,group_id,created_at)
        ''');
        await db.execute('''
          CREATE TABLE offline_expense_cache(
            user_id TEXT NOT NULL,
            group_id TEXT NOT NULL,
            snapshot_json TEXT NOT NULL,
            saved_at TEXT NOT NULL,
            PRIMARY KEY(user_id, group_id)
          )
        ''');
        await db.execute('''
          CREATE TABLE offline_group_cache(
            user_id TEXT PRIMARY KEY,
            groups_json TEXT NOT NULL,
            saved_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE offline_member_cache(
            user_id TEXT NOT NULL,
            group_id TEXT NOT NULL,
            members_json TEXT NOT NULL,
            saved_at TEXT NOT NULL,
            PRIMARY KEY(user_id, group_id)
          )
        ''');
      });
    _database = db;
    return db;
    } catch (_) { _opening = null; rethrow; }
  }

  String get _userId {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw StateError('Sign in to save a shared expense');
    return user.id;
  }

  Future<void> queue({
    required String groupId,
    required String title,
    required String amount,
    required String currency,
    required String rateToSpending,
    required String paidBy,
    required List<String> participants,
    Uint8List? receipt,
    DateTime? receiptDate,
  }) async {
    final owner = _userId;
    final opId = _uuid.v4();
    String? path;
    if (receipt != null) {
      final root = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(root.path, 'pending_receipts'));
      await dir.create(recursive: true);
      path = p.join(dir.path, '$opId.jpg');
      // Persistent file is written BEFORE making the queued operation visible.
      await File(path).writeAsBytes(receipt, flush: true);
    }
    try {
      await (await database).insert('offline_expenses', {
        'operation_id': opId,
        'user_id': owner,
        'group_id': groupId,
        'title': title.trim(),
        'amount': amount,
        'currency': currency,
        'rate_to_spending': rateToSpending,
        'paid_by': paidBy,
        'participants_json': jsonEncode(participants),
        'receipt_path': path,
        'receipt_date': receiptDate == null ? null :
          receiptDate.toIso8601String().substring(0,10),
        'status': 'pending',
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {
      if (path != null) { try { await File(path).delete(); } catch (_) {} }
      rethrow;
    }
  }

  Future<void> cacheGroups(List<Map<String,dynamic>> groups) async {
    await (await database).insert('offline_group_cache',{
      'user_id':_userId, 'groups_json':jsonEncode(groups),
      'saved_at':DateTime.now().toUtc().toIso8601String(),
    },conflictAlgorithm:ConflictAlgorithm.replace);
  }

  Future<List<Map<String,dynamic>>> cachedGroups() async {
    final rows=await (await database).query('offline_group_cache',
      where:'user_id=?',whereArgs:[_userId],limit:1);
    if(rows.isEmpty) return [];
    return (jsonDecode(rows.first['groups_json'] as String) as List)
      .map((e)=>Map<String,dynamic>.from(e as Map)).toList();
  }

  Future<void> cacheMembers(
    String groupId, List<Map<String,dynamic>> members) async {
    await (await database).insert('offline_member_cache',{
      'user_id':_userId,'group_id':groupId,
      'members_json':jsonEncode(members),
      'saved_at':DateTime.now().toUtc().toIso8601String(),
    },conflictAlgorithm:ConflictAlgorithm.replace);
  }

  Future<List<Map<String,dynamic>>> cachedMembers(String groupId) async {
    final rows=await (await database).query('offline_member_cache',
      where:'user_id=? AND group_id=?',whereArgs:[_userId,groupId],limit:1);
    if(rows.isEmpty) return [];
    return (jsonDecode(rows.first['members_json'] as String) as List)
      .map((e)=>Map<String,dynamic>.from(e as Map)).toList();
  }

  Future<void> cacheExpenses(
    String groupId, List<Map<String,dynamic>> expenses) async {
    final owner = _userId;
    await (await database).insert('offline_expense_cache',{
      'user_id':owner, 'group_id':groupId,
      'snapshot_json':jsonEncode(expenses),
      'saved_at':DateTime.now().toUtc().toIso8601String(),
    },conflictAlgorithm:ConflictAlgorithm.replace);
  }

  Future<List<Map<String,dynamic>>> cachedExpenses(String groupId) async {
    final rows = await (await database).query('offline_expense_cache',
      where:'user_id=? AND group_id=?',whereArgs:[_userId,groupId],
      limit:1);
    if(rows.isEmpty) return [];
    final json=jsonDecode(rows.first['snapshot_json'] as String) as List;
    return json.map((x)=>Map<String,dynamic>.from(x as Map)).toList();
  }

  Future<List<Map<String, Object?>>> pending(String groupId) async {
    final rows = await (await database).query('offline_expenses',
      where: 'group_id=? AND user_id=?',
      whereArgs: [groupId, _userId],
      orderBy: 'created_at DESC');
    return rows;
  }

  /// Retry-safe even when the server committed an expense but the mobile
  /// connection failed before the response was received.
  Future<void> sync(String groupId) async {
    if (_syncing) return;
    final owner = _userId;
    _syncing = true;
    try {
      final db = await database;
      final rows = await db.query('offline_expenses',
        where: 'group_id=? AND user_id=?',
        whereArgs: [groupId, owner],orderBy: 'created_at ASC');
      for (final row in rows) {
        final id = row['operation_id'] as String;
        final receiptPath = row['receipt_path'] as String?;
        var remoteId = row['remote_expense_id'] as String?;
        try {
          if (remoteId == null) {
            remoteId = (await Supabase.instance.client.rpc(
              'add_trip_expense_offline', params: {
                'p_operation': id,
                'p_group': groupId,
                'p_title': row['title'],
                'p_amount': num.parse(row['amount'] as String),
                'p_currency': row['currency'],
                'p_rate_to_spending':
                  num.parse(row['rate_to_spending'] as String),
                'p_paid_by': row['paid_by'],
                'p_split_between': List<String>.from(
                  jsonDecode(row['participants_json'] as String) as List),
                'p_date': row['receipt_date'],
              })).toString();
            await db.update('offline_expenses', {
              'remote_expense_id': remoteId,
              'status': receiptPath == null ? 'synced' : 'receipt_pending',
              'last_error': null,
            },where: 'operation_id=? AND user_id=?',whereArgs: [id,owner]);
          }

          if (receiptPath != null) {
            // If upload+association succeeded but acknowledgement was lost,
            // never upload the receipt twice.
            final storage = ReceiptStorage();
            final existing = await storage.get(expenseId: remoteId);
            if (existing == null) {
              final bytes = await File(receiptPath).readAsBytes();
              await storage.upload(
                groupId:groupId, expenseId:remoteId, jpeg:bytes);
            }
          }

          // Only after both operations succeed is the local record retired.
          await db.delete('offline_expenses',
            where:'operation_id=? AND user_id=?',whereArgs:[id,owner]);
          if (receiptPath != null) {
            try { await File(receiptPath).delete(); } catch (_) {}
          }
        } catch (e) {
          // Keep the immutable request and any saved server UUID. Next retry
          // resumes without creating a second expense.
          await db.update('offline_expenses',{
            'status': remoteId == null ? 'needs_review' : 'receipt_pending',
            'last_error': e.toString().length > 300
              ? e.toString().substring(0,300) : e.toString(),
          },where:'operation_id=? AND user_id=?',whereArgs:[id,owner]);
          // A broken network should not spin through all subsequent items.
          break;
        }
      }
    } finally { _syncing = false; }
  }

  /// We do not expose local Delete for ambiguous requests; after a timeout
  /// the server may already have committed. Always retry the same UUID.
}
