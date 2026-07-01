/// Userfacing string constants
///
/// All hardcoded UI strings live here so they are easy to find and replace
/// when adding i18n support, Import this class instead of inlining literals
///
/// Strings with runtime parameters are static methods rather than constants
library;

class AppStrings {
  // ---------------------------------------------------------------------------
  // App branding
  // -------------------------------------------------------------------------
  static const String appName           = 'OndaCerta';
  static const String appTagline        = 'Real beaches. Real conditions.';
  static const String appLocation       = 'Arrábida Natural Park · Portugal';

  // --------------------------------------------------------------------------
  // Bottom navigation
  // ---------------------------------------------------------------------------
  static const String navHome           = 'Início';
  static const String navBeaches        = 'Praias';
  static const String navTides          = 'Marés';
  static const String navProfile        = 'Perfil';

  // ---------------------------------------------------------------------------
  // Auth
  // ---------------------------------------------------------------------------
  static const String continueAsGuest   = 'Continuar como visitante';
  static const String createAccount     = 'Criar conta';
  static const String signIn            = 'Entrar';
  static const String registerSubtitle  = 'Regista-te para contribuíres com a comunidade';
  static const String loginWelcomeBack  = 'Bem-vindo de volta';
  static const String fieldName         = 'Nome';
  static const String fieldNameHint     = 'O teu nome';
  static const String fieldEmail        = 'Email';
  static const String fieldEmailHint    = 'o.teu@email.com';
  static const String forgotPassword    = 'Esqueci a password';
  static const String termsOfService    = 'Termos de Serviço';
  static const String privacyPolicy     = 'Política de Privacidade';
  static const String authConsentPrefix = 'Ao continuar, aceitas os nossos ';
  static const String authConsentAnd    = ' e a nossa ';
  static const String errorGoogleToken  = 'Não foi possível obter o token Google';
  static const String errorGoogleSignIn = 'Falha ao entrar com Google';

  // --------------------------------------------------------------------------
  // Common UI
  // ---------------------------------------------------------------------------
  static const String loading           = 'A carregar dados...';
  static const String comingSoon        = 'Em breve';
  static const String settings          = 'Definições';
  static const String close             = 'Fechar';
  static const String viewAll           = 'Ver tudo →';
  static const String viewDetails       = 'Ver detalhes →';
  static const String viewBeaches       = 'Ver todas →';
  static const String tryAgain          = 'Tentar de novo';
  static const String liveLabel         = 'live';
  static const String recommended       = 'Recomendada';
  static const String updating          = 'A atualizar...';
  static const String updatePresence    = 'Atualizar presença';
  static const String seeAllBeaches     = 'Ver todas as praias >';

  // ---------------------------------------------------------------------------
  // Location
  // --------------------------------------------------------------------------
  static const String noLocationBanner  = 'Sem acesso à localização não podes reportar condições nem votar.';

  // -------------------------------------------------------------------------  
  /// Home screen — sections
  // ---------------------------------------------------------------------------
  static const String sectionFavourites = 'FAVORITAS';
  static const String sectionAlerts     = 'ALERTAS ACTIVOS';
  static const String noFavourites      = 'Sem favoritas ainda';
  static const String noFavouritesHint  = 'Abre uma praia e guarda-a\npara acesso rápido aqui.';
  static const String noAlerts          = 'Sem alertas activos';
  static const String bestBeachNow      = 'Melhor Praia Agora';

  static String tidesSection(String beach) => 'MARÉS · ${beach.toUpperCase()}';

