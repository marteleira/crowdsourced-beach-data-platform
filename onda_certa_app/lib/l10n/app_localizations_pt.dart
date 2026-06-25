// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => 'OndaCerta';

  @override
  String get appTagline => 'Real beaches. Real conditions.';

  @override
  String get appLocation => 'Arrábida Natural Park · Portugal';

  @override
  String get navHome => 'Início';

  @override
  String get navBeaches => 'Praias';

  @override
  String get navTides => 'Marés';

  @override
  String get navProfile => 'Perfil';

  @override
  String get continueAsGuest => 'Continuar como visitante';

  @override
  String get createAccount => 'Criar conta';

  @override
  String get signIn => 'Entrar';

  @override
  String get registerSubtitle =>
      'Regista-te para contribuíres com a comunidade';

  @override
  String get loginWelcomeBack => 'Bem-vindo de volta';

  @override
  String get fieldName => 'Nome';

  @override
  String get fieldNameHint => 'O teu nome';

  @override
  String get fieldEmail => 'Email';

  @override
  String get fieldEmailHint => 'o.teu@email.com';

  @override
  String get forgotPassword => 'Esqueci a password';

  @override
  String get termsOfService => 'Termos de Serviço';

  @override
  String get privacyPolicy => 'Política de Privacidade';

  @override
  String get authConsentPrefix => 'Ao continuar, aceitas os nossos ';

  @override
  String get authConsentAnd => ' e a nossa ';

  @override
  String get errorGoogleToken => 'Não foi possível obter o token Google';

  @override
  String get errorGoogleSignIn => 'Falha ao entrar com Google';

  @override
  String get loading => 'A carregar dados...';

  @override
  String get comingSoon => 'Em breve';

  @override
  String get settings => 'Definições';

  @override
  String get close => 'Fechar';

  @override
  String get viewAll => 'Ver tudo →';

  @override
  String get viewDetails => 'Ver detalhes →';

  @override
  String get viewBeaches => 'Ver todas →';

  @override
  String get tryAgain => 'Tentar de novo';

  @override
  String get liveLabel => 'live';

  @override
  String get recommended => 'Recomendada';

  @override
  String get updating => 'A atualizar...';

  @override
  String get updatePresence => 'Atualizar presença';

  @override
  String get seeAllBeaches => 'Ver todas as praias >';

  @override
  String get noLocationBanner =>
      'Sem acesso à localização não podes reportar condições nem votar.';

  @override
  String get sectionFavourites => 'FAVORITAS';

  @override
  String get sectionAlerts => 'ALERTAS ACTIVOS';

  @override
  String get noFavourites => 'Sem favoritas ainda';

  @override
  String get noFavouritesHint =>
      'Abre uma praia e guarda-a\npara acesso rápido aqui.';

  @override
  String get noAlerts => 'Sem alertas activos';

  @override
  String get bestBeachNow => 'Melhor Praia Agora';

  @override
  String tidesSection(String beach) {
    return 'MARÉS · $beach';
  }

  @override
  String get greetingMorning => 'Bom dia';

  @override
  String get greetingAfternoon => 'Boa tarde';

  @override
  String get greetingEvening => 'Boa noite';

  @override
  String get weatherAir => 'Ar';

  @override
  String get weatherWind => 'Vento';

  @override
  String get weatherWaves => 'Ondas';

  @override
  String get weatherRain => 'Chuva';

  @override
  String get flagStatusSafe => 'Seguras';

  @override
  String get flagStatusCaution => 'Cuidado';

  @override
  String get flagStatusDanger => 'Perigo';

  @override
  String get exploreTitle => 'Explorar';

  @override
  String get exploreMap => 'Mapa de praias';

  @override
  String get exploreMapSub => 'Ver todas no mapa';

  @override
  String get exploreTransport => 'Transportes';

  @override
  String get exploreTransportSub => 'Carris Metropolitana';

  @override
  String get exploreBeaches => 'Praias';

  @override
  String get exploreReport => 'Submeter reporte';

  @override
  String get exploreReportSub => 'Ajuda a comunidade';

  @override
  String get communityTitle => 'Comunidade';

  @override
  String communityReports(int count) {
    return '$count reportes activos';
  }

  @override
  String communityFooter(int beaches, int users) {
    return 'em $beaches praias · $users utilizadores online';
  }

  @override
  String get beachListTitle => 'Praias';

  @override
  String get searchHint => 'Pesquisar praia...';

  @override
  String get filterAll => 'Todas';

  @override
  String get filterSafe => 'Seguras';

  @override
  String get filterCaution => 'Cuidado';

  @override
  String get filterDanger => 'Perigo';

  @override
  String get filterNoData => 'Sem dados';

  @override
  String get beachCardView => 'Ver →';

  @override
  String get errorLoadBeaches => 'Não foi possível carregar as praias';

  @override
  String noBeachesForSearch(String query) {
    return 'Nenhuma praia encontrada para \"$query\"';
  }

  @override
  String get noBeachesForFilter => 'Nenhuma praia com este filtro';

  @override
  String get municipality => 'Arrábida';

  @override
  String get sectionWeather => 'Meteorologia';

  @override
  String get labelTemperature => 'Temperatura';

  @override
  String get labelRain => 'Chuva';

  @override
  String get labelOccupancy => 'Ocupação';

  @override
  String get labelConfidence => '% conf.';

  @override
  String get flagLiveTap => 'live · Toca para confirmar';

  @override
  String get flagProposeTap => 'Toca para propor a bandeira';

  @override
  String get errorFavourite => 'Erro ao actualizar favorito';

  @override
  String get tooFarToCheckin =>
      'Estás demasiado longe de uma praia para registar presença.';

  @override
  String get presenceRegistered => 'Presença registada!';

  @override
  String get fewUsersNote => 'Poucos utilizadores';

  @override
  String usersAtBeach(int count) {
    return '$count pessoas';
  }

  @override
  String get occupancyNote =>
      'a usar a app nesta praia nos últimos 20 min. Estimativa aproximada.';

  @override
  String get alertsTitle => 'Alertas da Comunidade';

  @override
  String alertsActive(int count) {
    return '$count activos';
  }

  @override
  String get mustBeAtBeachVote => 'Tens de estar na praia para votar';

  @override
  String get errorVoting => 'Erro ao votar. Tenta de novo.';

  @override
  String get notificationsTitle => 'Notificações';

  @override
  String get errorLoadNotifications => 'Erro ao carregar notificações';

  @override
  String get notificationsEmpty =>
      'As notificações sobre as praias aparecem aqui.';

  @override
  String get settingsGeneral => 'Geral';

  @override
  String get settingsNotifsEnabled => 'Notificações ativadas';

  @override
  String get settingsNotifsEnabledSub =>
      'Liga ou desliga todas as notificações';

  @override
  String get settingsCommunityAlerts => 'Alertas de comunidade';

  @override
  String get settingsCheckinAlerts => 'Alertas ao fazer check-in';

  @override
  String get settingsCheckinAlertsSub =>
      'Notifica quando chegares a uma praia com alertas';

  @override
  String get settingsProximityAlerts => 'Alertas de proximidade';

  @override
  String get settingsProximityAlertsSub =>
      'Alertas quando estás perto de uma praia';

  @override
  String get settingsProximityRadius => 'Raio de proximidade';

  @override
  String get settingsAlertTypes => 'Tipos de alerta';

  @override
  String get settingsJellyfish => 'Medusas';

  @override
  String get settingsStrongCurrent => 'Corrente forte';

  @override
  String get settingsPollution => 'Poluição';

  @override
  String get settingsRoughSea => 'Mar agitado';

  @override
  String get settingsMinSeverity => 'Severidade mínima';

  @override
  String get errorLoadSettings => 'Não foi possível carregar as notificações';

  @override
  String proximityRadiusValue(int meters) {
    return '$meters m';
  }

  @override
  String get accountTitle => 'Conta';

  @override
  String get errorLoadProfile => 'Não foi possível carregar o perfil';

  @override
  String get guestUser => 'Convidado';

  @override
  String get registeredUser => 'Utilizador';

  @override
  String get guestMode => 'Modo convidado';

  @override
  String reputationPoints(int count) {
    return '$count pontos de reputação';
  }

  @override
  String get flagLabelGreen => 'Segura';

  @override
  String get flagLabelYellow => 'Cuidado';

  @override
  String get flagLabelRed => 'Perigo';

  @override
  String get flagLabelPurple => 'Fechada';

  @override
  String get flagLabelUnknown => 'Desconhecida';

  @override
  String get flagDescGreen => 'Segura para nadar';

  @override
  String get flagDescYellow => 'Cuidado ao nadar';

  @override
  String get flagDescRed => 'Condições perigosas';

  @override
  String get flagDescPurple => 'Praia fechada';

  @override
  String get flagDescUnknown => 'Estado desconhecido';

  @override
  String get occupancyLow => 'Tranquila';

  @override
  String get occupancyMedium => 'Moderada';

  @override
  String get occupancyHigh => 'Lotada';

  @override
  String get occupancyAnimated => 'Animada';

  @override
  String get occupancyFull => 'Cheia';

  @override
  String get occupancyUnknown => 'Desconhecida';

  @override
  String get qualityExcellent => 'Excelente';

  @override
  String get qualityGood => 'Boa';

  @override
  String get qualitySufficient => 'Suficiente';

  @override
  String get qualityPoor => 'Má';

  @override
  String get qualityUnknown => 'Desconhecida';

  @override
  String get beachQualityExcellent => 'Excelente';

  @override
  String get beachQualityGood => 'Boa condição';

  @override
  String get beachQualityFair => 'Condição razoável';

  @override
  String get beachQualityPoor => 'Má condição';

  @override
  String get tideHigh => 'alta';

  @override
  String get tideLow => 'baixa';

  @override
  String get tidePrefixHigh => 'maré alta';

  @override
  String get tidePrefixLow => 'maré baixa';

  @override
  String get timeJustNow => 'agora mesmo';

  @override
  String get timeYesterday => 'ontem';

  @override
  String timeMinutes(int minutes) {
    return 'há $minutes min';
  }

  @override
  String timeHours(int hours) {
    return 'há ${hours}h';
  }

  @override
  String timeDays(int days) {
    return 'há $days dias';
  }

  @override
  String timeWeeks(int weeks) {
    return 'há $weeks sem.';
  }

  @override
  String timeMonths(int months) {
    return 'há $months meses';
  }

  @override
  String get guestVoteAlerts => 'Cria uma conta para votar nos alertas';

  @override
  String get guestSubmitReport => 'Cria uma conta para submeter avisos';

  @override
  String get guestConfirmFlag => 'Cria uma conta para confirmar bandeiras';

  @override
  String get guestProposeFlag => 'Cria uma conta para propor bandeiras';

  @override
  String get guestSaveContribs =>
      'Cria uma conta para guardar as tuas contribuições.';
}
