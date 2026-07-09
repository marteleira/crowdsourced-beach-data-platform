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
  String get appLocation => 'Setúbal · Portugal';

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
  String get errorGoogleToken => 'Não foi possível obter o token Google';

  @override
  String get errorGoogleSignIn => 'Falha ao entrar com Google';

  @override
  String get errorSignIn => 'Erro ao iniciar sessão. Tenta novamente.';

  @override
  String get loading => 'A carregar dados...';

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
  String get communityTitle => 'Comunidade';

  @override
  String communityReports(int count) {
    return '$count avisos activos';
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
  String get municipality => 'Setúbal';

  @override
  String get sectionWeather => 'Meteorologia';

  @override
  String get labelTemperature => 'Temperatura';

  @override
  String get labelRain => 'Chuva';

  @override
  String get labelOccupancy => 'Ocupação';

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
  String get privacyPendingBodyNoDate =>
      'A tua conta está agendada para eliminação.\n\nPodes cancelar esta ação antes da data prevista.';

  @override
  String get privacyCancelDeletion => 'Cancelar eliminação da conta';

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
  String get occupancyVotePrompt => 'Como está a praia agora?';

  @override
  String get occupancyVote1 => 'Vazia';

  @override
  String get occupancyVote2 => 'Tranquila';

  @override
  String get occupancyVote3 => 'Normal';

  @override
  String get occupancyVote4 => 'Movimentada';

  @override
  String get occupancyVote5 => 'Cheia';

  @override
  String get occupancyVoted => 'Obrigado pelo teu voto!';

  @override
  String get occupancyAlreadyVoted => 'Já votaste recentemente.';

  @override
  String get occupancyMustBePresent => 'Deves estar na praia para reportar.';

  @override
  String get occupancyDetailsTitle => 'Detalhes da ocupação';

  @override
  String occupancyAppUsers(int count) {
    return '$count utilizadores da app';
  }

  @override
  String occupancyReports(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'relatos',
      one: 'relato',
    );
    return '$count $_temp0 recentes';
  }

  @override
  String occupancyConfidencePct(int pct) {
    return 'Confiança: $pct%';
  }

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

  @override
  String get accountBannedTitle => 'Conta banida';

  @override
  String get accountBannedBody =>
      'A tua conta foi banida permanentemente por violação das regras da comunidade.';

  @override
  String accountBannedBodyReason(String reason) {
    return 'A tua conta foi banida permanentemente por violação das regras da comunidade.\n\nRazão: $reason';
  }

  @override
  String get accountSuspendedTitle => 'Conta suspensa';

  @override
  String get accountSuspendedBody =>
      'A tua conta está temporariamente suspensa.\n\nContinuas a poder ver as praias.';

  @override
  String accountSuspendedBodyUntil(String date) {
    return 'A tua conta está temporariamente suspensa até $date.\n\nContinuas a poder ver as praias. Podes voltar a contribuir após esse período.';
  }

  @override
  String get passwordEmpty => 'Introduz a password';

  @override
  String get passwordMinLength => 'Mínimo 8 caracteres';

  @override
  String get passwordNeedsUppercase => 'Precisa de uma letra maiúscula';

  @override
  String get passwordNeedsLowercase => 'Precisa de uma letra minúscula';

  @override
  String get passwordNeedsDigitOrSpecial =>
      'Precisa de um número ou caractere especial';

  @override
  String get passwordStrengthWeak => 'Fraca';

  @override
  String get passwordStrengthFair => 'Razoável';

  @override
  String get passwordStrengthGood => 'Boa';

  @override
  String get passwordStrengthStrong => 'Forte';

  @override
  String get passwordReq8Chars => '8+ caracteres';

  @override
  String get passwordReqUppercase => 'Letra maiúscula (A–Z)';

  @override
  String get passwordReqLowercase => 'Letra minúscula (a–z)';

  @override
  String get passwordReqDigitOrSpecial => 'Número ou caractere especial';

  @override
  String get translateNote => 'Traduzir';

  @override
  String get showOriginal => 'Ver original';

  @override
  String get translatedLabel => 'Traduzido';

  @override
  String get translateError => 'Erro ao traduzir · Tentar de novo';

  @override
  String get translateSameLanguage => 'Nota já no teu idioma';

  @override
  String get onboardingSkip => 'Saltar';

  @override
  String get onboardingNext => 'Seguinte';

  @override
  String get onboardingStart => 'Começar';

  @override
  String get onboardingTitle1 => 'Sabe antes de ir';

  @override
  String get onboardingBody1 =>
      'Consulta o estado do mar, ondas, maré e qualidade da água de cada praia em tempo real';

  @override
  String get onboardingTitle2 => 'Alertas da comunidade';

  @override
  String get onboardingBody2 =>
      'Medusas, correntes fortes ou lotação — recebe avisos reportados por quem está na praia.';

  @override
  String get onboardingTitle3 => 'As tuas praias favoritas';

  @override
  String get onboardingBody3 =>
      'Guarda as praias que mais visitas e recebe notificações sobre as condições.';

  @override
  String get legalLastUpdated => 'Última atualização: julho de 2026';

  @override
  String get termsIntroBody =>
      'Ao utilizares a OndaCerta aceitas estes Termos de Serviço. Lê-os com atenção antes de criar uma conta ou usar a aplicação.';

  @override
  String get termsSection1Heading => '1. O Serviço';

  @override
  String get termsSection1Body =>
      'A OndaCerta é uma aplicação de informação sobre as praias do Parque Natural da Arrábida que agrega dados oficiais de entidades como o IPMA, o Instituto Hidrográfico, a APA e a Carris Metropolitana, complementados por contribuições da comunidade de utilizadores.\n\nOs dados meteorológicos, de marés, qualidade da água e transportes têm caráter meramente informativo e podem conter atrasos, falhas ou imprecisões das fontes externas. A OndaCerta não é um serviço de emergência nem substitui a sinalização oficial das praias, a bandeira hasteada no areal ou as indicações dos nadadores-salvadores e das autoridades competentes. Em caso de emergência, liga sempre 112.';

  @override
  String get termsSection2Heading => '2. Conta de Utilizador';

  @override
  String get termsSection2Body =>
      'Podes usar a app como visitante (conta anónima associada ao teu dispositivo), com registo por email/password, ou com Google Sign-In.\n\nÉs responsável por manter a confidencialidade da tua password e por notificar-nos imediatamente em caso de uso não autorizado da tua conta.\n\nAo criar uma conta, declaras e garantes que tens pelo menos 13 anos de idade. Não verificamos tecnicamente a tua idade — confiamos na tua declaração — pelo que não deves criar uma conta, nem permitir que um menor de 13 anos o faça, se essa condição não se verificar.';

  @override
  String get termsSection3Heading => '3. Conteúdo Comunitário';

  @override
  String get termsSection3Body =>
      'Ao submeteres relatos (alforrecas, correntes fortes, poluição, mar agitado ou outros), propostas de bandeira, votos ou confirmações, garantes que a informação é verdadeira e reflete condições que observaste presencialmente.\n\nAlguns relatos só podem ser submetidos quando o sistema verifica, através do sinal de localização (heartbeat), que estás fisicamente perto da praia em causa.\n\nÉ proibido publicar conteúdo falso, enganoso, ofensivo ou que viole direitos de terceiros. Ao submeter conteúdo concedes à OndaCerta uma licença não exclusiva, mundial e gratuita para o exibir, distribuir e utilizar no âmbito do serviço, incluindo de forma agregada ou estatística.';

  @override
  String get termsSection4Heading => '4. Sistema de Reputação e Moderação';

  @override
  String get termsSection4Body =>
      'A tua reputação é calculada com base nas tuas contribuições e na forma como a comunidade as confirma ou rejeita. Relatos confirmados aumentam a reputação; relatos marcados como falsos reduzem-na.\n\nAlgumas funcionalidades (por exemplo, propor uma bandeira) podem exigir um nível mínimo de reputação, que nos reservamos o direito de ajustar a qualquer momento.\n\nSe a tua reputação descer de forma sustentada abaixo de um limite definido por nós, ou em caso de violação destes termos, a tua conta pode ser suspensa temporariamente ou banida de forma permanente, de forma automática ou manual, sem aviso prévio. Podes sempre contactar-nos (secção 10) para contestar uma decisão de suspensão ou banimento.';

  @override
  String get termsSection5Heading => '5. Comportamento Proibido';

  @override
  String get termsSection5Body =>
      'É proibido:\n\n• Submeter relatos, propostas de bandeira ou confirmações falsas, ou manipular votos de forma coordenada.\n\n• Usar ferramentas automáticas (bots), contas falsas ou GPS falsificado para gerar presença ou conteúdo artificial.\n\n• Tentar aceder a contas de outros utilizadores ou comprometer a segurança do serviço.\n\n• Recolher (\"scrape\") dados de outros utilizadores ou da app sem consentimento.\n\nA violação destas regras pode resultar na suspensão ou eliminação da conta, nos termos da secção 4.';

  @override
  String get termsSection6Heading => '6. Limitação de Responsabilidade';

  @override
  String get termsSection6Body =>
      'A informação apresentada na OndaCerta, incluindo dados de terceiros e conteúdo comunitário, é fornecida \"tal como está\", sem garantias de exatidão, atualidade ou disponibilidade. As condições do mar podem mudar rapidamente e de forma imprevisível.\n\nNa máxima medida permitida por lei, a OndaCerta e os seus criadores não se responsabilizam por lesões, afogamentos, danos materiais ou outros prejuízos resultantes do uso da app ou da confiança depositada nos dados nela exibidos, nem por imprecisões nos dados de APIs externas ou por conteúdo submetido por outros utilizadores.\n\nNunca entres na água nem tomes decisões de segurança apenas com base nesta app — segue sempre a sinalização física da praia e as indicações dos nadadores-salvadores.';

  @override
  String get termsSection7Heading => '7. Propriedade Intelectual';

  @override
  String get termsSection7Body =>
      'O nome \"OndaCerta\", o logótipo e os materiais visuais da aplicação são propriedade dos seus criadores. O código-fonte está disponível publicamente no GitHub nos termos da respetiva licença.\n\nOs dados das APIs externas são propriedade das respetivas entidades (IPMA, Instituto Hidrográfico, APA, Carris Metropolitana). O conteúdo comunitário (relatos, votos, propostas) pode ser reutilizado pela OndaCerta de forma agregada ou anonimizada, nos termos da secção 3.';

  @override
  String get termsSection8Heading => '8. Alterações e Rescisão';

  @override
  String get termsSection8Body =>
      'Podemos modificar ou descontinuar o serviço, ou atualizar estes termos, a qualquer momento. Alterações significativas serão comunicadas na app ou por email.\n\nPodes eliminar a tua conta a qualquer momento em Perfil → Privacidade → Eliminar conta. A eliminação tem um período de carência de 30 dias, durante o qual podes cancelar o pedido; após esse período, a conta e os dados de identificação são apagados de forma permanente e irreversível.';

  @override
  String get termsSection9Heading => '9. Lei Aplicável';

  @override
  String get termsSection9Body =>
      'Estes termos regem-se pela lei portuguesa. Qualquer litígio será submetido à jurisdição dos tribunais portugueses, sem prejuízo dos direitos que te assistam como consumidor ao abrigo de legislação imperativa aplicável.';

  @override
  String get termsSection10Heading => '10. Contacto';

  @override
  String get termsSection10Body =>
      'Para questões sobre estes termos, contacta-nos em ondacerta.app@gmail.com.';

  @override
  String get privacyIntroBody =>
      'A OndaCerta valoriza a tua privacidade. Esta política explica que dados recolhemos, como os usamos e quais são os teus direitos ao abrigo do Regulamento Geral de Proteção de Dados (RGPD).';

  @override
  String get privacySection1Heading => '1. Responsável pelo Tratamento';

  @override
  String get privacySection1Body =>
      'A OndaCerta é uma aplicação dedicada às praias do Parque Natural da Arrábida, Portugal.\nContacto: ondacerta.app@gmail.com';

  @override
  String get privacySection2Heading => '2. Dados que Recolhemos';

  @override
  String get privacySection2Body =>
      '• Dados de conta: email, nome apresentado e avatar selecionado (um ícone predefinido, não uma fotografia), quando te registas com email/password ou Google. Nas contas de visitante não recolhemos email nem nome, apenas um identificador anónimo do dispositivo.\n\n• Localização: enquanto a app está aberta e tens a permissão de localização ativa, enviamos periodicamente a tua posição GPS para calcular a tua proximidade a uma praia e o número de pessoas presentes (\"ocupação\"). As tuas coordenadas exatas nunca são mostradas a outros utilizadores — apenas o número total de pessoas por praia é público e, se ativares \"Mostrar no mapa\" nas definições de privacidade, o teu nome pode ficar associado a essa praia (sem coordenadas).\n\n• Conteúdo comunitário: relatos que submeteste (tipo, severidade, nota), votos e propostas ou confirmações de bandeira.\n\n• Notificações push: um token do dispositivo (Firebase Cloud Messaging), usado apenas para te enviar as notificações que ativares.\n\n• Identificador de dispositivo: nas contas de visitante, um identificador anónimo do dispositivo. Não recolhemos IMEI, número de telefone nem outros dados de hardware.\n\n• Dados de sessão: tokens de autenticação armazenados de forma segura no dispositivo (Keychain no iOS, Keystore no Android). Não usamos cookies.';

  @override
  String get privacySection3Heading => '3. Como Usamos os Dados';

  @override
  String get privacySection3Body =>
      '• Mostrar condições das praias e presença de utilizadores em tempo real.\n\n• Calcular o nível de ocupação de cada praia.\n\n• Enviar as notificações que configurares (proximidade, alertas da comunidade, marés, alteração de bandeira, entre outras).\n\n• Calcular a tua reputação com base nos relatos confirmados pela comunidade.\n\n• Manter a segurança do serviço e prevenir abuso (por exemplo, deteção de contas suspeitas).';

  @override
  String get privacySection4Heading => '4. Partilha de Dados';

  @override
  String get privacySection4Body =>
      'Não vendemos os teus dados pessoais nem os partilhamos com terceiros para fins publicitários.\n\nO teu nome e a praia onde estás podem ficar visíveis a outros utilizadores no mapa se ativares \"Mostrar no mapa\" nas definições de privacidade; podes desativar esta opção a qualquer momento.\n\nUsamos os seguintes serviços de terceiros, estritamente necessários ao funcionamento da app:\n\n• Google (Firebase Cloud Messaging), para enviar notificações push.\n\n• Google Sign-In, se optares por entrar com a tua conta Google.\n\nEstes serviços podem processar dados fora do Espaço Económico Europeu, ao abrigo dos mecanismos de transferência internacional de dados da Google (cláusulas contratuais-tipo da Comissão Europeia ou equivalente).';

  @override
  String get privacySection5Heading => '5. Retenção de Dados';

  @override
  String get privacySection5Body =>
      'Mantemos os teus dados enquanto a tua conta estiver ativa.\n\nOs relatos que submetes deixam de ser mostrados na app quando expiram (geralmente algumas horas), mas o conteúdo pode ser mantido para fins estatísticos.\n\nSe eliminares a tua conta, os teus dados de identificação (email, nome, tokens de sessão e de notificações) são apagados de forma permanente ao fim do período de carência de 30 dias. Os relatos, votos e propostas que submeteste deixam de estar associados à tua identidade nesse momento: os relatos com conteúdo informativo (por exemplo, o alerta de alforrecas que submeteste) podem ser mantidos desassociados da tua conta, enquanto votos, propostas de bandeira e confirmações são apagados.';

  @override
  String get privacySection6Heading => '6. Os Teus Direitos (RGPD)';

  @override
  String get privacySection6Body =>
      'Ao abrigo do RGPD tens direito a:\n\n• Acesso e portabilidade: exportar os teus dados em formato JSON em Perfil → Privacidade → Exportar dados.\n\n• Retificação: alterar o teu nome ou email nas definições de conta.\n\n• Apagamento: eliminar todos os teus relatos em Privacidade → Apagar os meus relatos, ou eliminar a conta completa em Privacidade → Eliminar conta (com período de carência de 30 dias, cancelável a qualquer momento).\n\n• Oposição: desativar a partilha de presença e de localização nas definições de privacidade.\n\nPara exercer qualquer um destes direitos, ou se tiveres dúvidas sobre o tratamento dos teus dados, contacta-nos em ondacerta.app@gmail.com. Tens também o direito de apresentar reclamação junto da Comissão Nacional de Proteção de Dados (CNPD), a autoridade de controlo em Portugal — www.cnpd.pt.';

  @override
  String get privacySection7Heading => '7. Segurança';

  @override
  String get privacySection7Body =>
      'As passwords são armazenadas com hash bcrypt, nunca em texto simples. Os tokens de autenticação são guardados no sistema de armazenamento seguro do dispositivo e toda a comunicação com o servidor é feita sobre HTTPS.';

  @override
  String get privacySection8Heading => '8. Alterações a esta Política';

  @override
  String get privacySection8Body =>
      'Podemos atualizar esta política ocasionalmente. Quando o fizermos, atualizamos a data no topo desta página; para alterações significativas, notificamos através da app ou por email.';

  @override
  String get authConsentJoiner => ' e\n';

  @override
  String get legalLinksSeparator => ' · ';
}
