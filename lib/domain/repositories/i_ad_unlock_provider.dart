/// Provider que controla o desbloqueio temporario de acoes premium
/// apos o usuario assistir um rewarded ad.
abstract class IAdUnlockProvider {
  bool get isShareUnlocked;
  void setShareUnlocked(bool value);
}
