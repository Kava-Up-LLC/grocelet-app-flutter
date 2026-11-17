import 'package:app_shoplist/core/appambit/analytics.dart';
import 'package:app_shoplist/core/appambit/cloud_service.dart';
import 'package:app_shoplist/core/appambit/db_service.dart';
import 'package:app_shoplist/core/errors.dart';

class FakeAnalytics implements Analytics {
  final events = <String>[];
  @override
  void track(String event, [Map<String, String> properties = const {}]) => events.add(event);
}

/// Answers SQL by its first word; records writes. Set [offline] to fail everything.
class FakeDb implements DbService {
  List<DbRow> rows = [];
  final writes = <String>[];
  bool offline = false;

  @override
  Future<List<DbRow>> query(String sql, [List<Object?> params = const []]) async {
    if (offline) throw const AppFailure(FailureKind.noConnection);
    return rows;
  }

  @override
  Future<int> execute(String sql, [List<Object?> params = const []]) async {
    if (offline) throw const AppFailure(FailureKind.noConnection);
    writes.add(sql.split(' ').first);
    return 1;
  }
}

class FakeCloud implements CloudService {
  FakeCloud(this.answer);
  Map<String, dynamic> Function(String function, Map<String, dynamic> body) answer;
  final calls = <Map<String, dynamic>>[];

  @override
  Future<Map<String, dynamic>> call(String function, Map<String, dynamic> body) async {
    calls.add({'function': function, ...body});
    return answer(function, body);
  }
}

DbRow itemRow(String id, String name, {String? qty, bool checked = false, String by = 'm1', String at = '2026-11-17 10:00:00'}) =>
    {'id': id, 'name': name, 'quantity': qty, 'checked': checked ? 1 : 0, 'added_by': by, 'created_at': at};
