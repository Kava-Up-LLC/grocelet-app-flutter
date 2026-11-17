/// The house this phone belongs to, remembered on the phone.
class HouseSession {
  const HouseSession({required this.houseId, required this.code, required this.nickname, required this.memberId});

  final String houseId;
  final String code;
  final String nickname;
  final String memberId;
}
