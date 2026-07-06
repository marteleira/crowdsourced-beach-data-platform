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
  /// **'Praias reais. Condições reais.'**
  String get appTagline;

  /// No description provided for @appLocation.
  ///
  /// In pt, this message translates to:
  /// **'Setúbal · Portugal'**
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

  /// No description provided for @signInGoogle.
  ///
  /// In pt, this message translates to:
  /// **'Entrar com Google'**
  String get signInGoogle;

  /// No description provided for @signInEmail.
  ///
  /// In pt, this message translates to:
  /// **'Entrar com email'**
  String get signInEmail;

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

  /// No description provided for @errorSignIn.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao iniciar sessão. Tenta novamente.'**
  String get errorSignIn;

  /// No description provided for @loading.
  ///
  /// In pt, this message translates to:
  /// **'A carregar dados...'**
  String get loading;

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

  /// No description provided for @retryAgain.
  ///
  /// In pt, this message translates to:
  /// **'Tentar novamente'**
  String get retryAgain;

  /// No description provided for @cancelLabel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get cancelLabel;

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

  /// No description provided for @explorerName.
  ///
  /// In pt, this message translates to:
  /// **'explorador'**
  String get explorerName;

  /// No description provided for @updatedAt.
  ///
  /// In pt, this message translates to:
  /// **'Actualizado às {time}'**
  String updatedAt(String time);

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

  /// No description provided for @homeSeaTemp.
  ///
  /// In pt, this message translates to:
  /// **'Temp. mar'**
  String get homeSeaTemp;

  /// No description provided for @homeActiveNow.
  ///
  /// In pt, this message translates to:
  /// **'Activos agora'**
  String get homeActiveNow;

  /// No description provided for @homeAlerts.
  ///
  /// In pt, this message translates to:
  /// **'Alertas'**
  String get homeAlerts;

  /// No description provided for @homeFavViewAll.
  ///
  /// In pt, this message translates to:
  /// **'Ver\ntodas'**
  String get homeFavViewAll;

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

  /// No description provided for @weatherFeelsLike.
  ///
  /// In pt, this message translates to:
  /// **'Sensação'**
  String get weatherFeelsLike;

  /// No description provided for @weatherHumidity.
  ///
  /// In pt, this message translates to:
  /// **'Humidade'**
  String get weatherHumidity;

  /// No description provided for @weatherUv.
  ///
  /// In pt, this message translates to:
  /// **'UV'**
  String get weatherUv;

  /// No description provided for @windGusts.
  ///
  /// In pt, this message translates to:
  /// **'raj. {gusts} km/h'**
  String windGusts(int gusts);

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

  /// No description provided for @communityTitle.
  ///
  /// In pt, this message translates to:
  /// **'Comunidade'**
  String get communityTitle;

  /// No description provided for @communityReports.
  ///
  /// In pt, this message translates to:
  /// **'{count} avisos activos'**
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

  /// No description provided for @beachAlertSingular.
  ///
  /// In pt, this message translates to:
  /// **'alerta ativo'**
  String get beachAlertSingular;

  /// No description provided for @beachAlertPlural.
  ///
  /// In pt, this message translates to:
  /// **'alertas ativos'**
  String get beachAlertPlural;

  /// No description provided for @municipality.
  ///
  /// In pt, this message translates to:
  /// **'Setúbal'**
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

  /// No description provided for @seaConditionsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Condições do Mar'**
  String get seaConditionsTitle;

  /// No description provided for @seaWavePeriod.
  ///
  /// In pt, this message translates to:
  /// **'Período'**
  String get seaWavePeriod;

  /// No description provided for @seaTempLabel.
  ///
  /// In pt, this message translates to:
  /// **'Temp. Mar'**
  String get seaTempLabel;

  /// No description provided for @tideDirRising.
  ///
  /// In pt, this message translates to:
  /// **'subindo'**
  String get tideDirRising;

  /// No description provided for @tideDirFalling.
  ///
  /// In pt, this message translates to:
  /// **'descendo'**
  String get tideDirFalling;

  /// No description provided for @tideDirSteady.
  ///
  /// In pt, this message translates to:
  /// **'estável'**
  String get tideDirSteady;

  /// No description provided for @tideDirRisingCap.
  ///
  /// In pt, this message translates to:
  /// **'Subindo'**
  String get tideDirRisingCap;

  /// No description provided for @tideDirFallingCap.
  ///
  /// In pt, this message translates to:
  /// **'Descendo'**
  String get tideDirFallingCap;

  /// No description provided for @tideDirSteadyCap.
  ///
  /// In pt, this message translates to:
  /// **'Estável'**
  String get tideDirSteadyCap;

  /// No description provided for @tidesPageTitle.
  ///
  /// In pt, this message translates to:
  /// **'Marés'**
  String get tidesPageTitle;

  /// No description provided for @tidesMoreDetails.
  ///
  /// In pt, this message translates to:
  /// **'MAIS DETALHES'**
  String get tidesMoreDetails;

  /// No description provided for @tidesTodaySection.
  ///
  /// In pt, this message translates to:
  /// **'MARÉS DE HOJE'**
  String get tidesTodaySection;

  /// No description provided for @tidesNoData.
  ///
  /// In pt, this message translates to:
  /// **'Sem dados de marés disponíveis'**
  String get tidesNoData;

  /// No description provided for @tidesChartSection.
  ///
  /// In pt, this message translates to:
  /// **'GRÁFICO DA MARÉ'**
  String get tidesChartSection;

  /// No description provided for @tidesNowLabel.
  ///
  /// In pt, this message translates to:
  /// **'AGORA'**
  String get tidesNowLabel;

  /// No description provided for @tidesCardTitle.
  ///
  /// In pt, this message translates to:
  /// **'Marés Hoje'**
  String get tidesCardTitle;

  /// No description provided for @tidesViewFull.
  ///
  /// In pt, this message translates to:
  /// **'Vista completa →'**
  String get tidesViewFull;

  /// No description provided for @waterQualityTitle.
  ///
  /// In pt, this message translates to:
  /// **'Qualidade da Água'**
  String get waterQualityTitle;

  /// No description provided for @waterQualityLastSampled.
  ///
  /// In pt, this message translates to:
  /// **'Última avaliação em {date}'**
  String waterQualityLastSampled(String date);

  /// No description provided for @waterQualityCachedMins.
  ///
  /// In pt, this message translates to:
  /// **'cache {minutes} min atrás'**
  String waterQualityCachedMins(int minutes);

  /// No description provided for @waterQualityCachedHours.
  ///
  /// In pt, this message translates to:
  /// **'cache {hours}h atrás'**
  String waterQualityCachedHours(int hours);

  /// No description provided for @waterQualityCachedDays.
  ///
  /// In pt, this message translates to:
  /// **'cache {days}d atrás'**
  String waterQualityCachedDays(int days);

  /// No description provided for @waterQualityCached.
  ///
  /// In pt, this message translates to:
  /// **'dados em cache'**
  String get waterQualityCached;

  /// No description provided for @transportCardTitle.
  ///
  /// In pt, this message translates to:
  /// **'Próximas Partidas'**
  String get transportCardTitle;

  /// No description provided for @transportNoInfo.
  ///
  /// In pt, this message translates to:
  /// **'Sem informação de transportes para esta praia'**
  String get transportNoInfo;

  /// No description provided for @transportNoDepartures.
  ///
  /// In pt, this message translates to:
  /// **'Sem partidas previstas'**
  String get transportNoDepartures;

  /// No description provided for @transportNearbyStop.
  ///
  /// In pt, this message translates to:
  /// **'{count} paragem próxima'**
  String transportNearbyStop(int count);

  /// No description provided for @transportNearbyStops.
  ///
  /// In pt, this message translates to:
  /// **'{count} paragens próximas'**
  String transportNearbyStops(int count);

  /// No description provided for @transportViewSchedules.
  ///
  /// In pt, this message translates to:
  /// **'Ver horários completos →'**
  String get transportViewSchedules;

  /// No description provided for @communityAlertsSectionTitle.
  ///
  /// In pt, this message translates to:
  /// **'ALERTAS DA COMUNIDADE'**
  String get communityAlertsSectionTitle;

  /// No description provided for @reportVerified.
  ///
  /// In pt, this message translates to:
  /// **'Verificado'**
  String get reportVerified;

  /// No description provided for @reportVoteSingular.
  ///
  /// In pt, this message translates to:
  /// **'voto'**
  String get reportVoteSingular;

  /// No description provided for @reportVotePlural.
  ///
  /// In pt, this message translates to:
  /// **'votos'**
  String get reportVotePlural;

  /// No description provided for @communityAlertsEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Tudo calmo!'**
  String get communityAlertsEmptyTitle;

  /// No description provided for @communityAlertsEmptyBody.
  ///
  /// In pt, this message translates to:
  /// **'Sem alertas activos nesta praia.\nSe vires algo, reporta!'**
  String get communityAlertsEmptyBody;

  /// No description provided for @communityAlertsReportBtn.
  ///
  /// In pt, this message translates to:
  /// **'Reportar condição'**
  String get communityAlertsReportBtn;

  /// No description provided for @errorLoadAlerts.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar alertas'**
  String get errorLoadAlerts;

  /// No description provided for @alertTypeJellyfish.
  ///
  /// In pt, this message translates to:
  /// **'Medusas'**
  String get alertTypeJellyfish;

  /// No description provided for @alertTypeStrongCurrent.
  ///
  /// In pt, this message translates to:
  /// **'Corrente Forte'**
  String get alertTypeStrongCurrent;

  /// No description provided for @alertTypePollution.
  ///
  /// In pt, this message translates to:
  /// **'Poluição'**
  String get alertTypePollution;

  /// No description provided for @alertTypeRoughSea.
  ///
  /// In pt, this message translates to:
  /// **'Mar Agitado'**
  String get alertTypeRoughSea;

  /// No description provided for @alertTypeOther.
  ///
  /// In pt, this message translates to:
  /// **'Outro'**
  String get alertTypeOther;

  /// No description provided for @alertTypeDefault.
  ///
  /// In pt, this message translates to:
  /// **'Alerta'**
  String get alertTypeDefault;

  /// No description provided for @severityLow.
  ///
  /// In pt, this message translates to:
  /// **'Baixo'**
  String get severityLow;

  /// No description provided for @severityModerate.
  ///
  /// In pt, this message translates to:
  /// **'Moderado'**
  String get severityModerate;

  /// No description provided for @severityHigh.
  ///
  /// In pt, this message translates to:
  /// **'Grave'**
  String get severityHigh;

  /// No description provided for @reportSheetTitle.
  ///
  /// In pt, this message translates to:
  /// **'Reportar Condição'**
  String get reportSheetTitle;

  /// No description provided for @reportTypeSection.
  ///
  /// In pt, this message translates to:
  /// **'Tipo de condição'**
  String get reportTypeSection;

  /// No description provided for @reportSeveritySection.
  ///
  /// In pt, this message translates to:
  /// **'Qual a gravidade?'**
  String get reportSeveritySection;

  /// No description provided for @reportSeverityLowSub.
  ///
  /// In pt, this message translates to:
  /// **'Preocupação menor'**
  String get reportSeverityLowSub;

  /// No description provided for @reportSeverityModerateSub.
  ///
  /// In pt, this message translates to:
  /// **'Risco notável'**
  String get reportSeverityModerateSub;

  /// No description provided for @reportSeverityHighSub.
  ///
  /// In pt, this message translates to:
  /// **'Perigoso'**
  String get reportSeverityHighSub;

  /// No description provided for @reportNoteSection.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar nota'**
  String get reportNoteSection;

  /// No description provided for @reportNoteOptional.
  ///
  /// In pt, this message translates to:
  /// **'(opcional)'**
  String get reportNoteOptional;

  /// No description provided for @reportNoteHint.
  ///
  /// In pt, this message translates to:
  /// **'Descreve o que observaste...'**
  String get reportNoteHint;

  /// No description provided for @reportLocationNote.
  ///
  /// In pt, this message translates to:
  /// **'A tua localização aproximada será partilhada com este aviso.'**
  String get reportLocationNote;

  /// No description provided for @reportSubmit.
  ///
  /// In pt, this message translates to:
  /// **'Submeter Aviso'**
  String get reportSubmit;

  /// No description provided for @reportSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Aviso submetido com sucesso!'**
  String get reportSuccess;

  /// No description provided for @reportMustBeAtBeach.
  ///
  /// In pt, this message translates to:
  /// **'Tens de estar na praia para submeter um aviso'**
  String get reportMustBeAtBeach;

  /// No description provided for @reportError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao submeter. Tenta de novo.'**
  String get reportError;

  /// No description provided for @presenceSectionTitle.
  ///
  /// In pt, this message translates to:
  /// **'QUEM ESTÁ AQUI'**
  String get presenceSectionTitle;

  /// No description provided for @presenceViewAll.
  ///
  /// In pt, this message translates to:
  /// **'Ver todos →'**
  String get presenceViewAll;

  /// No description provided for @presencePerson.
  ///
  /// In pt, this message translates to:
  /// **'1 pessoa'**
  String get presencePerson;

  /// No description provided for @presencePeople.
  ///
  /// In pt, this message translates to:
  /// **'{count} pessoas'**
  String presencePeople(int count);

  /// No description provided for @presencePersonHere.
  ///
  /// In pt, this message translates to:
  /// **'1 pessoa nesta praia agora'**
  String get presencePersonHere;

  /// No description provided for @presencePeopleHere.
  ///
  /// In pt, this message translates to:
  /// **'{count} pessoas nesta praia agora'**
  String presencePeopleHere(int count);

  /// No description provided for @presenceSharedProfile1.
  ///
  /// In pt, this message translates to:
  /// **'1 partilha o perfil'**
  String get presenceSharedProfile1;

  /// No description provided for @presenceSharedProfiles.
  ///
  /// In pt, this message translates to:
  /// **'{count} partilham o perfil'**
  String presenceSharedProfiles(int count);

  /// No description provided for @presencePrivateNote.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma pessoa decidiu partilhar a localização.'**
  String get presencePrivateNote;

  /// No description provided for @presenceSheetTitle.
  ///
  /// In pt, this message translates to:
  /// **'Quem está aqui'**
  String get presenceSheetTitle;

  /// No description provided for @presenceAnonymousUser.
  ///
  /// In pt, this message translates to:
  /// **'Utilizador Anónimo'**
  String get presenceAnonymousUser;

  /// No description provided for @presencePrivateFooter1.
  ///
  /// In pt, this message translates to:
  /// **'+{count} pessoa em modo privado'**
  String presencePrivateFooter1(int count);

  /// No description provided for @presencePrivateFooterN.
  ///
  /// In pt, this message translates to:
  /// **'+{count} pessoas em modo privado'**
  String presencePrivateFooterN(int count);

  /// No description provided for @presenceEmptyTitle1.
  ///
  /// In pt, this message translates to:
  /// **'1 pessoa está aqui'**
  String get presenceEmptyTitle1;

  /// No description provided for @presenceEmptyTitleN.
  ///
  /// In pt, this message translates to:
  /// **'{count} pessoas estão aqui'**
  String presenceEmptyTitleN(int count);

  /// No description provided for @presenceEmptyPrivate.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma pessoa decidiu partilhar\na sua localização.'**
  String get presenceEmptyPrivate;

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

  /// No description provided for @settingsFavBeaches.
  ///
  /// In pt, this message translates to:
  /// **'Praias favoritas'**
  String get settingsFavBeaches;

  /// No description provided for @settingsFavAlertsEnabled.
  ///
  /// In pt, this message translates to:
  /// **'Alertas das minhas praias'**
  String get settingsFavAlertsEnabled;

  /// No description provided for @settingsFavAlertsEnabledSub.
  ///
  /// In pt, this message translates to:
  /// **'Recebe alertas das praias que tens guardadas'**
  String get settingsFavAlertsEnabledSub;

  /// No description provided for @settingsBeachStatus.
  ///
  /// In pt, this message translates to:
  /// **'Estado da praia'**
  String get settingsBeachStatus;

  /// No description provided for @settingsFlagChange.
  ///
  /// In pt, this message translates to:
  /// **'Mudança de bandeira'**
  String get settingsFlagChange;

  /// No description provided for @settingsFlagChangeSub.
  ///
  /// In pt, this message translates to:
  /// **'Notifica quando o estado de segurança muda'**
  String get settingsFlagChangeSub;

  /// No description provided for @settingsTideAlerts.
  ///
  /// In pt, this message translates to:
  /// **'Alertas de maré'**
  String get settingsTideAlerts;

  /// No description provided for @settingsTideAlertsSub.
  ///
  /// In pt, this message translates to:
  /// **'Aviso antes de preia-mar e baixa-mar'**
  String get settingsTideAlertsSub;

  /// No description provided for @settingsMyReports.
  ///
  /// In pt, this message translates to:
  /// **'Os meus avisos'**
  String get settingsMyReports;

  /// No description provided for @settingsReportConfirmed.
  ///
  /// In pt, this message translates to:
  /// **'Aviso confirmado'**
  String get settingsReportConfirmed;

  /// No description provided for @settingsReportConfirmedSub.
  ///
  /// In pt, this message translates to:
  /// **'Quando a comunidade confirma um aviso teu'**
  String get settingsReportConfirmedSub;

  /// No description provided for @settingsReportRejected.
  ///
  /// In pt, this message translates to:
  /// **'Aviso rejeitado'**
  String get settingsReportRejected;

  /// No description provided for @settingsReportRejectedSub.
  ///
  /// In pt, this message translates to:
  /// **'Quando a comunidade rejeita um aviso teu'**
  String get settingsReportRejectedSub;

  /// No description provided for @settingsQuietHours.
  ///
  /// In pt, this message translates to:
  /// **'Horas de silêncio'**
  String get settingsQuietHours;

  /// No description provided for @settingsQuietHoursEnabled.
  ///
  /// In pt, this message translates to:
  /// **'Ativar horas de silêncio'**
  String get settingsQuietHoursEnabled;

  /// No description provided for @settingsQuietHoursEnabledSub.
  ///
  /// In pt, this message translates to:
  /// **'Sem notificações durante o período definido'**
  String get settingsQuietHoursEnabledSub;

  /// No description provided for @settingsQuietStart.
  ///
  /// In pt, this message translates to:
  /// **'Início'**
  String get settingsQuietStart;

  /// No description provided for @settingsQuietEnd.
  ///
  /// In pt, this message translates to:
  /// **'Fim'**
  String get settingsQuietEnd;

  /// No description provided for @settingsSeverityLow.
  ///
  /// In pt, this message translates to:
  /// **'Baixa'**
  String get settingsSeverityLow;

  /// No description provided for @settingsSeverityMedium.
  ///
  /// In pt, this message translates to:
  /// **'Média'**
  String get settingsSeverityMedium;

  /// No description provided for @settingsSeverityHigh.
  ///
  /// In pt, this message translates to:
  /// **'Alta'**
  String get settingsSeverityHigh;

  /// No description provided for @privacyPublicProfile.
  ///
  /// In pt, this message translates to:
  /// **'Perfil público'**
  String get privacyPublicProfile;

  /// No description provided for @privacyNameVisible.
  ///
  /// In pt, this message translates to:
  /// **'Nome visível'**
  String get privacyNameVisible;

  /// No description provided for @privacyNameVisibleSub.
  ///
  /// In pt, this message translates to:
  /// **'Outros utilizadores podem ver o teu nome'**
  String get privacyNameVisibleSub;

  /// No description provided for @privacyAvatarVisible.
  ///
  /// In pt, this message translates to:
  /// **'Avatar visível'**
  String get privacyAvatarVisible;

  /// No description provided for @privacyAvatarVisibleSub.
  ///
  /// In pt, this message translates to:
  /// **'As tuas iniciais aparecem nos avisos'**
  String get privacyAvatarVisibleSub;

  /// No description provided for @privacyPresence.
  ///
  /// In pt, this message translates to:
  /// **'Presença & Atividade'**
  String get privacyPresence;

  /// No description provided for @privacyShowOnMap.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar no mapa'**
  String get privacyShowOnMap;

  /// No description provided for @privacyShowOnMapSub.
  ///
  /// In pt, this message translates to:
  /// **'A tua presença conta para a lotação da praia'**
  String get privacyShowOnMapSub;

  /// No description provided for @privacyShareUsage.
  ///
  /// In pt, this message translates to:
  /// **'Partilhar dados de utilização'**
  String get privacyShareUsage;

  /// No description provided for @privacyShareUsageSub.
  ///
  /// In pt, this message translates to:
  /// **'Ajuda a melhorar a app de forma anónima'**
  String get privacyShareUsageSub;

  /// No description provided for @privacyMyData.
  ///
  /// In pt, this message translates to:
  /// **'Os meus dados'**
  String get privacyMyData;

  /// No description provided for @privacyExportData.
  ///
  /// In pt, this message translates to:
  /// **'Exportar os meus dados'**
  String get privacyExportData;

  /// No description provided for @privacyExportDataSub.
  ///
  /// In pt, this message translates to:
  /// **'Recebe uma cópia de tudo o que guardamos'**
  String get privacyExportDataSub;

  /// No description provided for @privacyDeleteReports.
  ///
  /// In pt, this message translates to:
  /// **'Apagar todos os avisos'**
  String get privacyDeleteReports;

  /// No description provided for @privacyDeleteReportsSub.
  ///
  /// In pt, this message translates to:
  /// **'Remove os teus avisos da plataforma'**
  String get privacyDeleteReportsSub;

  /// No description provided for @privacyDeleteAccount.
  ///
  /// In pt, this message translates to:
  /// **'Apagar conta'**
  String get privacyDeleteAccount;

  /// No description provided for @privacyDeleteAccountSub.
  ///
  /// In pt, this message translates to:
  /// **'Ação permanente e irreversível'**
  String get privacyDeleteAccountSub;

  /// No description provided for @privacyExporting.
  ///
  /// In pt, this message translates to:
  /// **'A exportar dados…'**
  String get privacyExporting;

  /// No description provided for @privacyExportSaved.
  ///
  /// In pt, this message translates to:
  /// **'Guardado: {filename}'**
  String privacyExportSaved(String filename);

  /// No description provided for @privacyExportError.
  ///
  /// In pt, this message translates to:
  /// **'Erro: {error}'**
  String privacyExportError(String error);

  /// No description provided for @privacyDeleteReportsConfirmTitle.
  ///
  /// In pt, this message translates to:
  /// **'Apagar todos os avisos?'**
  String get privacyDeleteReportsConfirmTitle;

  /// No description provided for @privacyDeleteReportsConfirmBody.
  ///
  /// In pt, this message translates to:
  /// **'Todos os teus avisos serão removidos da plataforma. Os teus pontos de reputação serão mantidos.'**
  String get privacyDeleteReportsConfirmBody;

  /// No description provided for @privacyDeleteReportsSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Avisos apagados com sucesso'**
  String get privacyDeleteReportsSuccess;

  /// No description provided for @privacyDeleteReportsError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao apagar avisos'**
  String get privacyDeleteReportsError;

  /// No description provided for @privacyDeleteAccountConfirmTitle.
  ///
  /// In pt, this message translates to:
  /// **'Apagar conta?'**
  String get privacyDeleteAccountConfirmTitle;

  /// No description provided for @privacyDeleteAccountConfirmBody.
  ///
  /// In pt, this message translates to:
  /// **'Esta ação é permanente. Todos os teus dados serão eliminados.\n\nEscreve APAGAR para confirmar:'**
  String get privacyDeleteAccountConfirmBody;

  /// No description provided for @privacyDeleteAccountConfirmWord.
  ///
  /// In pt, this message translates to:
  /// **'APAGAR'**
  String get privacyDeleteAccountConfirmWord;

  /// No description provided for @privacyDeleteAccountError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao apagar conta'**
  String get privacyDeleteAccountError;

  /// No description provided for @privacyPendingTitle.
  ///
  /// In pt, this message translates to:
  /// **'Conta agendada para eliminação'**
  String get privacyPendingTitle;

  /// No description provided for @privacyPendingBody.
  ///
  /// In pt, this message translates to:
  /// **'A tua conta e todos os teus dados serão eliminados definitivamente a {date}.\n\nPodes cancelar esta ação até essa data.'**
  String privacyPendingBody(String date);

  /// No description provided for @privacyPendingBodyNoDate.
  ///
  /// In pt, this message translates to:
  /// **'A tua conta está agendada para eliminação.\n\nPodes cancelar esta ação antes da data prevista.'**
  String get privacyPendingBodyNoDate;

  /// No description provided for @privacyCancelDeletion.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar eliminação da conta'**
  String get privacyCancelDeletion;

  /// No description provided for @privacyCancelling.
  ///
  /// In pt, this message translates to:
  /// **'A cancelar…'**
  String get privacyCancelling;

  /// No description provided for @privacyCancelError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao cancelar a eliminação. Tenta de novo.'**
  String get privacyCancelError;

  /// No description provided for @privacyDeleteLabel.
  ///
  /// In pt, this message translates to:
  /// **'Apagar'**
  String get privacyDeleteLabel;

  /// No description provided for @privacyDeleteAccountConfirmBtn.
  ///
  /// In pt, this message translates to:
  /// **'Apagar conta'**
  String get privacyDeleteAccountConfirmBtn;

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

  /// No description provided for @accountAvatarSection.
  ///
  /// In pt, this message translates to:
  /// **'Avatar'**
  String get accountAvatarSection;

  /// No description provided for @accountAvatarDefault.
  ///
  /// In pt, this message translates to:
  /// **'Avatar predefinido (iniciais)'**
  String get accountAvatarDefault;

  /// No description provided for @accountAvatarChoose.
  ///
  /// In pt, this message translates to:
  /// **'Escolher avatar'**
  String get accountAvatarChoose;

  /// No description provided for @accountAvatarPickerTitle.
  ///
  /// In pt, this message translates to:
  /// **'Escolhe o teu avatar'**
  String get accountAvatarPickerTitle;

  /// No description provided for @accountAvatarPickerSub.
  ///
  /// In pt, this message translates to:
  /// **'Toca num avatar para o selecionar.'**
  String get accountAvatarPickerSub;

  /// No description provided for @accountAvatarDefaultLabel.
  ///
  /// In pt, this message translates to:
  /// **'Predefinido (iniciais)'**
  String get accountAvatarDefaultLabel;

  /// No description provided for @accountAvatarDefaultSub.
  ///
  /// In pt, this message translates to:
  /// **'Mostra as iniciais do teu nome'**
  String get accountAvatarDefaultSub;

  /// No description provided for @accountPersonalSection.
  ///
  /// In pt, this message translates to:
  /// **'Informação Pessoal'**
  String get accountPersonalSection;

  /// No description provided for @accountNameEmpty.
  ///
  /// In pt, this message translates to:
  /// **'O nome não pode estar vazio'**
  String get accountNameEmpty;

  /// No description provided for @accountNameTooLong.
  ///
  /// In pt, this message translates to:
  /// **'Máximo 50 caracteres'**
  String get accountNameTooLong;

  /// No description provided for @accountSaveName.
  ///
  /// In pt, this message translates to:
  /// **'Guardar nome'**
  String get accountSaveName;

  /// No description provided for @accountNoChanges.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma alteração para guardar'**
  String get accountNoChanges;

  /// No description provided for @accountProfileUpdated.
  ///
  /// In pt, this message translates to:
  /// **'Perfil atualizado com sucesso'**
  String get accountProfileUpdated;

  /// No description provided for @accountProfileUpdateError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível atualizar o perfil'**
  String get accountProfileUpdateError;

  /// No description provided for @accountAvatarUpdated.
  ///
  /// In pt, this message translates to:
  /// **'Avatar atualizado com sucesso'**
  String get accountAvatarUpdated;

  /// No description provided for @accountAvatarUpdateError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível atualizar o avatar'**
  String get accountAvatarUpdateError;

  /// No description provided for @accountUnexpectedError.
  ///
  /// In pt, this message translates to:
  /// **'Ocorreu um erro inesperado'**
  String get accountUnexpectedError;

  /// No description provided for @accountEmailSection.
  ///
  /// In pt, this message translates to:
  /// **'Email'**
  String get accountEmailSection;

  /// No description provided for @accountEmailNoGuest.
  ///
  /// In pt, this message translates to:
  /// **'Os convidados não têm email associado.'**
  String get accountEmailNoGuest;

  /// No description provided for @accountEmailNoGoogle.
  ///
  /// In pt, this message translates to:
  /// **'A tua conta Google não permite alterar o email aqui.'**
  String get accountEmailNoGoogle;

  /// No description provided for @accountNewEmail.
  ///
  /// In pt, this message translates to:
  /// **'Novo email'**
  String get accountNewEmail;

  /// No description provided for @accountNewEmailHint.
  ///
  /// In pt, this message translates to:
  /// **'novo@exemplo.com'**
  String get accountNewEmailHint;

  /// No description provided for @accountEmailVerificationNote.
  ///
  /// In pt, this message translates to:
  /// **'A verificação será enviada para o novo email.'**
  String get accountEmailVerificationNote;

  /// No description provided for @accountCurrentPasswordConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Password atual (confirmação)'**
  String get accountCurrentPasswordConfirm;

  /// No description provided for @accountPasswordHint.
  ///
  /// In pt, this message translates to:
  /// **'••••••••'**
  String get accountPasswordHint;

  /// No description provided for @accountEmailEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Introduz um email'**
  String get accountEmailEmpty;

  /// No description provided for @accountEmailInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Email inválido'**
  String get accountEmailInvalid;

  /// No description provided for @accountEmailUnchanged.
  ///
  /// In pt, this message translates to:
  /// **'O email não foi alterado'**
  String get accountEmailUnchanged;

  /// No description provided for @accountCurrentPasswordEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Introduz a password atual'**
  String get accountCurrentPasswordEmpty;

  /// No description provided for @accountChangeEmail.
  ///
  /// In pt, this message translates to:
  /// **'Alterar email'**
  String get accountChangeEmail;

  /// No description provided for @accountPasswordSection.
  ///
  /// In pt, this message translates to:
  /// **'Password'**
  String get accountPasswordSection;

  /// No description provided for @accountPasswordNoGuest.
  ///
  /// In pt, this message translates to:
  /// **'Os convidados não têm password.'**
  String get accountPasswordNoGuest;

  /// No description provided for @accountPasswordNoGoogle.
  ///
  /// In pt, this message translates to:
  /// **'A tua conta Google não usa password.'**
  String get accountPasswordNoGoogle;

  /// No description provided for @accountCurrentPassword.
  ///
  /// In pt, this message translates to:
  /// **'Password atual'**
  String get accountCurrentPassword;

  /// No description provided for @accountNewPassword.
  ///
  /// In pt, this message translates to:
  /// **'Nova password'**
  String get accountNewPassword;

  /// No description provided for @accountConfirmPassword.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar nova password'**
  String get accountConfirmPassword;

  /// No description provided for @accountPasswordMismatch.
  ///
  /// In pt, this message translates to:
  /// **'As passwords não coincidem'**
  String get accountPasswordMismatch;

  /// No description provided for @accountConfirmPasswordEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Confirma a nova password'**
  String get accountConfirmPasswordEmpty;

  /// No description provided for @accountPasswordChanged.
  ///
  /// In pt, this message translates to:
  /// **'Password alterada. Inicia sessão novamente nos outros dispositivos.'**
  String get accountPasswordChanged;

  /// No description provided for @accountPasswordChangeError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível alterar a password'**
  String get accountPasswordChangeError;

  /// No description provided for @accountChangePassword.
  ///
  /// In pt, this message translates to:
  /// **'Alterar password'**
  String get accountChangePassword;

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

  /// No description provided for @levelNew.
  ///
  /// In pt, this message translates to:
  /// **'Novo'**
  String get levelNew;

  /// No description provided for @levelRegular.
  ///
  /// In pt, this message translates to:
  /// **'Regular'**
  String get levelRegular;

  /// No description provided for @levelContributor.
  ///
  /// In pt, this message translates to:
  /// **'Contribuidor'**
  String get levelContributor;

  /// No description provided for @levelVeteran.
  ///
  /// In pt, this message translates to:
  /// **'Veterano'**
  String get levelVeteran;

  /// No description provided for @levelNextLabel.
  ///
  /// In pt, this message translates to:
  /// **'Próximo nível'**
  String get levelNextLabel;

  /// No description provided for @levelPointsLeft.
  ///
  /// In pt, this message translates to:
  /// **'{count} pts restantes'**
  String levelPointsLeft(int count);

  /// No description provided for @levelMaxReached.
  ///
  /// In pt, this message translates to:
  /// **'🏄 Nível máximo!'**
  String get levelMaxReached;

  /// No description provided for @statReports.
  ///
  /// In pt, this message translates to:
  /// **'Avisos'**
  String get statReports;

  /// No description provided for @statStreak.
  ///
  /// In pt, this message translates to:
  /// **'Streak'**
  String get statStreak;

  /// No description provided for @statAccuracy.
  ///
  /// In pt, this message translates to:
  /// **'Precisão'**
  String get statAccuracy;

  /// No description provided for @guestBannerTitle.
  ///
  /// In pt, this message translates to:
  /// **'Estás em modo convidado'**
  String get guestBannerTitle;

  /// No description provided for @achievementsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Conquistas'**
  String get achievementsTitle;

  /// No description provided for @achievementFirstReport.
  ///
  /// In pt, this message translates to:
  /// **'Primeira Onda'**
  String get achievementFirstReport;

  /// No description provided for @achievementTideWatcher.
  ///
  /// In pt, this message translates to:
  /// **'Guardião das Marés'**
  String get achievementTideWatcher;

  /// No description provided for @achievement10Reports.
  ///
  /// In pt, this message translates to:
  /// **'10 Avisos'**
  String get achievement10Reports;

  /// No description provided for @achievementAccurate.
  ///
  /// In pt, this message translates to:
  /// **'Preciso'**
  String get achievementAccurate;

  /// No description provided for @achievementStreak10.
  ///
  /// In pt, this message translates to:
  /// **'10 Dias'**
  String get achievementStreak10;

  /// No description provided for @achievementRegular.
  ///
  /// In pt, this message translates to:
  /// **'Regular'**
  String get achievementRegular;

  /// No description provided for @achievementContributor.
  ///
  /// In pt, this message translates to:
  /// **'Contribuidor'**
  String get achievementContributor;

  /// No description provided for @achievementVeteran.
  ///
  /// In pt, this message translates to:
  /// **'Veterano'**
  String get achievementVeteran;

  /// No description provided for @recentActivityTitle.
  ///
  /// In pt, this message translates to:
  /// **'Atividade Recente'**
  String get recentActivityTitle;

  /// No description provided for @eventReportSubmitted.
  ///
  /// In pt, this message translates to:
  /// **'Aviso submetido'**
  String get eventReportSubmitted;

  /// No description provided for @eventFirstReportBonus.
  ///
  /// In pt, this message translates to:
  /// **'Primeiro aviso!'**
  String get eventFirstReportBonus;

  /// No description provided for @eventReportConfirmed.
  ///
  /// In pt, this message translates to:
  /// **'Aviso confirmado pela comunidade'**
  String get eventReportConfirmed;

  /// No description provided for @eventReportContradicted.
  ///
  /// In pt, this message translates to:
  /// **'Aviso rejeitado pela comunidade'**
  String get eventReportContradicted;

  /// No description provided for @eventFlagConfirmed.
  ///
  /// In pt, this message translates to:
  /// **'Proposta de bandeira confirmada'**
  String get eventFlagConfirmed;

  /// No description provided for @eventFlagContradicted.
  ///
  /// In pt, this message translates to:
  /// **'Proposta de bandeira rejeitada'**
  String get eventFlagContradicted;

  /// No description provided for @eventConfirmationAccurate.
  ///
  /// In pt, this message translates to:
  /// **'Confirmação correta'**
  String get eventConfirmationAccurate;

  /// No description provided for @eventConfirmationContradicted.
  ///
  /// In pt, this message translates to:
  /// **'Confirmação precisa — bandeira {color} contradita'**
  String eventConfirmationContradicted(String color);

  /// No description provided for @eventConfirmationVerified.
  ///
  /// In pt, this message translates to:
  /// **'Confirmação precisa — bandeira {color} verificada'**
  String eventConfirmationVerified(String color);

  /// No description provided for @eventSpamPenalty.
  ///
  /// In pt, this message translates to:
  /// **'Penalidade por spam'**
  String get eventSpamPenalty;

  /// No description provided for @settingsAccountTitle.
  ///
  /// In pt, this message translates to:
  /// **'Definições da Conta'**
  String get settingsAccountTitle;

  /// No description provided for @settingsFavouritesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Praias Favoritas'**
  String get settingsFavouritesTitle;

  /// No description provided for @settingsPrivacyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Privacidade & Dados'**
  String get settingsPrivacyTitle;

  /// No description provided for @settingsAboutTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sobre OndaCerta'**
  String get settingsAboutTitle;

  /// No description provided for @signOut.
  ///
  /// In pt, this message translates to:
  /// **'Terminar Sessão'**
  String get signOut;

  /// No description provided for @signOutTitle.
  ///
  /// In pt, this message translates to:
  /// **'Terminar sessão?'**
  String get signOutTitle;

  /// No description provided for @signOutBody.
  ///
  /// In pt, this message translates to:
  /// **'Tens a certeza que queres sair da tua conta?'**
  String get signOutBody;

  /// No description provided for @signOutCancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get signOutCancel;

  /// No description provided for @signOutConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Sair'**
  String get signOutConfirm;

  /// No description provided for @favouritesScreenTitle.
  ///
  /// In pt, this message translates to:
  /// **'Praias Favoritas'**
  String get favouritesScreenTitle;

  /// No description provided for @favouritesSaved1.
  ///
  /// In pt, this message translates to:
  /// **'1 praia guardada'**
  String get favouritesSaved1;

  /// No description provided for @favouritesSavedN.
  ///
  /// In pt, this message translates to:
  /// **'{count} praias guardadas'**
  String favouritesSavedN(int count);

  /// No description provided for @favouriteAlertSingular.
  ///
  /// In pt, this message translates to:
  /// **'alerta'**
  String get favouriteAlertSingular;

  /// No description provided for @favouriteAlertPlural.
  ///
  /// In pt, this message translates to:
  /// **'alertas'**
  String get favouriteAlertPlural;

  /// No description provided for @favouriteRemoveTitle.
  ///
  /// In pt, this message translates to:
  /// **'Remover \"{name}\"?'**
  String favouriteRemoveTitle(String name);

  /// No description provided for @favouriteRemoveBody.
  ///
  /// In pt, this message translates to:
  /// **'Esta praia será removida das tuas favoritas.'**
  String get favouriteRemoveBody;

  /// No description provided for @removeLabel.
  ///
  /// In pt, this message translates to:
  /// **'Remover'**
  String get removeLabel;

  /// No description provided for @errorRemoveFavourite.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao remover favorito'**
  String get errorRemoveFavourite;

  /// No description provided for @favouritesEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sem praias favoritas'**
  String get favouritesEmptyTitle;

  /// No description provided for @favouritesEmptyHint.
  ///
  /// In pt, this message translates to:
  /// **'Abre uma praia e toca no coração\npara a guardar aqui.'**
  String get favouritesEmptyHint;

  /// No description provided for @errorLoadFavourites.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar favoritos'**
  String get errorLoadFavourites;

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

  /// No description provided for @occupancyVotePrompt.
  ///
  /// In pt, this message translates to:
  /// **'Como está a praia agora?'**
  String get occupancyVotePrompt;

  /// No description provided for @occupancyVote1.
  ///
  /// In pt, this message translates to:
  /// **'Vazia'**
  String get occupancyVote1;

  /// No description provided for @occupancyVote2.
  ///
  /// In pt, this message translates to:
  /// **'Tranquila'**
  String get occupancyVote2;

  /// No description provided for @occupancyVote3.
  ///
  /// In pt, this message translates to:
  /// **'Normal'**
  String get occupancyVote3;

  /// No description provided for @occupancyVote4.
  ///
  /// In pt, this message translates to:
  /// **'Movimentada'**
  String get occupancyVote4;

  /// No description provided for @occupancyVote5.
  ///
  /// In pt, this message translates to:
  /// **'Cheia'**
  String get occupancyVote5;

  /// No description provided for @occupancyVoted.
  ///
  /// In pt, this message translates to:
  /// **'Obrigado pelo teu voto!'**
  String get occupancyVoted;

  /// No description provided for @occupancyAlreadyVoted.
  ///
  /// In pt, this message translates to:
  /// **'Já votaste recentemente.'**
  String get occupancyAlreadyVoted;

  /// No description provided for @occupancyMustBePresent.
  ///
  /// In pt, this message translates to:
  /// **'Deves estar na praia para reportar.'**
  String get occupancyMustBePresent;

  /// No description provided for @occupancyDetailsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes da ocupação'**
  String get occupancyDetailsTitle;

  /// No description provided for @occupancyAppUsers.
  ///
  /// In pt, this message translates to:
  /// **'{count} utilizadores da app'**
  String occupancyAppUsers(int count);

  /// No description provided for @occupancyReports.
  ///
  /// In pt, this message translates to:
  /// **'{count} {count, plural, one{relato} other{relatos}} recentes'**
  String occupancyReports(int count);

  /// No description provided for @occupancyConfidencePct.
  ///
  /// In pt, this message translates to:
  /// **'Confiança: {pct}%'**
  String occupancyConfidencePct(int pct);

  /// No description provided for @activityLabelUnverified.
  ///
  /// In pt, this message translates to:
  /// **'Não verificado'**
  String get activityLabelUnverified;

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

  /// No description provided for @transportScreenTitle.
  ///
  /// In pt, this message translates to:
  /// **'Transportes'**
  String get transportScreenTitle;

  /// No description provided for @transportFlagNoInfo.
  ///
  /// In pt, this message translates to:
  /// **'Sem info'**
  String get transportFlagNoInfo;

  /// No description provided for @transportWavesLabel.
  ///
  /// In pt, this message translates to:
  /// **'{height}m ondas'**
  String transportWavesLabel(String height);

  /// No description provided for @transportArrivingSoon.
  ///
  /// In pt, this message translates to:
  /// **'A chegar'**
  String get transportArrivingSoon;

  /// No description provided for @transportNextDeparturesSection.
  ///
  /// In pt, this message translates to:
  /// **'PRÓXIMAS PARTIDAS'**
  String get transportNextDeparturesSection;

  /// No description provided for @transportWalkMins.
  ///
  /// In pt, this message translates to:
  /// **'{mins} min a pé até à praia'**
  String transportWalkMins(int mins);

  /// No description provided for @transportNextDep.
  ///
  /// In pt, this message translates to:
  /// **'Próxima: {time}'**
  String transportNextDep(String time);

  /// No description provided for @transportWalkTo.
  ///
  /// In pt, this message translates to:
  /// **'Ir a pé para {beach}'**
  String transportWalkTo(String beach);

  /// No description provided for @transportWalkToMins.
  ///
  /// In pt, this message translates to:
  /// **'Ir a pé para {beach} ({mins} min)'**
  String transportWalkToMins(String beach, int mins);

  /// No description provided for @transportWalkToMinsFromStop.
  ///
  /// In pt, this message translates to:
  /// **'Ir a pé para {beach} ({mins} min da paragem)'**
  String transportWalkToMinsFromStop(String beach, int mins);

  /// No description provided for @transportDisclaimerLive.
  ///
  /// In pt, this message translates to:
  /// **'Horários Carris Metropolitana. Dados em tempo real quando disponível — verificar nas paragens.'**
  String get transportDisclaimerLive;

  /// No description provided for @transportDisclaimerCache.
  ///
  /// In pt, this message translates to:
  /// **'Horários Carris Metropolitana. Dados em cache — verificar nas paragens.'**
  String get transportDisclaimerCache;

  /// No description provided for @transportEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Sem transportes disponíveis\npara esta praia'**
  String get transportEmpty;

  /// No description provided for @transportLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar os transportes'**
  String get transportLoadError;

  /// No description provided for @emailNameEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Introduz o teu nome'**
  String get emailNameEmpty;

  /// No description provided for @emailEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Introduz o email'**
  String get emailEmpty;

  /// No description provided for @emailInvalidSimple.
  ///
  /// In pt, this message translates to:
  /// **'Email inválido'**
  String get emailInvalidSimple;

  /// No description provided for @emailAlreadyRegisteredTitle.
  ///
  /// In pt, this message translates to:
  /// **'Email já registado'**
  String get emailAlreadyRegisteredTitle;

  /// No description provided for @emailAlreadyRegisteredBody.
  ///
  /// In pt, this message translates to:
  /// **'Este email já tem uma conta. Entra com a tua password.'**
  String get emailAlreadyRegisteredBody;

  /// No description provided for @emailRegisterError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao criar conta. Verifica os dados.'**
  String get emailRegisterError;

  /// No description provided for @emailLoginError.
  ///
  /// In pt, this message translates to:
  /// **'Email ou password incorrectos.'**
  String get emailLoginError;

  /// No description provided for @connectionError.
  ///
  /// In pt, this message translates to:
  /// **'Erro de ligação. Tenta novamente.'**
  String get connectionError;

  /// No description provided for @emailAlreadyHaveAccount.
  ///
  /// In pt, this message translates to:
  /// **'Já tens conta? '**
  String get emailAlreadyHaveAccount;

  /// No description provided for @emailNoAccountYet.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não tens conta? '**
  String get emailNoAccountYet;

  /// No description provided for @flagColorGreen.
  ///
  /// In pt, this message translates to:
  /// **'verde'**
  String get flagColorGreen;

  /// No description provided for @flagColorYellow.
  ///
  /// In pt, this message translates to:
  /// **'amarela'**
  String get flagColorYellow;

  /// No description provided for @flagColorRed.
  ///
  /// In pt, this message translates to:
  /// **'vermelha'**
  String get flagColorRed;

  /// No description provided for @flagColorPurple.
  ///
  /// In pt, this message translates to:
  /// **'roxa'**
  String get flagColorPurple;

  /// No description provided for @flagColorGreenCap.
  ///
  /// In pt, this message translates to:
  /// **'Verde'**
  String get flagColorGreenCap;

  /// No description provided for @flagColorYellowCap.
  ///
  /// In pt, this message translates to:
  /// **'Amarela'**
  String get flagColorYellowCap;

  /// No description provided for @flagColorRedCap.
  ///
  /// In pt, this message translates to:
  /// **'Vermelha'**
  String get flagColorRedCap;

  /// No description provided for @flagColorPurpleCap.
  ///
  /// In pt, this message translates to:
  /// **'Roxa'**
  String get flagColorPurpleCap;

  /// No description provided for @flagProposeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Propor Bandeira'**
  String get flagProposeTitle;

  /// No description provided for @flagProposeRequirement.
  ///
  /// In pt, this message translates to:
  /// **'Tens de estar na praia e ter reputação ≥ 25 para propor.'**
  String get flagProposeRequirement;

  /// No description provided for @flagProposeQuestion.
  ///
  /// In pt, this message translates to:
  /// **'Qual é a bandeira actual?'**
  String get flagProposeQuestion;

  /// No description provided for @flagProposeDescGreen.
  ///
  /// In pt, this message translates to:
  /// **'Seguro para nadar'**
  String get flagProposeDescGreen;

  /// No description provided for @flagProposeDescYellow.
  ///
  /// In pt, this message translates to:
  /// **'Nadar com precaução'**
  String get flagProposeDescYellow;

  /// No description provided for @flagProposeDescRed.
  ///
  /// In pt, this message translates to:
  /// **'Proibido nadar'**
  String get flagProposeDescRed;

  /// No description provided for @flagProposeDescPurple.
  ///
  /// In pt, this message translates to:
  /// **'Animais marinhos presentes'**
  String get flagProposeDescPurple;

  /// No description provided for @flagProposeNoRep.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não tens reputação suficiente (mínimo: 25). Continua a contribuir com alertas e confirmações!'**
  String get flagProposeNoRep;

  /// No description provided for @flagProposeNotPresent.
  ///
  /// In pt, this message translates to:
  /// **'Tens de estar na praia (nos últimos 10 min) para propor uma bandeira.'**
  String get flagProposeNotPresent;

  /// No description provided for @flagProposeUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'Esta praia não tem sistema de bandeiras físicas.'**
  String get flagProposeUnavailable;

  /// No description provided for @flagProposeGenericError.
  ///
  /// In pt, this message translates to:
  /// **'Algo correu mal. Tenta de novo.'**
  String get flagProposeGenericError;

  /// No description provided for @flagProposeSubmit.
  ///
  /// In pt, this message translates to:
  /// **'Propor bandeira {color}'**
  String flagProposeSubmit(String color);

  /// No description provided for @flagProposeSuccessApplied.
  ///
  /// In pt, this message translates to:
  /// **'Bandeira atualizada!'**
  String get flagProposeSuccessApplied;

  /// No description provided for @flagProposeSuccessPending.
  ///
  /// In pt, this message translates to:
  /// **'Proposta submetida!'**
  String get flagProposeSuccessPending;

  /// No description provided for @flagProposeSuccessBodyApplied.
  ///
  /// In pt, this message translates to:
  /// **'A tua reputação deu-te autoridade para aplicar a bandeira directamente.'**
  String get flagProposeSuccessBodyApplied;

  /// No description provided for @flagProposeSuccessBodyPending.
  ///
  /// In pt, this message translates to:
  /// **'A comunidade irá confirmar a tua proposta em breve.'**
  String get flagProposeSuccessBodyPending;

  /// No description provided for @flagProposeFlagLabel.
  ///
  /// In pt, this message translates to:
  /// **'Bandeira {color}'**
  String flagProposeFlagLabel(String color);

  /// No description provided for @flagConfirmQuestionPrefix.
  ///
  /// In pt, this message translates to:
  /// **'A bandeira ainda está '**
  String get flagConfirmQuestionPrefix;

  /// No description provided for @flagConfirmQuestionSuffix.
  ///
  /// In pt, this message translates to:
  /// **'?'**
  String get flagConfirmQuestionSuffix;

  /// No description provided for @flagConfirmYesPrefix.
  ///
  /// In pt, this message translates to:
  /// **'Sim, ainda '**
  String get flagConfirmYesPrefix;

  /// No description provided for @flagConfirmNo.
  ///
  /// In pt, this message translates to:
  /// **'Não, mudou'**
  String get flagConfirmNo;

  /// No description provided for @flagConfirmUnsure.
  ///
  /// In pt, this message translates to:
  /// **'Não tenho a certeza'**
  String get flagConfirmUnsure;

  /// No description provided for @flagConfirmRateLimited.
  ///
  /// In pt, this message translates to:
  /// **'Já confirmaste a bandeira desta praia na última hora.'**
  String get flagConfirmRateLimited;

  /// No description provided for @flagConfirmError.
  ///
  /// In pt, this message translates to:
  /// **'Algo correu mal. Tenta de novo.'**
  String get flagConfirmError;

  /// No description provided for @flagConfirmThankYou.
  ///
  /// In pt, this message translates to:
  /// **'Obrigado!'**
  String get flagConfirmThankYou;

  /// No description provided for @flagConfirmSuccessBody.
  ///
  /// In pt, this message translates to:
  /// **'A tua confirmação ajuda a comunidade\na estar sempre bem informada.'**
  String get flagConfirmSuccessBody;

  /// No description provided for @communityConfidence.
  ///
  /// In pt, this message translates to:
  /// **'Confiança da comunidade'**
  String get communityConfidence;

  /// No description provided for @confidencePercent.
  ///
  /// In pt, this message translates to:
  /// **'{pct}% de confiança'**
  String confidencePercent(int pct);

  /// No description provided for @confidencePercentShort.
  ///
  /// In pt, this message translates to:
  /// **'{pct}% confiança'**
  String confidencePercentShort(int pct);

  /// No description provided for @flagNameGreen.
  ///
  /// In pt, this message translates to:
  /// **'Bandeira Verde'**
  String get flagNameGreen;

  /// No description provided for @flagNameYellow.
  ///
  /// In pt, this message translates to:
  /// **'Bandeira Amarela'**
  String get flagNameYellow;

  /// No description provided for @flagNameRed.
  ///
  /// In pt, this message translates to:
  /// **'Bandeira Vermelha'**
  String get flagNameRed;

  /// No description provided for @flagNamePurple.
  ///
  /// In pt, this message translates to:
  /// **'Bandeira Roxa'**
  String get flagNamePurple;

  /// No description provided for @flagNameUnknown.
  ///
  /// In pt, this message translates to:
  /// **'Estado Desconhecido'**
  String get flagNameUnknown;

  /// No description provided for @flagSafetyGreen.
  ///
  /// In pt, this message translates to:
  /// **'Seguro para nadar'**
  String get flagSafetyGreen;

  /// No description provided for @flagSafetyYellow.
  ///
  /// In pt, this message translates to:
  /// **'Nadar com precaução'**
  String get flagSafetyYellow;

  /// No description provided for @flagSafetyRed.
  ///
  /// In pt, this message translates to:
  /// **'Proibido nadar'**
  String get flagSafetyRed;

  /// No description provided for @flagSafetyPurple.
  ///
  /// In pt, this message translates to:
  /// **'Animais marinhos presentes'**
  String get flagSafetyPurple;

  /// No description provided for @flagSafetyUnknown.
  ///
  /// In pt, this message translates to:
  /// **'Estado desconhecido'**
  String get flagSafetyUnknown;

  /// No description provided for @confidencePct.
  ///
  /// In pt, this message translates to:
  /// **'{pct}% conf.'**
  String confidencePct(int pct);

  /// No description provided for @atTimePrep.
  ///
  /// In pt, this message translates to:
  /// **'às'**
  String get atTimePrep;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In pt, this message translates to:
  /// **'Recuperar password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordBody.
  ///
  /// In pt, this message translates to:
  /// **'Introduz o teu email. Enviamos um código de 6 dígitos para poderes definir uma nova password.'**
  String get forgotPasswordBody;

  /// No description provided for @forgotPasswordSubmit.
  ///
  /// In pt, this message translates to:
  /// **'Enviar código'**
  String get forgotPasswordSubmit;

  /// No description provided for @forgotPasswordSendError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao enviar o código. Tenta novamente.'**
  String get forgotPasswordSendError;

  /// No description provided for @emailVerifyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Confirma o teu email'**
  String get emailVerifyTitle;

  /// No description provided for @emailVerifyBody.
  ///
  /// In pt, this message translates to:
  /// **'Enviámos um código de 6 dígitos para o teu email.\nIntroduz o código abaixo para continuares.'**
  String get emailVerifyBody;

  /// No description provided for @emailVerifyButton.
  ///
  /// In pt, this message translates to:
  /// **'Verificar'**
  String get emailVerifyButton;

  /// No description provided for @emailVerifyCodeInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Código inválido. Tenta de novo.'**
  String get emailVerifyCodeInvalid;

  /// No description provided for @resetCodeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Verifica o teu email'**
  String get resetCodeTitle;

  /// No description provided for @resetCodeBody.
  ///
  /// In pt, this message translates to:
  /// **'Enviámos um código de 6 dígitos para {email}.'**
  String resetCodeBody(String email);

  /// No description provided for @resetCodeContinue.
  ///
  /// In pt, this message translates to:
  /// **'Continuar'**
  String get resetCodeContinue;

  /// No description provided for @resetNewPasswordTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nova password'**
  String get resetNewPasswordTitle;

  /// No description provided for @resetNewPasswordBody.
  ///
  /// In pt, this message translates to:
  /// **'Escolhe uma nova password para a tua conta.'**
  String get resetNewPasswordBody;

  /// No description provided for @resetNewPasswordConfirmLabel.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar password'**
  String get resetNewPasswordConfirmLabel;

  /// No description provided for @resetNewPasswordSubmit.
  ///
  /// In pt, this message translates to:
  /// **'Alterar password'**
  String get resetNewPasswordSubmit;

  /// No description provided for @resetPasswordSuccessTitle.
  ///
  /// In pt, this message translates to:
  /// **'Password alterada!'**
  String get resetPasswordSuccessTitle;

  /// No description provided for @resetPasswordSuccessBody.
  ///
  /// In pt, this message translates to:
  /// **'A tua password foi actualizada com sucesso.\nPodes entrar com a nova password.'**
  String get resetPasswordSuccessBody;

  /// No description provided for @resetPasswordError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao alterar a password. Tenta novamente.'**
  String get resetPasswordError;

  /// No description provided for @codeResend.
  ///
  /// In pt, this message translates to:
  /// **'Reenviar código'**
  String get codeResend;

  /// No description provided for @codeResendCooldown.
  ///
  /// In pt, this message translates to:
  /// **'Reenviar código ({secs}s)'**
  String codeResendCooldown(int secs);

  /// No description provided for @codeResendShortCooldown.
  ///
  /// In pt, this message translates to:
  /// **'Reenviar ({secs}s)'**
  String codeResendShortCooldown(int secs);

  /// No description provided for @codeSentSnack.
  ///
  /// In pt, this message translates to:
  /// **'Novo código enviado para o teu email.'**
  String get codeSentSnack;

  /// No description provided for @codeResendError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao reenviar o código.'**
  String get codeResendError;

  /// No description provided for @codeConfirmEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Confirma a nova password'**
  String get codeConfirmEmpty;

  /// No description provided for @accountBannedTitle.
  ///
  /// In pt, this message translates to:
  /// **'Conta banida'**
  String get accountBannedTitle;

  /// No description provided for @accountBannedBody.
  ///
  /// In pt, this message translates to:
  /// **'A tua conta foi banida permanentemente por violação das regras da comunidade.'**
  String get accountBannedBody;

  /// No description provided for @accountBannedBodyReason.
  ///
  /// In pt, this message translates to:
  /// **'A tua conta foi banida permanentemente por violação das regras da comunidade.\n\nRazão: {reason}'**
  String accountBannedBodyReason(String reason);

  /// No description provided for @accountSuspendedTitle.
  ///
  /// In pt, this message translates to:
  /// **'Conta suspensa'**
  String get accountSuspendedTitle;

  /// No description provided for @accountSuspendedBody.
  ///
  /// In pt, this message translates to:
  /// **'A tua conta está temporariamente suspensa.\n\nContinuas a poder ver as praias.'**
  String get accountSuspendedBody;

  /// No description provided for @accountSuspendedBodyUntil.
  ///
  /// In pt, this message translates to:
  /// **'A tua conta está temporariamente suspensa até {date}.\n\nContinuas a poder ver as praias. Podes voltar a contribuir após esse período.'**
  String accountSuspendedBodyUntil(String date);

  /// No description provided for @passwordEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Introduz a password'**
  String get passwordEmpty;

  /// No description provided for @passwordMinLength.
  ///
  /// In pt, this message translates to:
  /// **'Mínimo 8 caracteres'**
  String get passwordMinLength;

  /// No description provided for @passwordNeedsUppercase.
  ///
  /// In pt, this message translates to:
  /// **'Precisa de uma letra maiúscula'**
  String get passwordNeedsUppercase;

  /// No description provided for @passwordNeedsLowercase.
  ///
  /// In pt, this message translates to:
  /// **'Precisa de uma letra minúscula'**
  String get passwordNeedsLowercase;

  /// No description provided for @passwordNeedsDigitOrSpecial.
  ///
  /// In pt, this message translates to:
  /// **'Precisa de um número ou caractere especial'**
  String get passwordNeedsDigitOrSpecial;

  /// No description provided for @passwordStrengthWeak.
  ///
  /// In pt, this message translates to:
  /// **'Fraca'**
  String get passwordStrengthWeak;

  /// No description provided for @passwordStrengthFair.
  ///
  /// In pt, this message translates to:
  /// **'Razoável'**
  String get passwordStrengthFair;

  /// No description provided for @passwordStrengthGood.
  ///
  /// In pt, this message translates to:
  /// **'Boa'**
  String get passwordStrengthGood;

  /// No description provided for @passwordStrengthStrong.
  ///
  /// In pt, this message translates to:
  /// **'Forte'**
  String get passwordStrengthStrong;

  /// No description provided for @passwordReq8Chars.
  ///
  /// In pt, this message translates to:
  /// **'8+ caracteres'**
  String get passwordReq8Chars;

  /// No description provided for @passwordReqUppercase.
  ///
  /// In pt, this message translates to:
  /// **'Letra maiúscula (A–Z)'**
  String get passwordReqUppercase;

  /// No description provided for @passwordReqLowercase.
  ///
  /// In pt, this message translates to:
  /// **'Letra minúscula (a–z)'**
  String get passwordReqLowercase;

  /// No description provided for @passwordReqDigitOrSpecial.
  ///
  /// In pt, this message translates to:
  /// **'Número ou caractere especial'**
  String get passwordReqDigitOrSpecial;

  /// No description provided for @translateNote.
  ///
  /// In pt, this message translates to:
  /// **'Traduzir'**
  String get translateNote;

  /// No description provided for @showOriginal.
  ///
  /// In pt, this message translates to:
  /// **'Ver original'**
  String get showOriginal;

  /// No description provided for @translatedLabel.
  ///
  /// In pt, this message translates to:
  /// **'Traduzido'**
  String get translatedLabel;

  /// No description provided for @translateError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao traduzir · Tentar de novo'**
  String get translateError;

  /// No description provided for @translateSameLanguage.
  ///
  /// In pt, this message translates to:
  /// **'Nota já no teu idioma'**
  String get translateSameLanguage;

  /// No description provided for @onboardingSkip.
  ///
  /// In pt, this message translates to:
  /// **'Saltar'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In pt, this message translates to:
  /// **'Seguinte'**
  String get onboardingNext;

  /// No description provided for @onboardingStart.
  ///
  /// In pt, this message translates to:
  /// **'Começar'**
  String get onboardingStart;

  /// No description provided for @onboardingTitle1.
  ///
  /// In pt, this message translates to:
  /// **'Sabe antes de ir'**
  String get onboardingTitle1;

  /// No description provided for @onboardingBody1.
  ///
  /// In pt, this message translates to:
  /// **'Consulta o estado do mar, ondas, maré e qualidade da água de cada praia em tempo real'**
  String get onboardingBody1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In pt, this message translates to:
  /// **'Alertas da comunidade'**
  String get onboardingTitle2;

  /// No description provided for @onboardingBody2.
  ///
  /// In pt, this message translates to:
  /// **'Medusas, correntes fortes ou lotação — recebe avisos reportados por quem está na praia.'**
  String get onboardingBody2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In pt, this message translates to:
  /// **'As tuas praias favoritas'**
  String get onboardingTitle3;

  /// No description provided for @onboardingBody3.
  ///
  /// In pt, this message translates to:
  /// **'Guarda as praias que mais visitas e recebe notificações sobre as condições.'**
  String get onboardingBody3;
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
