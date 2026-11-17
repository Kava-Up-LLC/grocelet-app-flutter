import '../../../core/appambit/cloud_service.dart';
import '../../../core/errors.dart';
import '../../../core/house_session.dart';
import '../../../core/local_store.dart';

/// Creates or joins a house through the join_house cloud function, and remembers it.
class HouseRepository {
  HouseRepository({required CloudService cloud, required LocalStore store, required String platform})
      : _cloud = cloud,
        _store = store,
        _platform = platform;

  final CloudService _cloud;
  final LocalStore _store;
  final String _platform;

  HouseSession? get current => _store.session;

  Future<HouseSession> create(String nickname) => _joinHouse(action: 'create', nickname: nickname);

  Future<HouseSession> join(String code, String nickname) =>
      _joinHouse(action: 'join', code: code, nickname: nickname);

  /// Joins the saved house again so the cloud has this phone's current AppAmbit
  /// consumer id (what start_shopping sends the push to). Quiet: failures are ignored.
  Future<void> refreshMembership() async {
    final s = current;
    if (s == null) return;
    try {
      await _joinHouse(action: 'join', code: s.code, nickname: s.nickname);
    } on AppFailure {
      // Next start will try again.
    }
  }

  Future<HouseSession> _joinHouse({required String action, required String nickname, String? code}) async {
    final res = await _cloud.call('join_house', {
      'action': action,
      'code': ?code,
      'nickname': nickname,
      'member_id': _store.memberId,
      'platform': _platform,
    });
    if (res['ok'] != true) {
      throw AppFailure(
        res['error'] == 'HOUSE_NOT_FOUND' ? FailureKind.houseNotFound : FailureKind.unexpected,
        res['error'],
      );
    }
    final houseId = res['house_id'], houseCode = res['code'];
    if (houseId is! String || houseCode is! String) throw const AppFailure(FailureKind.unexpected, 'join_house: bad response');
    final session = HouseSession(
      houseId: houseId,
      code: houseCode,
      nickname: nickname,
      memberId: _store.memberId,
    );
    await _store.saveSession(session);
    return session;
  }
}
