import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'house_session.dart';

/// The only things ShopList keeps on the phone: who this phone is, and its house.
class LocalStore {
  LocalStore(this._prefs);

  final SharedPreferences _prefs;

  static Future<LocalStore> open() async => LocalStore(await SharedPreferences.getInstance());

  /// Generated once per install. This is how the phone is identified: no login.
  String get memberId {
    final saved = _prefs.getString('member_id');
    if (saved != null) return saved;
    final id = const Uuid().v4();
    _prefs.setString('member_id', id);
    return id;
  }

  HouseSession? get session {
    final houseId = _prefs.getString('house_id');
    final code = _prefs.getString('house_code');
    final nickname = _prefs.getString('nickname');
    if (houseId == null || code == null || nickname == null) return null;
    return HouseSession(houseId: houseId, code: code, nickname: nickname, memberId: memberId);
  }

  Future<void> saveSession(HouseSession s) async {
    await _prefs.setString('house_id', s.houseId);
    await _prefs.setString('house_code', s.code);
    await _prefs.setString('nickname', s.nickname);
  }
}
