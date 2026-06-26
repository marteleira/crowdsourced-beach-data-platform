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
  String get appTagline => 'Praias reais. Condições reais.';

  @override
  String get appLocation => 'Parque Natural da Arrábida · Portugal';

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
  String get signInGoogle => 'Entrar com Google';

  @override
  String get signInEmail => 'Entrar com email';

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
  String get errorSignIn => 'Erro ao iniciar sessão. Tenta novamente.';

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
  String get retryAgain => 'Tentar novamente';

  @override
  String get cancelLabel => 'Cancelar';

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
  String get explorerName => 'explorador';

  @override
  String updatedAt(String time) {
    return 'Actualizado às $time';
  }

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
  String get homeSeaTemp => 'Temp. mar';

  @override
  String get homeActiveNow => 'Activos agora';

  @override
  String get homeAlerts => 'Alertas';

  @override
  String get homeFavViewAll => 'Ver\ntodas';

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
  String get weatherFeelsLike => 'Sensação';

  @override
  String get weatherHumidity => 'Humidade';

  @override
  String get weatherUv => 'UV';

  @override
  String windGusts(int gusts) {
    return 'raj. $gusts km/h';
  }

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
  String get beachAlertSingular => 'alerta ativo';

  @override
  String get beachAlertPlural => 'alertas ativos';

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
  String get seaConditionsTitle => 'Condições do Mar';

  @override
  String get seaWavePeriod => 'Período';

  @override
  String get seaTempLabel => 'Temp. Mar';

  @override
  String get tideDirRising => 'subindo';

  @override
  String get tideDirFalling => 'descendo';

  @override
  String get tideDirSteady => 'estável';

  @override
  String get tideDirRisingCap => 'Subindo';

  @override
  String get tideDirFallingCap => 'Descendo';

  @override
  String get tideDirSteadyCap => 'Estável';

  @override
  String get tidesPageTitle => 'Marés';

  @override
  String get tidesMoreDetails => 'MAIS DETALHES';

  @override
  String get tidesTodaySection => 'MARÉS DE HOJE';

  @override
  String get tidesNoData => 'Sem dados de marés disponíveis';

  @override
  String get tidesChartSection => 'GRÁFICO DA MARÉ';

  @override
  String get tidesNowLabel => 'AGORA';

  @override
  String get tidesCardTitle => 'Marés Hoje';

  @override
  String get tidesViewFull => 'Vista completa →';

  @override
  String get waterQualityTitle => 'Qualidade da Água';

  @override
  String waterQualityLastSampled(String date) {
    return 'Última avaliação em $date';
  }

  @override
  String waterQualityCachedMins(int minutes) {
    return 'cache $minutes min atrás';
  }

  @override
  String waterQualityCachedHours(int hours) {
    return 'cache ${hours}h atrás';
  }

  @override
  String waterQualityCachedDays(int days) {
    return 'cache ${days}d atrás';
  }

  @override
  String get waterQualityCached => 'dados em cache';

  @override
  String get transportCardTitle => 'Próximas Partidas';

  @override
  String get transportNoInfo => 'Sem informação de transportes para esta praia';

  @override
  String get transportNoDepartures => 'Sem partidas previstas';

  @override
  String transportNearbyStop(int count) {
    return '$count paragem próxima';
  }

  @override
  String transportNearbyStops(int count) {
    return '$count paragens próximas';
  }

  @override
  String get transportViewSchedules => 'Ver horários completos →';

  @override
  String get communityAlertsSectionTitle => 'ALERTAS DA COMUNIDADE';

  @override
  String get reportVerified => 'Verificado';

  @override
  String get reportVoteSingular => 'voto';

  @override
  String get reportVotePlural => 'votos';

  @override
  String get communityAlertsEmptyTitle => 'Tudo calmo!';

  @override
  String get communityAlertsEmptyBody =>
      'Sem alertas activos nesta praia.\nSe vires algo, reporta!';

  @override
  String get communityAlertsReportBtn => 'Reportar condição';

  @override
  String get errorLoadAlerts => 'Erro ao carregar alertas';

  @override
  String get alertTypeJellyfish => 'Medusas';

  @override
  String get alertTypeStrongCurrent => 'Corrente Forte';

  @override
  String get alertTypePollution => 'Poluição';

  @override
  String get alertTypeRoughSea => 'Mar Agitado';

  @override
  String get alertTypeOther => 'Outro';

  @override
  String get alertTypeDefault => 'Alerta';

  @override
  String get severityLow => 'Baixo';

  @override
  String get severityModerate => 'Moderado';

  @override
  String get severityHigh => 'Grave';

  @override
  String get reportSheetTitle => 'Reportar Condição';

  @override
  String get reportTypeSection => 'Tipo de condição';

  @override
  String get reportSeveritySection => 'Qual a gravidade?';

  @override
  String get reportSeverityLowSub => 'Preocupação menor';

  @override
  String get reportSeverityModerateSub => 'Risco notável';

  @override
  String get reportSeverityHighSub => 'Perigoso';

  @override
  String get reportNoteSection => 'Adicionar nota';

  @override
  String get reportNoteOptional => '(opcional)';

  @override
  String get reportNoteHint => 'Descreve o que observaste...';

  @override
  String get reportLocationNote =>
      'A tua localização aproximada será partilhada com este aviso.';

  @override
  String get reportSubmit => 'Submeter Aviso';

  @override
  String get reportSuccess => 'Aviso submetido com sucesso!';

  @override
  String get reportMustBeAtBeach =>
      'Tens de estar na praia para submeter um aviso';

  @override
  String get reportError => 'Erro ao submeter. Tenta de novo.';

  @override
  String get presenceSectionTitle => 'QUEM ESTÁ AQUI';

  @override
  String get presenceViewAll => 'Ver todos →';

  @override
  String get presencePerson => '1 pessoa';

  @override
  String presencePeople(int count) {
    return '$count pessoas';
  }

  @override
  String get presencePersonHere => '1 pessoa nesta praia agora';

  @override
  String presencePeopleHere(int count) {
    return '$count pessoas nesta praia agora';
  }

  @override
  String get presenceSharedProfile1 => '1 partilha o perfil';

  @override
  String presenceSharedProfiles(int count) {
    return '$count partilham o perfil';
  }

  @override
  String get presencePrivateNote =>
      'Nenhuma pessoa decidiu partilhar a localização.';

  @override
  String get presenceSheetTitle => 'Quem está aqui';

  @override
  String get presenceAnonymousUser => 'Utilizador Anónimo';

  @override
  String presencePrivateFooter1(int count) {
    return '+$count pessoa em modo privado';
  }

  @override
  String presencePrivateFooterN(int count) {
    return '+$count pessoas em modo privado';
  }

  @override
  String get presenceEmptyTitle1 => '1 pessoa está aqui';

  @override
  String presenceEmptyTitleN(int count) {
    return '$count pessoas estão aqui';
  }

  @override
  String get presenceEmptyPrivate =>
      'Nenhuma pessoa decidiu partilhar\na sua localização.';

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
  String get settingsFavBeaches => 'Praias favoritas';

  @override
  String get settingsFavAlertsEnabled => 'Alertas das minhas praias';

  @override
  String get settingsFavAlertsEnabledSub =>
      'Recebe alertas das praias que tens guardadas';

  @override
  String get settingsBeachStatus => 'Estado da praia';

  @override
  String get settingsFlagChange => 'Mudança de bandeira';

  @override
  String get settingsFlagChangeSub =>
      'Notifica quando o estado de segurança muda';

  @override
  String get settingsTideAlerts => 'Alertas de maré';

  @override
  String get settingsTideAlertsSub => 'Aviso antes de preia-mar e baixa-mar';

  @override
  String get settingsMyReports => 'Os meus avisos';

  @override
  String get settingsReportConfirmed => 'Aviso confirmado';

  @override
  String get settingsReportConfirmedSub =>
      'Quando a comunidade confirma um aviso teu';

  @override
  String get settingsReportRejected => 'Aviso rejeitado';

  @override
  String get settingsReportRejectedSub =>
      'Quando a comunidade rejeita um aviso teu';

  @override
  String get settingsQuietHours => 'Horas de silêncio';

  @override
  String get settingsQuietHoursEnabled => 'Ativar horas de silêncio';

  @override
  String get settingsQuietHoursEnabledSub =>
      'Sem notificações durante o período definido';

  @override
  String get settingsQuietStart => 'Início';

  @override
  String get settingsQuietEnd => 'Fim';

  @override
  String get settingsSeverityLow => 'Baixa';

  @override
  String get settingsSeverityMedium => 'Média';

  @override
  String get settingsSeverityHigh => 'Alta';

  @override
  String get privacyLocation => 'Localização';

  @override
  String get privacyLocationAccuracy => 'Precisão da localização';

  @override
  String get privacyLocationAccuracySub =>
      'Controla a precisão partilhada com outros utilizadores';

  @override
  String get privacyLocationExact => 'Exata';

  @override
  String get privacyLocationApprox => 'Aprox.';

  @override
  String get privacyLocationNone => 'Nenhuma';

  @override
  String get privacyPublicProfile => 'Perfil público';

  @override
  String get privacyNameVisible => 'Nome visível';

  @override
  String get privacyNameVisibleSub =>
      'Outros utilizadores podem ver o teu nome';

  @override
  String get privacyAvatarVisible => 'Avatar visível';

  @override
  String get privacyAvatarVisibleSub => 'As tuas iniciais aparecem nos avisos';

  @override
  String get privacyPresence => 'Presença & Atividade';

  @override
  String get privacyShowOnMap => 'Mostrar no mapa';

  @override
  String get privacyShowOnMapSub =>
      'A tua presença conta para a lotação da praia';

  @override
  String get privacyShareUsage => 'Partilhar dados de utilização';

  @override
  String get privacyShareUsageSub => 'Ajuda a melhorar a app de forma anónima';

  @override
  String get privacyMyData => 'Os meus dados';

  @override
  String get privacyExportData => 'Exportar os meus dados';

  @override
  String get privacyExportDataSub => 'Recebe uma cópia de tudo o que guardamos';

  @override
  String get privacyDeleteReports => 'Apagar todos os avisos';

  @override
  String get privacyDeleteReportsSub => 'Remove os teus avisos da plataforma';

  @override
  String get privacyDeleteAccount => 'Apagar conta';

  @override
  String get privacyDeleteAccountSub => 'Ação permanente e irreversível';

  @override
  String get privacyExporting => 'A exportar dados…';

  @override
  String privacyExportSaved(String filename) {
    return 'Guardado: $filename';
  }

  @override
  String privacyExportError(String error) {
    return 'Erro: $error';
  }

  @override
  String get privacyDeleteReportsConfirmTitle => 'Apagar todos os avisos?';

  @override
  String get privacyDeleteReportsConfirmBody =>
      'Todos os teus avisos serão removidos da plataforma. Os teus pontos de reputação serão mantidos.';

  @override
  String get privacyDeleteReportsSuccess => 'Avisos apagados com sucesso';

  @override
  String get privacyDeleteReportsError => 'Erro ao apagar avisos';

  @override
  String get privacyDeleteAccountConfirmTitle => 'Apagar conta?';

  @override
  String get privacyDeleteAccountConfirmBody =>
      'Esta ação é permanente. Todos os teus dados serão eliminados.\n\nEscreve APAGAR para confirmar:';

  @override
  String get privacyDeleteAccountConfirmWord => 'APAGAR';

  @override
  String get privacyDeleteAccountError => 'Erro ao apagar conta';

  @override
  String get privacyPendingTitle => 'Conta agendada para eliminação';

  @override
  String privacyPendingBody(String date) {
    return 'A tua conta e todos os teus dados serão eliminados definitivamente a $date.\n\nPodes cancelar esta ação até essa data.';
  }

  @override
  String get privacyCancelDeletion => 'Cancelar eliminação';

  @override
  String get privacyCancelling => 'A cancelar…';

  @override
  String get privacyCancelError =>
      'Erro ao cancelar a eliminação. Tenta de novo.';

  @override
  String get privacyDeleteLabel => 'Apagar';

  @override
  String get privacyDeleteAccountConfirmBtn => 'Apagar conta';

  @override
  String get accountTitle => 'Conta';

  @override
  String get errorLoadProfile => 'Não foi possível carregar o perfil';

  @override
  String get accountAvatarSection => 'Avatar';

  @override
  String get accountAvatarDefault => 'Avatar predefinido (iniciais)';

  @override
  String get accountAvatarChoose => 'Escolher avatar';

  @override
  String get accountAvatarPickerTitle => 'Escolhe o teu avatar';

  @override
  String get accountAvatarPickerSub => 'Toca num avatar para o selecionar.';

  @override
  String get accountAvatarDefaultLabel => 'Predefinido (iniciais)';

  @override
  String get accountAvatarDefaultSub => 'Mostra as iniciais do teu nome';

  @override
  String get accountPersonalSection => 'Informação Pessoal';

  @override
  String get accountNameEmpty => 'O nome não pode estar vazio';

  @override
  String get accountNameTooLong => 'Máximo 50 caracteres';

  @override
  String get accountSaveName => 'Guardar nome';

  @override
  String get accountNoChanges => 'Nenhuma alteração para guardar';

  @override
  String get accountProfileUpdated => 'Perfil atualizado com sucesso';

  @override
  String get accountProfileUpdateError => 'Não foi possível atualizar o perfil';

  @override
  String get accountAvatarUpdated => 'Avatar atualizado com sucesso';

  @override
  String get accountAvatarUpdateError => 'Não foi possível atualizar o avatar';

  @override
  String get accountUnexpectedError => 'Ocorreu um erro inesperado';

  @override
  String get accountEmailSection => 'Email';

  @override
  String get accountEmailNoGuest => 'Os convidados não têm email associado.';

  @override
  String get accountEmailNoGoogle =>
      'A tua conta Google não permite alterar o email aqui.';

  @override
  String get accountNewEmail => 'Novo email';

  @override
  String get accountNewEmailHint => 'novo@exemplo.com';

  @override
  String get accountEmailVerificationNote =>
      'A verificação será enviada para o novo email.';

  @override
  String get accountCurrentPasswordConfirm => 'Password atual (confirmação)';

  @override
  String get accountPasswordHint => '••••••••';

  @override
  String get accountEmailEmpty => 'Introduz um email';

  @override
  String get accountEmailInvalid => 'Email inválido';

  @override
  String get accountEmailUnchanged => 'O email não foi alterado';

  @override
  String get accountCurrentPasswordEmpty => 'Introduz a password atual';

  @override
  String get accountChangeEmail => 'Alterar email';

  @override
  String get accountPasswordSection => 'Password';

  @override
  String get accountPasswordNoGuest => 'Os convidados não têm password.';

  @override
  String get accountPasswordNoGoogle => 'A tua conta Google não usa password.';

  @override
  String get accountCurrentPassword => 'Password atual';

  @override
  String get accountNewPassword => 'Nova password';

  @override
  String get accountConfirmPassword => 'Confirmar nova password';

  @override
  String get accountPasswordMismatch => 'As passwords não coincidem';

  @override
  String get accountConfirmPasswordEmpty => 'Confirma a nova password';

  @override
  String get accountPasswordChanged =>
      'Password alterada. Inicia sessão novamente nos outros dispositivos.';

  @override
  String get accountPasswordChangeError =>
      'Não foi possível alterar a password';

  @override
  String get accountChangePassword => 'Alterar password';

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
  String get levelNew => 'Novo';

  @override
  String get levelRegular => 'Regular';

  @override
  String get levelContributor => 'Contribuidor';

  @override
  String get levelVeteran => 'Veterano';

  @override
  String get levelNextLabel => 'Próximo nível';

  @override
  String levelPointsLeft(int count) {
    return '$count pts restantes';
  }

  @override
  String get levelMaxReached => '🏄 Nível máximo!';

  @override
  String get statReports => 'Avisos';

  @override
  String get statStreak => 'Streak';

  @override
  String get statAccuracy => 'Precisão';

  @override
  String get guestBannerTitle => 'Estás em modo convidado';

  @override
  String get achievementsTitle => 'Conquistas';

  @override
  String get achievementFirstReport => 'Primeira Onda';

  @override
  String get achievementTideWatcher => 'Guardião das Marés';

  @override
  String get achievement10Reports => '10 Avisos';

  @override
  String get achievementAccurate => 'Preciso';

  @override
  String get achievementStreak10 => '10 Dias';

  @override
  String get achievementRegular => 'Regular';

  @override
  String get achievementContributor => 'Contribuidor';

  @override
  String get achievementVeteran => 'Veterano';

  @override
  String get recentActivityTitle => 'Atividade Recente';

  @override
  String get eventReportSubmitted => 'Aviso submetido';

  @override
  String get eventFirstReportBonus => 'Primeiro aviso!';

  @override
  String get eventReportConfirmed => 'Aviso confirmado pela comunidade';

  @override
  String get eventReportContradicted => 'Aviso rejeitado pela comunidade';

  @override
  String get eventFlagConfirmed => 'Proposta de bandeira confirmada';

  @override
  String get eventFlagContradicted => 'Proposta de bandeira rejeitada';

  @override
  String get eventConfirmationAccurate => 'Confirmação correta';

  @override
  String eventConfirmationContradicted(String color) {
    return 'Confirmação precisa — bandeira $color contradita';
  }

  @override
  String eventConfirmationVerified(String color) {
    return 'Confirmação precisa — bandeira $color verificada';
  }

  @override
  String get eventSpamPenalty => 'Penalidade por spam';

  @override
  String get settingsAccountTitle => 'Definições da Conta';

  @override
  String get settingsFavouritesTitle => 'Praias Favoritas';

  @override
  String get settingsPrivacyTitle => 'Privacidade & Dados';

  @override
  String get settingsAboutTitle => 'Sobre OndaCerta';

  @override
  String get signOut => 'Terminar Sessão';

  @override
  String get signOutTitle => 'Terminar sessão?';

  @override
  String get signOutBody => 'Tens a certeza que queres sair da tua conta?';

  @override
  String get signOutCancel => 'Cancelar';

  @override
  String get signOutConfirm => 'Sair';

  @override
  String get favouritesScreenTitle => 'Praias Favoritas';

  @override
  String get favouritesSaved1 => '1 praia guardada';

  @override
  String favouritesSavedN(int count) {
    return '$count praias guardadas';
  }

  @override
  String get favouriteAlertSingular => 'alerta';

  @override
  String get favouriteAlertPlural => 'alertas';

  @override
  String favouriteRemoveTitle(String name) {
    return 'Remover \"$name\"?';
  }

  @override
  String get favouriteRemoveBody =>
      'Esta praia será removida das tuas favoritas.';

  @override
  String get removeLabel => 'Remover';

  @override
  String get errorRemoveFavourite => 'Erro ao remover favorito';

  @override
  String get favouritesEmptyTitle => 'Sem praias favoritas';

  @override
  String get favouritesEmptyHint =>
      'Abre uma praia e toca no coração\npara a guardar aqui.';

  @override
  String get errorLoadFavourites => 'Erro ao carregar favoritos';

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
  String get activityLabelUnverified => 'Não verificado';

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

  @override
  String get transportScreenTitle => 'Transportes';

  @override
  String get transportFlagNoInfo => 'Sem info';

  @override
  String transportWavesLabel(String height) {
    return '${height}m ondas';
  }

  @override
  String get transportArrivingSoon => 'A chegar';

  @override
  String get transportNextDeparturesSection => 'PRÓXIMAS PARTIDAS';

  @override
  String transportWalkMins(int mins) {
    return '$mins min a pé até à praia';
  }

  @override
  String transportNextDep(String time) {
    return 'Próxima: $time';
  }

  @override
  String transportWalkTo(String beach) {
    return 'Ir a pé para $beach';
  }

  @override
  String transportWalkToMins(String beach, int mins) {
    return 'Ir a pé para $beach ($mins min)';
  }

  @override
  String transportWalkToMinsFromStop(String beach, int mins) {
    return 'Ir a pé para $beach ($mins min da paragem)';
  }

  @override
  String get transportDisclaimerLive =>
      'Horários Carris Metropolitana. Dados em tempo real quando disponível — verificar nas paragens.';

  @override
  String get transportDisclaimerCache =>
      'Horários Carris Metropolitana. Dados em cache — verificar nas paragens.';

  @override
  String get transportEmpty => 'Sem transportes disponíveis\npara esta praia';

  @override
  String get transportLoadError => 'Não foi possível carregar os transportes';

  @override
  String get emailNameEmpty => 'Introduz o teu nome';

  @override
  String get emailEmpty => 'Introduz o email';

  @override
  String get emailInvalidSimple => 'Email inválido';

  @override
  String get emailAlreadyRegisteredTitle => 'Email já registado';

  @override
  String get emailAlreadyRegisteredBody =>
      'Este email já tem uma conta. Entra com a tua password.';

  @override
  String get emailRegisterError => 'Erro ao criar conta. Verifica os dados.';

  @override
  String get emailLoginError => 'Email ou password incorrectos.';

  @override
  String get connectionError => 'Erro de ligação. Tenta novamente.';

  @override
  String get emailAlreadyHaveAccount => 'Já tens conta? ';

  @override
  String get emailNoAccountYet => 'Ainda não tens conta? ';

  @override
  String get flagColorGreen => 'verde';

  @override
  String get flagColorYellow => 'amarela';

  @override
  String get flagColorRed => 'vermelha';

  @override
  String get flagColorPurple => 'roxa';

  @override
  String get flagColorGreenCap => 'Verde';

  @override
  String get flagColorYellowCap => 'Amarela';

  @override
  String get flagColorRedCap => 'Vermelha';

  @override
  String get flagColorPurpleCap => 'Roxa';

  @override
  String get flagProposeTitle => 'Propor Bandeira';

  @override
  String get flagProposeRequirement =>
      'Tens de estar na praia e ter reputação ≥ 25 para propor.';

  @override
  String get flagProposeQuestion => 'Qual é a bandeira actual?';

  @override
  String get flagProposeDescGreen => 'Seguro para nadar';

  @override
  String get flagProposeDescYellow => 'Nadar com precaução';

  @override
  String get flagProposeDescRed => 'Proibido nadar';

  @override
  String get flagProposeDescPurple => 'Animais marinhos presentes';

  @override
  String get flagProposeNoRep =>
      'Ainda não tens reputação suficiente (mínimo: 25). Continua a contribuir com alertas e confirmações!';

  @override
  String get flagProposeNotPresent =>
      'Tens de estar na praia (nos últimos 10 min) para propor uma bandeira.';

  @override
  String get flagProposeUnavailable =>
      'Esta praia não tem sistema de bandeiras físicas.';

  @override
  String get flagProposeGenericError => 'Algo correu mal. Tenta de novo.';

  @override
  String flagProposeSubmit(String color) {
    return 'Propor bandeira $color';
  }

  @override
  String get flagProposeSuccessApplied => 'Bandeira atualizada!';

  @override
  String get flagProposeSuccessPending => 'Proposta submetida!';

  @override
  String get flagProposeSuccessBodyApplied =>
      'A tua reputação deu-te autoridade para aplicar a bandeira directamente.';

  @override
  String get flagProposeSuccessBodyPending =>
      'A comunidade irá confirmar a tua proposta em breve.';

  @override
  String flagProposeFlagLabel(String color) {
    return 'Bandeira $color';
  }

  @override
  String get flagConfirmQuestionPrefix => 'A bandeira ainda está ';

  @override
  String get flagConfirmQuestionSuffix => '?';

  @override
  String get flagConfirmYesPrefix => 'Sim, ainda ';

  @override
  String get flagConfirmNo => 'Não, mudou';

  @override
  String get flagConfirmUnsure => 'Não tenho a certeza';

  @override
  String get flagConfirmRateLimited =>
      'Já confirmaste a bandeira desta praia na última hora.';

  @override
  String get flagConfirmError => 'Algo correu mal. Tenta de novo.';

  @override
  String get flagConfirmThankYou => 'Obrigado!';

  @override
  String get flagConfirmSuccessBody =>
      'A tua confirmação ajuda a comunidade\na estar sempre bem informada.';

  @override
  String get communityConfidence => 'Confiança da comunidade';

  @override
  String confidencePercent(int pct) {
    return '$pct% de confiança';
  }

  @override
  String confidencePercentShort(int pct) {
    return '$pct% confiança';
  }

  @override
  String get flagNameGreen => 'Bandeira Verde';

  @override
  String get flagNameYellow => 'Bandeira Amarela';

  @override
  String get flagNameRed => 'Bandeira Vermelha';

  @override
  String get flagNamePurple => 'Bandeira Roxa';

  @override
  String get flagNameUnknown => 'Estado Desconhecido';

  @override
  String get flagSafetyGreen => 'Seguro para nadar';

  @override
  String get flagSafetyYellow => 'Nadar com precaução';

  @override
  String get flagSafetyRed => 'Proibido nadar';

  @override
  String get flagSafetyPurple => 'Animais marinhos presentes';

  @override
  String get flagSafetyUnknown => 'Estado desconhecido';

  @override
  String confidencePct(int pct) {
    return '$pct% conf.';
  }

  @override
  String get atTimePrep => 'às';

  @override
  String get forgotPasswordTitle => 'Recuperar password';

  @override
  String get forgotPasswordBody =>
      'Introduz o teu email. Enviamos um código de 6 dígitos para poderes definir uma nova password.';

  @override
  String get forgotPasswordSubmit => 'Enviar código';

  @override
  String get forgotPasswordSendError =>
      'Erro ao enviar o código. Tenta novamente.';

  @override
  String get emailVerifyTitle => 'Confirma o teu email';

  @override
  String get emailVerifyBody =>
      'Enviámos um código de 6 dígitos para o teu email.\nIntroduz o código abaixo para continuares.';

  @override
  String get emailVerifyButton => 'Verificar';

  @override
  String get emailVerifyCodeInvalid => 'Código inválido. Tenta de novo.';

  @override
  String get resetCodeTitle => 'Verifica o teu email';

  @override
  String resetCodeBody(String email) {
    return 'Enviámos um código de 6 dígitos para $email.';
  }

  @override
  String get resetCodeContinue => 'Continuar';

  @override
  String get resetNewPasswordTitle => 'Nova password';

  @override
  String get resetNewPasswordBody =>
      'Escolhe uma nova password para a tua conta.';

  @override
  String get resetNewPasswordConfirmLabel => 'Confirmar password';

  @override
  String get resetNewPasswordSubmit => 'Alterar password';

  @override
  String get resetPasswordSuccessTitle => 'Password alterada!';

  @override
  String get resetPasswordSuccessBody =>
      'A tua password foi actualizada com sucesso.\nPodes entrar com a nova password.';

  @override
  String get resetPasswordError =>
      'Erro ao alterar a password. Tenta novamente.';

  @override
  String get codeResend => 'Reenviar código';

  @override
  String codeResendCooldown(int secs) {
    return 'Reenviar código (${secs}s)';
  }

  @override
  String codeResendShortCooldown(int secs) {
    return 'Reenviar (${secs}s)';
  }

  @override
  String get codeSentSnack => 'Novo código enviado para o teu email.';

  @override
  String get codeResendError => 'Erro ao reenviar o código.';

  @override
  String get codeConfirmEmpty => 'Confirma a nova password';
}
