import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt'),
  ];

  /// No description provided for @appName.
  ///
  /// In pt, this message translates to:
  /// **'OndaCerta'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In pt, this message translates to:
  /// **'Real beaches. Real conditions.'**
  String get appTagline;

  /// No description provided for @appLocation.
  ///
  /// In pt, this message translates to:
  /// **'Arrábida Natural Park · Portugal'**
  String get appLocation;

  /// No description provided for @navHome.
  ///
  /// In pt, this message translates to:
  /// **'Início'**
  String get navHome;

  /// No description provided for @navBeaches.
  ///
  /// In pt, this message translates to:
  /// **'Praias'**
  String get navBeaches;

  /// No description provided for @navTides.
  ///
  /// In pt, this message translates to:
  /// **'Marés'**
  String get navTides;

  /// No description provided for @navProfile.
  ///
  /// In pt, this message translates to:
  /// **'Perfil'**
  String get navProfile;

  /// No description provided for @continueAsGuest.
  ///
  /// In pt, this message translates to:
  /// **'Continuar como visitante'**
  String get continueAsGuest;

  /// No description provided for @createAccount.
  ///
  /// In pt, this message translates to:
  /// **'Criar conta'**
  String get createAccount;

  /// No description provided for @signIn.
  ///
  /// In pt, this message translates to:
  /// **'Entrar'**
  String get signIn;

  /// No description provided for @registerSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Regista-te para contribuíres com a comunidade'**
  String get registerSubtitle;

  /// No description provided for @loginWelcomeBack.
  ///
  /// In pt, this message translates to:
  /// **'Bem-vindo de volta'**
  String get loginWelcomeBack;

  /// No description provided for @fieldName.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get fieldName;

  /// No description provided for @fieldNameHint.
  ///
  /// In pt, this message translates to:
  /// **'O teu nome'**
  String get fieldNameHint;

  /// No description provided for @fieldEmail.
  ///
  /// In pt, this message translates to:
  /// **'Email'**
  String get fieldEmail;

  /// No description provided for @fieldEmailHint.
  ///
  /// In pt, this message translates to:
  /// **'o.teu@email.com'**
  String get fieldEmailHint;

  /// No description provided for @forgotPassword.
  ///
  /// In pt, this message translates to:
  /// **'Esqueci a password'**
  String get forgotPassword;

  /// No description provided for @termsOfService.
  ///
  /// In pt, this message translates to:
  /// **'Termos de Serviço'**
  String get termsOfService;

  /// No description provided for @privacyPolicy.
  ///
  /// In pt, this message translates to:
  /// **'Política de Privacidade'**
  String get privacyPolicy;

  /// No description provided for @authConsentPrefix.
  ///
  /// In pt, this message translates to:
  /// **'Ao continuar, aceitas os nossos '**
  String get authConsentPrefix;

  /// No description provided for @authConsentAnd.
  ///
  /// In pt, this message translates to:
  /// **' e a nossa '**
  String get authConsentAnd;

  /// No description provided for @errorGoogleToken.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível obter o token Google'**
  String get errorGoogleToken;

  /// No description provided for @errorGoogleSignIn.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao entrar com Google'**
  String get errorGoogleSignIn;

  /// No description provided for @loading.
  ///
  /// In pt, this message translates to:
  /// **'A carregar dados...'**
  String get loading;

  /// No description provided for @comingSoon.
  ///
  /// In pt, this message translates to:
  /// **'Em breve'**
  String get comingSoon;

  /// No description provided for @settings.
  ///
  /// In pt, this message translates to:
  /// **'Definições'**
  String get settings;

  /// No description provided for @close.
  ///
  /// In pt, this message translates to:
  /// **'Fechar'**
  String get close;

  /// No description provided for @viewAll.
  ///
  /// In pt, this message translates to:
  /// **'Ver tudo →'**
  String get viewAll;

  /// No description provided for @viewDetails.
  ///
  /// In pt, this message translates to:
  /// **'Ver detalhes →'**
  String get viewDetails;

  /// No description provided for @viewBeaches.
  ///
  /// In pt, this message translates to:
  /// **'Ver todas →'**
  String get viewBeaches;

  /// No description provided for @tryAgain.
  ///
  /// In pt, this message translates to:
  /// **'Tentar de novo'**
  String get tryAgain;

  /// No description provided for @liveLabel.
  ///
  /// In pt, this message translates to:
  /// **'live'**
  String get liveLabel;

  /// No description provided for @recommended.
  ///
  /// In pt, this message translates to:
  /// **'Recomendada'**
  String get recommended;

  /// No description provided for @updating.
  ///
  /// In pt, this message translates to:
  /// **'A atualizar...'**
  String get updating;

  /// No description provided for @updatePresence.
  ///
  /// In pt, this message translates to:
  /// **'Atualizar presença'**
  String get updatePresence;

  /// No description provided for @seeAllBeaches.
  ///
  /// In pt, this message translates to:
  /// **'Ver todas as praias >'**
  String get seeAllBeaches;

  /// No description provided for @noLocationBanner.
  ///
  /// In pt, this message translates to:
  /// **'Sem acesso à localização não podes reportar condições nem votar.'**
  String get noLocationBanner;

  /// No description provided for @sectionFavourites.
  ///
  /// In pt, this message translates to:
  /// **'FAVORITAS'**
  String get sectionFavourites;

  /// No description provided for @sectionAlerts.
  ///
  /// In pt, this message translates to:
  /// **'ALERTAS ACTIVOS'**
  String get sectionAlerts;

  /// No description provided for @noFavourites.
  ///
  /// In pt, this message translates to:
  /// **'Sem favoritas ainda'**
  String get noFavourites;

  /// No description provided for @noFavouritesHint.
  ///
  /// In pt, this message translates to:
  /// **'Abre uma praia e guarda-a\npara acesso rápido aqui.'**
  String get noFavouritesHint;

  /// No description provided for @noAlerts.
  ///
  /// In pt, this message translates to:
  /// **'Sem alertas activos'**
  String get noAlerts;

  /// No description provided for @bestBeachNow.
  ///
  /// In pt, this message translates to:
  /// **'Melhor Praia Agora'**
  String get bestBeachNow;

  /// No description provided for @tidesSection.
  ///
  /// In pt, this message translates to:
  /// **'MARÉS · {beach}'**
  String tidesSection(String beach);

  /// No description provided for @greetingMorning.
  ///
  /// In pt, this message translates to:
  /// **'Bom dia'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In pt, this message translates to:
  /// **'Boa tarde'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In pt, this message translates to:
  /// **'Boa noite'**
  String get greetingEvening;

  /// No description provided for @weatherAir.
  ///
  /// In pt, this message translates to:
  /// **'Ar'**
  String get weatherAir;

  /// No description provided for @weatherWind.
  ///
  /// In pt, this message translates to:
  /// **'Vento'**
  String get weatherWind;

  /// No description provided for @weatherWaves.
  ///
  /// In pt, this message translates to:
  /// **'Ondas'**
  String get weatherWaves;

  /// No description provided for @weatherRain.
  ///
  /// In pt, this message translates to:
  /// **'Chuva'**
  String get weatherRain;

  /// No description provided for @flagStatusSafe.
  ///
  /// In pt, this message translates to:
  /// **'Seguras'**
  String get flagStatusSafe;

  /// No description provided for @flagStatusCaution.
  ///
  /// In pt, this message translates to:
  /// **'Cuidado'**
  String get flagStatusCaution;

  /// No description provided for @flagStatusDanger.
  ///
  /// In pt, this message translates to:
  /// **'Perigo'**
  String get flagStatusDanger;

  /// No description provided for @exploreTitle.
  ///
  /// In pt, this message translates to:
  /// **'Explorar'**
  String get exploreTitle;

  /// No description provided for @exploreMap.
  ///
  /// In pt, this message translates to:
  /// **'Mapa de praias'**
  String get exploreMap;

  /// No description provided for @exploreMapSub.
  ///
  /// In pt, this message translates to:
  /// **'Ver todas no mapa'**
  String get exploreMapSub;

  /// No description provided for @exploreTransport.
  ///
  /// In pt, this message translates to:
  /// **'Transportes'**
  String get exploreTransport;

  /// No description provided for @exploreTransportSub.
  ///
  /// In pt, this message translates to:
  /// **'Carris Metropolitana'**
  String get exploreTransportSub;

  /// No description provided for @exploreBeaches.
  ///
  /// In pt, this message translates to:
  /// **'Praias'**
  String get exploreBeaches;

  /// No description provided for @exploreReport.
  ///
  /// In pt, this message translates to:
  /// **'Submeter reporte'**
  String get exploreReport;

  /// No description provided for @exploreReportSub.
  ///
  /// In pt, this message translates to:
  /// **'Ajuda a comunidade'**
  String get exploreReportSub;

  /// No description provided for @communityTitle.
  ///
  /// In pt, this message translates to:
  /// **'Comunidade'**
  String get communityTitle;

  /// No description provided for @communityReports.
  ///
  /// In pt, this message translates to:
  /// **'{count} reportes activos'**
  String communityReports(int count);

  /// No description provided for @communityFooter.
  ///
  /// In pt, this message translates to:
  /// **'em {beaches} praias · {users} utilizadores online'**
  String communityFooter(int beaches, int users);

  /// No description provided for @beachListTitle.
  ///
  /// In pt, this message translates to:
  /// **'Praias'**
  String get beachListTitle;

  /// No description provided for @searchHint.
  ///
  /// In pt, this message translates to:
  /// **'Pesquisar praia...'**
  String get searchHint;

  /// No description provided for @filterAll.
  ///
  /// In pt, this message translates to:
  /// **'Todas'**
  String get filterAll;

  /// No description provided for @filterSafe.
  ///
  /// In pt, this message translates to:
  /// **'Seguras'**
  String get filterSafe;

  /// No description provided for @filterCaution.
  ///
  /// In pt, this message translates to:
  /// **'Cuidado'**
  String get filterCaution;

  /// No description provided for @filterDanger.
  ///
  /// In pt, this message translates to:
  /// **'Perigo'**
  String get filterDanger;

  /// No description provided for @filterNoData.
  ///
  /// In pt, this message translates to:
  /// **'Sem dados'**
  String get filterNoData;

  /// No description provided for @beachCardView.
  ///
  /// In pt, this message translates to:
  /// **'Ver →'**
  String get beachCardView;

  /// No description provided for @errorLoadBeaches.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar as praias'**
  String get errorLoadBeaches;

  /// No description provided for @noBeachesForSearch.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma praia encontrada para \"{query}\"'**
  String noBeachesForSearch(String query);

  /// No description provided for @noBeachesForFilter.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma praia com este filtro'**
  String get noBeachesForFilter;

  /// No description provided for @municipality.
  ///
  /// In pt, this message translates to:
  /// **'Arrábida'**
  String get municipality;

  /// No description provided for @sectionWeather.
  ///
  /// In pt, this message translates to:
  /// **'Meteorologia'**
  String get sectionWeather;

  /// No description provided for @labelTemperature.
  ///
  /// In pt, this message translates to:
  /// **'Temperatura'**
  String get labelTemperature;

  /// No description provided for @labelRain.
  ///
  /// In pt, this message translates to:
  /// **'Chuva'**
  String get labelRain;

  /// No description provided for @labelOccupancy.
  ///
  /// In pt, this message translates to:
  /// **'Ocupação'**
  String get labelOccupancy;

  /// No description provided for @labelConfidence.
  ///
  /// In pt, this message translates to:
  /// **'% conf.'**
  String get labelConfidence;

  /// No description provided for @flagLiveTap.
  ///
  /// In pt, this message translates to:
  /// **'live · Toca para confirmar'**
  String get flagLiveTap;

  /// No description provided for @flagProposeTap.
  ///
  /// In pt, this message translates to:
  /// **'Toca para propor a bandeira'**
  String get flagProposeTap;

  /// No description provided for @errorFavourite.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao actualizar favorito'**
  String get errorFavourite;

  /// No description provided for @tooFarToCheckin.
  ///
  /// In pt, this message translates to:
  /// **'Estás demasiado longe de uma praia para registar presença.'**
  String get tooFarToCheckin;

  /// No description provided for @presenceRegistered.
  ///
  /// In pt, this message translates to:
  /// **'Presença registada!'**
  String get presenceRegistered;

  /// No description provided for @fewUsersNote.
  ///
  /// In pt, this message translates to:
  /// **'Poucos utilizadores'**
  String get fewUsersNote;

  /// No description provided for @usersAtBeach.
  ///
  /// In pt, this message translates to:
  /// **'{count} pessoas'**
  String usersAtBeach(int count);

  /// No description provided for @occupancyNote.
  ///
  /// In pt, this message translates to:
  /// **'a usar a app nesta praia nos últimos 20 min. Estimativa aproximada.'**
  String get occupancyNote;

  /// No description provided for @alertsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Alertas da Comunidade'**
  String get alertsTitle;

  /// No description provided for @alertsActive.
  ///
  /// In pt, this message translates to:
  /// **'{count} activos'**
  String alertsActive(int count);

  /// No description provided for @mustBeAtBeachVote.
  ///
  /// In pt, this message translates to:
  /// **'Tens de estar na praia para votar'**
  String get mustBeAtBeachVote;

  /// No description provided for @errorVoting.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao votar. Tenta de novo.'**
  String get errorVoting;

  /// No description provided for @notificationsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Notificações'**
  String get notificationsTitle;

  /// No description provided for @errorLoadNotifications.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar notificações'**
  String get errorLoadNotifications;

  /// No description provided for @notificationsEmpty.
  ///
  /// In pt, this message translates to:
  /// **'As notificações sobre as praias aparecem aqui.'**
  String get notificationsEmpty;

  /// No description provided for @settingsGeneral.
  ///
  /// In pt, this message translates to:
  /// **'Geral'**
  String get settingsGeneral;

  /// No description provided for @settingsNotifsEnabled.
  ///
  /// In pt, this message translates to:
  /// **'Notificações ativadas'**
  String get settingsNotifsEnabled;

  /// No description provided for @settingsNotifsEnabledSub.
  ///
  /// In pt, this message translates to:
  /// **'Liga ou desliga todas as notificações'**
  String get settingsNotifsEnabledSub;

  /// No description provided for @settingsCommunityAlerts.
  ///
  /// In pt, this message translates to:
  /// **'Alertas de comunidade'**
  String get settingsCommunityAlerts;

  /// No description provided for @settingsCheckinAlerts.
  ///
  /// In pt, this message translates to:
  /// **'Alertas ao fazer check-in'**
  String get settingsCheckinAlerts;

  /// No description provided for @settingsCheckinAlertsSub.
  ///
  /// In pt, this message translates to:
  /// **'Notifica quando chegares a uma praia com alertas'**
  String get settingsCheckinAlertsSub;

  /// No description provided for @settingsProximityAlerts.
  ///
  /// In pt, this message translates to:
  /// **'Alertas de proximidade'**
  String get settingsProximityAlerts;

  /// No description provided for @settingsProximityAlertsSub.
  ///
  /// In pt, this message translates to:
  /// **'Alertas quando estás perto de uma praia'**
  String get settingsProximityAlertsSub;

  /// No description provided for @settingsProximityRadius.
  ///
  /// In pt, this message translates to:
  /// **'Raio de proximidade'**
  String get settingsProximityRadius;

  /// No description provided for @settingsAlertTypes.
  ///
  /// In pt, this message translates to:
  /// **'Tipos de alerta'**
  String get settingsAlertTypes;

  /// No description provided for @settingsJellyfish.
  ///
  /// In pt, this message translates to:
  /// **'Medusas'**
  String get settingsJellyfish;

  /// No description provided for @settingsStrongCurrent.
  ///
  /// In pt, this message translates to:
  /// **'Corrente forte'**
  String get settingsStrongCurrent;

  /// No description provided for @settingsPollution.
  ///
  /// In pt, this message translates to:
  /// **'Poluição'**
  String get settingsPollution;

  /// No description provided for @settingsRoughSea.
  ///
  /// In pt, this message translates to:
  /// **'Mar agitado'**
  String get settingsRoughSea;

  /// No description provided for @settingsMinSeverity.
  ///
  /// In pt, this message translates to:
  /// **'Severidade mínima'**
  String get settingsMinSeverity;

  /// No description provided for @errorLoadSettings.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar as notificações'**
  String get errorLoadSettings;

  /// No description provided for @proximityRadiusValue.
  ///
  /// In pt, this message translates to:
  /// **'{meters} m'**
  String proximityRadiusValue(int meters);

  /// No description provided for @accountTitle.
  ///
  /// In pt, this message translates to:
  /// **'Conta'**
  String get accountTitle;

  /// No description provided for @errorLoadProfile.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar o perfil'**
  String get errorLoadProfile;

  /// No description provided for @guestUser.
  ///
  /// In pt, this message translates to:
  /// **'Convidado'**
  String get guestUser;

  /// No description provided for @registeredUser.
  ///
  /// In pt, this message translates to:
  /// **'Utilizador'**
  String get registeredUser;

  /// No description provided for @guestMode.
  ///
  /// In pt, this message translates to:
  /// **'Modo convidado'**
  String get guestMode;

  /// No description provided for @reputationPoints.
  ///
  /// In pt, this message translates to:
  /// **'{count} pontos de reputação'**
  String reputationPoints(int count);

  /// No description provided for @flagLabelGreen.
  ///
  /// In pt, this message translates to:
  /// **'Segura'**
  String get flagLabelGreen;

  /// No description provided for @flagLabelYellow.
  ///
  /// In pt, this message translates to:
  /// **'Cuidado'**
  String get flagLabelYellow;

  /// No description provided for @flagLabelRed.
  ///
  /// In pt, this message translates to:
  /// **'Perigo'**
  String get flagLabelRed;

  /// No description provided for @flagLabelPurple.
  ///
  /// In pt, this message translates to:
  /// **'Fechada'**
  String get flagLabelPurple;

  /// No description provided for @flagLabelUnknown.
  ///
  /// In pt, this message translates to:
  /// **'Desconhecida'**
  String get flagLabelUnknown;

  /// No description provided for @flagDescGreen.
  ///
  /// In pt, this message translates to:
  /// **'Segura para nadar'**
  String get flagDescGreen;

  /// No description provided for @flagDescYellow.
  ///
  /// In pt, this message translates to:
  /// **'Cuidado ao nadar'**
  String get flagDescYellow;

  /// No description provided for @flagDescRed.
  ///
  /// In pt, this message translates to:
  /// **'Condições perigosas'**
  String get flagDescRed;

  /// No description provided for @flagDescPurple.
  ///
  /// In pt, this message translates to:
  /// **'Praia fechada'**
  String get flagDescPurple;

  /// No description provided for @flagDescUnknown.
  ///
  /// In pt, this message translates to:
  /// **'Estado desconhecido'**
  String get flagDescUnknown;

  /// No description provided for @occupancyLow.
  ///
  /// In pt, this message translates to:
  /// **'Tranquila'**
  String get occupancyLow;

  /// No description provided for @occupancyMedium.
  ///
  /// In pt, this message translates to:
  /// **'Moderada'**
  String get occupancyMedium;

  /// No description provided for @occupancyHigh.
  ///
  /// In pt, this message translates to:
  /// **'Lotada'**
  String get occupancyHigh;

  /// No description provided for @occupancyAnimated.
  ///
  /// In pt, this message translates to:
  /// **'Animada'**
  String get occupancyAnimated;

  /// No description provided for @occupancyFull.
  ///
  /// In pt, this message translates to:
  /// **'Cheia'**
  String get occupancyFull;

  /// No description provided for @occupancyUnknown.
  ///
  /// In pt, this message translates to:
  /// **'Desconhecida'**
  String get occupancyUnknown;

  /// No description provided for @qualityExcellent.
  ///
  /// In pt, this message translates to:
  /// **'Excelente'**
  String get qualityExcellent;

  /// No description provided for @qualityGood.
  ///
  /// In pt, this message translates to:
  /// **'Boa'**
  String get qualityGood;

  /// No description provided for @qualitySufficient.
  ///
  /// In pt, this message translates to:
  /// **'Suficiente'**
  String get qualitySufficient;

  /// No description provided for @qualityPoor.
  ///
  /// In pt, this message translates to:
  /// **'Má'**
  String get qualityPoor;

  /// No description provided for @qualityUnknown.
  ///
  /// In pt, this message translates to:
  /// **'Desconhecida'**
  String get qualityUnknown;

  /// No description provided for @beachQualityExcellent.
  ///
  /// In pt, this message translates to:
  /// **'Excelente'**
  String get beachQualityExcellent;

  /// No description provided for @beachQualityGood.
  ///
  /// In pt, this message translates to:
  /// **'Boa condição'**
  String get beachQualityGood;

  /// No description provided for @beachQualityFair.
  ///
  /// In pt, this message translates to:
  /// **'Condição razoável'**
  String get beachQualityFair;

  /// No description provided for @beachQualityPoor.
  ///
  /// In pt, this message translates to:
  /// **'Má condição'**
  String get beachQualityPoor;

  /// No description provided for @tideHigh.
  ///
  /// In pt, this message translates to:
  /// **'alta'**
  String get tideHigh;

  /// No description provided for @tideLow.
  ///
  /// In pt, this message translates to:
  /// **'baixa'**
  String get tideLow;

  /// No description provided for @tidePrefixHigh.
  ///
  /// In pt, this message translates to:
  /// **'maré alta'**
  String get tidePrefixHigh;

  /// No description provided for @tidePrefixLow.
  ///
  /// In pt, this message translates to:
  /// **'maré baixa'**
  String get tidePrefixLow;

  /// No description provided for @timeJustNow.
  ///
  /// In pt, this message translates to:
  /// **'agora mesmo'**
  String get timeJustNow;

  /// No description provided for @timeYesterday.
  ///
  /// In pt, this message translates to:
  /// **'ontem'**
  String get timeYesterday;

  /// No description provided for @timeMinutes.
  ///
  /// In pt, this message translates to:
  /// **'há {minutes} min'**
  String timeMinutes(int minutes);

  /// No description provided for @timeHours.
  ///
  /// In pt, this message translates to:
  /// **'há {hours}h'**
  String timeHours(int hours);

  /// No description provided for @timeDays.
  ///
  /// In pt, this message translates to:
  /// **'há {days} dias'**
  String timeDays(int days);

  /// No description provided for @timeWeeks.
  ///
  /// In pt, this message translates to:
  /// **'há {weeks} sem.'**
  String timeWeeks(int weeks);

  /// No description provided for @timeMonths.
  ///
  /// In pt, this message translates to:
  /// **'há {months} meses'**
  String timeMonths(int months);

  /// No description provided for @guestVoteAlerts.
  ///
  /// In pt, this message translates to:
  /// **'Cria uma conta para votar nos alertas'**
  String get guestVoteAlerts;

  /// No description provided for @guestSubmitReport.
  ///
  /// In pt, this message translates to:
  /// **'Cria uma conta para submeter avisos'**
  String get guestSubmitReport;

  /// No description provided for @guestConfirmFlag.
  ///
  /// In pt, this message translates to:
  /// **'Cria uma conta para confirmar bandeiras'**
  String get guestConfirmFlag;

  /// No description provided for @guestProposeFlag.
  ///
  /// In pt, this message translates to:
  /// **'Cria uma conta para propor bandeiras'**
  String get guestProposeFlag;

  /// No description provided for @guestSaveContribs.
  ///
  /// In pt, this message translates to:
  /// **'Cria uma conta para guardar as tuas contribuições.'**
  String get guestSaveContribs;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