  // ---------------------------------------------------------------------------
  // Home screen — greetings
  // ---------------------------------------------------------------------------
  static const String greetingMorning   = 'Bom dia';
  static const String greetingAfternoon = 'Boa tarde';
  static const String greetingEvening   = 'Boa noite';
  static const List<String> dayNames    = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];
  static const List<String> monthNames  = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];

  // ---------------------------------------------------------------------------
  // Home screen — weather strip labels
  // ---------------------------------------------------------------------------
  static const String weatherAir        = 'Ar';
  static const String weatherWind       = 'Vento';
  static const String weatherWaves      = 'Ondas';
  static const String weatherRain       = 'Chuva';

  // ---------------------------------------------------------------------------
  // Home screen — flag status pills
  // ---------------------------------------------------------------------------
  static const String flagStatusSafe    = 'Seguras';
  static const String flagStatusCaution = 'Cuidado';
  static const String flagStatusDanger  = 'Perigo';

  // ---------------------------------------------------------------------------
  // Home screen — explore section
  // ---------------------------------------------------------------------------
  static const String exploreTitle      = 'Explorar';
  static const String exploreMap        = 'Mapa de praias';
  static const String exploreMapSub     = 'Ver todas no mapa';
  static const String exploreTransport  = 'Transportes';
  static const String exploreTransportSub = 'Carris Metropolitana';
  static const String exploreBeaches    = 'Praias';
  static const String exploreReport     = 'Submeter aviso';
  static const String exploreReportSub  = 'Ajuda a comunidade';

  // ---------------------------------------------------------------------------
  // Home screen — community strip
  // -------------------------------------------------------------------------
  static const String communityTitle    = 'Comunidade';
  static String communityReports(int n) => '$n avisos activos';
  static String communityFooter(int beaches, int users) =>
      'em $beaches praias · $users utilizadores online';

  // ---------------------------------------------------------------------------
  // Beach list screen
  // ---------------------------------------------------------------------------
  static const String beachListTitle    = 'Praias';
  static const String searchHint        = 'Pesquisar praia...';
  static const String filterAll         = 'Todas';
  static const String filterSafe        = 'Seguras';
  static const String filterCaution     = 'Cuidado';
  static const String filterDanger      = 'Perigo';
  static const String filterNoData      = 'Sem dados';
  static const String beachCardView     = 'Ver →';
  static const String errorLoadBeaches  = 'Não foi possível carregar as praias';
  static String noBeachesForSearch(String q) => 'Nenhuma praia encontrada para "$q"';
  static const String noBeachesForFilter = 'Nenhuma praia com este filtro';

  // ------------------------------------------------------------------------
  // Beach detail screen
  // ---------------------------------------------------------------------------
  static const String municipality      = 'Arrábida';   // fallback municipality
  static const String sectionWeather    = 'Meteorologia';
  static const String labelTemperature  = 'Temperatura';
  static const String labelRain         = 'Chuva';
  static const String labelOccupancy    = 'Ocupação';
  static const String labelConfidence   = '% conf.';
  static const String flagLiveTap       = 'live · Toca para confirmar';
  static const String flagProposeTap    = 'Toca para propor a bandeira';
  static const String errorFavourite    = 'Erro ao actualizar favorito';
  static const String tooFarToCheckin   = 'Estás demasiado longe de uma praia para registar presença.';
  static const String presenceRegistered = 'Presença registada!';
  static const String fewUsersNote      = 'Poucos utilizadores';
  static String usersAtBeach(int n)     => '$n pessoas';
  static const String occupancyNote     = 'a usar a app nesta praia nos últimos 20 min. Estimativa aproximada.';

  // -
  // --------------------------------------------------------------------------
  // Community / alerts screen
  // ---------------------------------------------------------------------------
  static const String alertsTitle       = 'Alertas da Comunidade';
  static String alertsActive(int n)     => '$n activos';
  static const String mustBeAtBeachVote = 'Tens de estar na praia para votar';
  static const String errorVoting       = 'Erro ao votar. Tenta de novo.';

  // ---------------------------------------------------------------------------
  // Notifications screen
  // ------------------------------------------------------------------------
  static const String notificationsTitle = 'Notificações';
  static const String errorLoadNotifications = 'Erro ao carregar notificações';
  static const String notificationsEmpty = 'As notificações sobre as praias aparecem aqui.';

  // --------------------------------------------------------------------------
  // Notification settings
  // ---------------------------------------------------------------------------
  static const String settingsGeneral        = 'Geral';
  static const String settingsNotifsEnabled  = 'Notificações ativadas';
  static const String settingsNotifsEnabledSub = 'Liga ou desliga todas as notificações';
  static const String settingsCommunityAlerts = 'Alertas de comunidade';
  static const String settingsCheckinAlerts  = 'Alertas ao fazer check-in';
  static const String settingsCheckinAlertsSub = 'Notifica quando chegares a uma praia com alertas';
  static const String settingsProximityAlerts = 'Alertas de proximidade';
  static const String settingsProximityAlertsSub = 'Alertas quando estás perto de uma praia';
  static const String settingsProximityRadius = 'Raio de proximidade';
  static const String settingsAlertTypes    = 'Tipos de alerta';
  static const String settingsJellyfish     = 'Medusas';
  static const String settingsStrongCurrent = 'Corrente forte';
  static const String settingsPollution     = 'Poluição';
  static const String settingsRoughSea      = 'Mar agitado';
  static const String settingsMinSeverity   = 'Severidade mínima';
  static const String errorLoadSettings     = 'Não foi possível carregar as notificações';
  static String proximityRadiusValue(int meters) => '$meters m';

  // --------------------------------------------------------------------------
  // Account settings
  // ------------------------------------------------------------------------
  static const String accountTitle      = 'Conta';
  static const String errorLoadProfile  = 'Não foi possível carregar o perfil';

  // ---------------------------------------------------------------------------
  // Profile screen
  // --------------------------------------------------------------------------
  static const String guestUser         = 'Convidado';
  static const String registeredUser    = 'Utilizador';
  static const String guestMode         = 'Modo convidado';
  static String reputationPoints(int n) => '$n pontos de reputação';

  // -------------------------------------------------------------------------
  // Flag labels (from beach_helpers.dart — values moved here for i18n)
  // --------------------------------------------------------------------------
  static const String flagLabelGreen    = 'Segura';
  static const String flagLabelYellow   = 'Cuidado';
  static const String flagLabelRed      = 'Perigo';
  static const String flagLabelPurple   = 'Fechada';
  static const String flagLabelUnknown  = 'Desconhecida';

  static const String flagDescGreen     = 'Segura para nadar';
  static const String flagDescYellow    = 'Cuidado ao nadar';
  static const String flagDescRed       = 'Condições perigosas';
  static const String flagDescPurple    = 'Praia fechada';
  static const String flagDescUnknown   = 'Estado desconhecido';

  // ---------------------------------------------------------------------------
  // Occupancy labels (from beach_helpers.dart)
  // -------------------------------------------------------------------------
  static const String occupancyLow      = 'Tranquila';
  static const String occupancyMedium   = 'Moderada';
  static const String occupancyHigh     = 'Lotada';
  static const String occupancyAnimated = 'Animada';
  static const String occupancyFull     = 'Cheia';
  static const String occupancyUnknown  = 'Desconhecida';

  // -------------------------------------------------------------------------
  // Water quality labels (from beach_helpers.dart)
  // --------------------------------------------------------------------------
  static const String qualityExcellent  = 'Excelente';
  static const String qualityGood       = 'Boa';
  static const String qualitySufficient = 'Suficiente';
  static const String qualityPoor       = 'Má';
  static const String qualityUnknown    = 'Desconhecida';

  // ---------------------------------------------------------------------------
  // Beach quality (recommendation label) — was in English, now unified in PT
  // ---------------------------------------------------------------------------
  static const String beachQualityExcellent = 'Excelente';
  static const String beachQualityGood      = 'Boa condição';
  static const String beachQualityFair      = 'Condição razoável';
  static const String beachQualityPoor      = 'Má condição';

  // ---------------------------------------------------------------------------
  // Tide labels (from beach_helpers.dart)
  // --------------------------------------------------------------------------
  static const String tideHigh         = 'alta';
  static const String tideLow          = 'baixa';
  static const String tidePrefixHigh   = 'maré alta';
  static const String tidePrefixLow    = 'maré baixa';

  // --------------------------------------------------------------------------
  // Time / relative strings (from format_helpers.dart)
  // ---------------------------------------------------------------------------
  static const String timeJustNow      = 'agora mesmo';
  static const String timeYesterday    = 'ontem';
  static String timeMinutes(int m)     => 'há $m min';
  static String timeHours(int h)       => 'há ${h}h';
  static String timeDays(int d)        => 'há $d dias';
  static String timeWeeks(int w)       => 'há $w sem.';
  static String timeMonths(int m)      => 'há $m meses';

  // -----------------------------------------------------------------------
  // Guest-account upgrade prompts (original set)
  // ---------------------------------------------------------------------------
  static const String guestVoteAlerts   = 'Cria uma conta para votar nos alertas';
  static const String guestSubmitReport = 'Cria uma conta para submeter avisos';
  static const String guestConfirmFlag  = 'Cria uma conta para confirmar bandeiras';
  static const String guestProposeFlag  = 'Cria uma conta para propor bandeiras';
  static const String guestSaveContribs = 'Cria uma conta para guardar as tuas contribuições.';
}
