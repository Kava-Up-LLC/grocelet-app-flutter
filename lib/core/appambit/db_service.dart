import 'package:appambit_sdk_flutter/appambit_db.dart';

import '../errors.dart';

typedef DbRow = Map<String, dynamic>;

/// The app database (AppAmbit ShopListDb). The only place that touches the DB SDK.
abstract interface class DbService {
  Future<List<DbRow>> query(String sql, [List<Object?> params]);

  /// Returns the rows written.
  Future<int> execute(String sql, [List<Object?> params]);
}

class AppAmbitDbService implements DbService {
  const AppAmbitDbService();

  @override
  Future<List<DbRow>> query(String sql, [List<Object?> params = const []]) async =>
      (await _run(sql, params)).toMaps();

  @override
  Future<int> execute(String sql, [List<Object?> params = const []]) async =>
      (await _run(sql, params)).rowsWritten;

  Future<DbResult> _run(String sql, List<Object?> params) async {
    final s = inlineNulls(sql, params);
    final DbResult result;
    try {
      result = await AppAmbitDb.execute(s.sql, s.params.isEmpty ? null : s.params);
    } catch (e) {
      throw AppFailure(FailureKind.noConnection, e);
    }
    if (result.hasError) throw AppFailure(FailureKind.unexpected, result.error);
    return result;
  }

  /// Replaces each `?` bound to `null` with a literal `NULL` and drops that param.
  /// The Android SDK crashes serializing null params, and iOS sends `''` as NULL.
  /// A `?` inside a quoted literal is left alone.
  static ({String sql, List<Object?> params}) inlineNulls(String sql, List<Object?> params) {
    if (!params.contains(null)) return (sql: sql, params: params);
    final out = StringBuffer();
    final kept = <Object?>[];
    var i = 0;
    String? quote;
    for (final ch in sql.split('')) {
      if (quote != null) {
        if (ch == quote) quote = null;
        out.write(ch);
      } else if (ch == "'" || ch == '"') {
        quote = ch;
        out.write(ch);
      } else if (ch == '?') {
        final v = i < params.length ? params[i] : null;
        i++;
        if (v == null) {
          out.write('NULL');
        } else {
          out.write('?');
          kept.add(v);
        }
      } else {
        out.write(ch);
      }
    }
    return (sql: out.toString(), params: kept);
  }
}
