/// User-facing string constants.
///
/// All hardcoded UI strings live here so they are easy to find and replace
/// when adding i18n support. Import this class instead of inlining literals.
library;

class AppStrings {
  // Guest-account upgrade prompts
  static const String guestVoteAlerts    = 'Cria uma conta para votar nos alertas';
  static const String guestSubmitReport  = 'Cria uma conta para submeter avisos';
  static const String guestConfirmFlag   = 'Cria uma conta para confirmar bandeiras';
  static const String guestProposeFlag   = 'Cria uma conta para propor bandeiras';
  static const String guestSaveContribs  = 'Cria uma conta para guardar as tuas contribuições.';
}
