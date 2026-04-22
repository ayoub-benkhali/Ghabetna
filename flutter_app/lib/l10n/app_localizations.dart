import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_fr.dart';

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
    Locale('ar'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ghabetna'**
  String get appTitle;

  /// No description provided for @dashboard.
  ///
  /// In fr, this message translates to:
  /// **'Tableau de bord'**
  String get dashboard;

  /// No description provided for @forests.
  ///
  /// In fr, this message translates to:
  /// **'Forêts'**
  String get forests;

  /// No description provided for @users.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateurs'**
  String get users;

  /// No description provided for @roles.
  ///
  /// In fr, this message translates to:
  /// **'Rôles'**
  String get roles;

  /// No description provided for @services.
  ///
  /// In fr, this message translates to:
  /// **'Services'**
  String get services;

  /// No description provided for @profile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get profile;

  /// No description provided for @logout.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get logout;

  /// No description provided for @administration.
  ///
  /// In fr, this message translates to:
  /// **'Administration'**
  String get administration;

  /// No description provided for @overview.
  ///
  /// In fr, this message translates to:
  /// **'Vue d\'ensemble'**
  String get overview;

  /// No description provided for @realtimeData.
  ///
  /// In fr, this message translates to:
  /// **'Données du système en temps réel'**
  String get realtimeData;

  /// No description provided for @parcelles.
  ///
  /// In fr, this message translates to:
  /// **'Parcelles'**
  String get parcelles;

  /// No description provided for @welcome.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue,'**
  String get welcome;

  /// No description provided for @reportIncident.
  ///
  /// In fr, this message translates to:
  /// **'Signaler un incident'**
  String get reportIncident;

  /// No description provided for @myReports.
  ///
  /// In fr, this message translates to:
  /// **'Mes signalements'**
  String get myReports;

  /// No description provided for @myProfile.
  ///
  /// In fr, this message translates to:
  /// **'Mon Profil'**
  String get myProfile;

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @rolesAndPermissions.
  ///
  /// In fr, this message translates to:
  /// **'Rôles & Permissions'**
  String get rolesAndPermissions;

  /// No description provided for @forestManagement.
  ///
  /// In fr, this message translates to:
  /// **'Gestion des Forêts'**
  String get forestManagement;

  /// No description provided for @adminServices.
  ///
  /// In fr, this message translates to:
  /// **'Services Administratifs'**
  String get adminServices;

  /// No description provided for @newRole.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau rôle'**
  String get newRole;

  /// No description provided for @editRole.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le rôle'**
  String get editRole;

  /// No description provided for @deleteRole.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce rôle ?'**
  String get deleteRole;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// No description provided for @create.
  ///
  /// In fr, this message translates to:
  /// **'Créer'**
  String get create;

  /// No description provided for @permissions.
  ///
  /// In fr, this message translates to:
  /// **'Permissions'**
  String get permissions;

  /// No description provided for @selectAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout sélectionner'**
  String get selectAll;

  /// No description provided for @clear.
  ///
  /// In fr, this message translates to:
  /// **'Effacer'**
  String get clear;

  /// No description provided for @newUser.
  ///
  /// In fr, this message translates to:
  /// **'Nouvel utilisateur'**
  String get newUser;

  /// No description provided for @newForest.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle forêt'**
  String get newForest;

  /// No description provided for @newService.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau service'**
  String get newService;

  /// No description provided for @loading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement…'**
  String get loading;

  /// No description provided for @supervisor.
  ///
  /// In fr, this message translates to:
  /// **'Superviseur'**
  String get supervisor;

  /// No description provided for @agent.
  ///
  /// In fr, this message translates to:
  /// **'Agent'**
  String get agent;

  /// No description provided for @incidents.
  ///
  /// In fr, this message translates to:
  /// **'Incidents'**
  String get incidents;

  /// No description provided for @map.
  ///
  /// In fr, this message translates to:
  /// **'Carte'**
  String get map;

  /// No description provided for @disconnect.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get disconnect;

  /// No description provided for @noRolesDefined.
  ///
  /// In fr, this message translates to:
  /// **'Aucun rôle défini'**
  String get noRolesDefined;

  /// No description provided for @noUsersDefined.
  ///
  /// In fr, this message translates to:
  /// **'Aucun utilisateur'**
  String get noUsersDefined;

  /// No description provided for @errorPrefix.
  ///
  /// In fr, this message translates to:
  /// **'Erreur:'**
  String get errorPrefix;

  /// No description provided for @nameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le nom est obligatoire'**
  String get nameRequired;

  /// No description provided for @tagline.
  ///
  /// In fr, this message translates to:
  /// **'Soyez la voix de la forêt\nRépondre à son appel est notre devoir.'**
  String get tagline;

  /// No description provided for @forestSurveillance.
  ///
  /// In fr, this message translates to:
  /// **'Surveillance forestière intelligente'**
  String get forestSurveillance;

  /// No description provided for @welcomeBack.
  ///
  /// In fr, this message translates to:
  /// **'Bon retour !'**
  String get welcomeBack;

  /// No description provided for @loginSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Entrez vos identifiants pour accéder à la plateforme'**
  String get loginSubtitle;

  /// No description provided for @emailAddress.
  ///
  /// In fr, this message translates to:
  /// **'Adresse email'**
  String get emailAddress;

  /// No description provided for @emailRequired.
  ///
  /// In fr, this message translates to:
  /// **'Email requis'**
  String get emailRequired;

  /// No description provided for @password.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get password;

  /// No description provided for @passwordRequired.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe requis'**
  String get passwordRequired;

  /// No description provided for @signIn.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get signIn;

  /// No description provided for @activateAccount.
  ///
  /// In fr, this message translates to:
  /// **'Activation de compte'**
  String get activateAccount;

  /// No description provided for @activateAccountSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Définissez votre mot de passe pour activer votre compte.'**
  String get activateAccountSubtitle;

  /// No description provided for @newPassword.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get newPassword;

  /// No description provided for @minChars.
  ///
  /// In fr, this message translates to:
  /// **'Minimum 8 caractères'**
  String get minChars;

  /// No description provided for @confirmPassword.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le mot de passe'**
  String get confirmPassword;

  /// No description provided for @passwordMismatch.
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe ne correspondent pas'**
  String get passwordMismatch;

  /// No description provided for @activateButton.
  ///
  /// In fr, this message translates to:
  /// **'Activer mon compte'**
  String get activateButton;

  /// No description provided for @accountActivated.
  ///
  /// In fr, this message translates to:
  /// **'Compte activé avec succès ! Connectez-vous.'**
  String get accountActivated;

  /// No description provided for @edit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// No description provided for @deleteConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ?'**
  String get deleteConfirm;

  /// No description provided for @deleteService.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce service ?'**
  String get deleteService;

  /// No description provided for @deleteForest.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cette forêt ?'**
  String get deleteForest;

  /// No description provided for @deleteParcelle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cette parcelle ?'**
  String get deleteParcelle;

  /// No description provided for @createForest.
  ///
  /// In fr, this message translates to:
  /// **'Créer une forêt'**
  String get createForest;

  /// No description provided for @drawParcelle.
  ///
  /// In fr, this message translates to:
  /// **'Dessiner une parcelle'**
  String get drawParcelle;

  /// No description provided for @closePolygon.
  ///
  /// In fr, this message translates to:
  /// **'Fermer le polygone'**
  String get closePolygon;

  /// No description provided for @undoLastPoint.
  ///
  /// In fr, this message translates to:
  /// **'Annuler dernier point'**
  String get undoLastPoint;

  /// No description provided for @clearAll.
  ///
  /// In fr, this message translates to:
  /// **'Effacer tout'**
  String get clearAll;

  /// No description provided for @minThreePoints.
  ///
  /// In fr, this message translates to:
  /// **'Dessinez au moins 3 points'**
  String get minThreePoints;

  /// No description provided for @parentForestBoundary.
  ///
  /// In fr, this message translates to:
  /// **'Limite forêt parente'**
  String get parentForestBoundary;

  /// No description provided for @forestBoundary.
  ///
  /// In fr, this message translates to:
  /// **'Limite forêt'**
  String get forestBoundary;

  /// No description provided for @currentParcelle.
  ///
  /// In fr, this message translates to:
  /// **'Parcelle en cours'**
  String get currentParcelle;

  /// No description provided for @editName.
  ///
  /// In fr, this message translates to:
  /// **'Modifier mon nom'**
  String get editName;

  /// No description provided for @editNameTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le nom'**
  String get editNameTitle;

  /// No description provided for @editPhone.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le téléphone'**
  String get editPhone;

  /// No description provided for @identifier.
  ///
  /// In fr, this message translates to:
  /// **'Identifiant'**
  String get identifier;

  /// No description provided for @assignedParcelle.
  ///
  /// In fr, this message translates to:
  /// **'Parcelle assignée'**
  String get assignedParcelle;

  /// No description provided for @noParcelleAssigned.
  ///
  /// In fr, this message translates to:
  /// **'Aucune parcelle assignée'**
  String get noParcelleAssigned;

  /// No description provided for @assignedForest.
  ///
  /// In fr, this message translates to:
  /// **'Forêt assignée'**
  String get assignedForest;

  /// No description provided for @noForestAssigned.
  ///
  /// In fr, this message translates to:
  /// **'Aucune forêt assignée'**
  String get noForestAssigned;

  /// No description provided for @retry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// No description provided for @noIncidents.
  ///
  /// In fr, this message translates to:
  /// **'Aucun incident signalé'**
  String get noIncidents;

  /// No description provided for @status.
  ///
  /// In fr, this message translates to:
  /// **'Statut'**
  String get status;

  /// No description provided for @reset.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser'**
  String get reset;

  /// No description provided for @apply.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer'**
  String get apply;

  /// No description provided for @mapView.
  ///
  /// In fr, this message translates to:
  /// **'Vue carte'**
  String get mapView;

  /// No description provided for @listView.
  ///
  /// In fr, this message translates to:
  /// **'Vue liste'**
  String get listView;

  /// No description provided for @pending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get pending;

  /// No description provided for @inProgress.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get inProgress;

  /// No description provided for @resolved.
  ///
  /// In fr, this message translates to:
  /// **'Résolu'**
  String get resolved;

  /// No description provided for @rejected.
  ///
  /// In fr, this message translates to:
  /// **'Rejeté'**
  String get rejected;

  /// No description provided for @critical.
  ///
  /// In fr, this message translates to:
  /// **'Critique'**
  String get critical;

  /// No description provided for @unknown.
  ///
  /// In fr, this message translates to:
  /// **'Inconnu'**
  String get unknown;

  /// No description provided for @closedIncident.
  ///
  /// In fr, this message translates to:
  /// **'Cet incident est clôturé.'**
  String get closedIncident;

  /// No description provided for @incidentUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Incident mis à jour'**
  String get incidentUpdated;

  /// No description provided for @supervisorActions.
  ///
  /// In fr, this message translates to:
  /// **'Actions superviseur'**
  String get supervisorActions;

  /// No description provided for @supervisorComment.
  ///
  /// In fr, this message translates to:
  /// **'Commentaire (optionnel)'**
  String get supervisorComment;

  /// No description provided for @incidentDetail.
  ///
  /// In fr, this message translates to:
  /// **'Détail de l\'incident'**
  String get incidentDetail;

  /// No description provided for @description.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @location.
  ///
  /// In fr, this message translates to:
  /// **'Localisation'**
  String get location;

  /// No description provided for @reportedOn.
  ///
  /// In fr, this message translates to:
  /// **'Signalé le'**
  String get reportedOn;

  /// No description provided for @photo.
  ///
  /// In fr, this message translates to:
  /// **'Photo'**
  String get photo;

  /// No description provided for @tapToZoom.
  ///
  /// In fr, this message translates to:
  /// **'Appuyer pour agrandir'**
  String get tapToZoom;

  /// No description provided for @typeIncendie.
  ///
  /// In fr, this message translates to:
  /// **'Incendie'**
  String get typeIncendie;

  /// No description provided for @typeCoupeIllegale.
  ///
  /// In fr, this message translates to:
  /// **'Coupe illégale'**
  String get typeCoupeIllegale;

  /// No description provided for @typeMaladie.
  ///
  /// In fr, this message translates to:
  /// **'Maladie végétale'**
  String get typeMaladie;

  /// No description provided for @typeDechet.
  ///
  /// In fr, this message translates to:
  /// **'Déchets'**
  String get typeDechet;

  /// No description provided for @typeTrafic.
  ///
  /// In fr, this message translates to:
  /// **'Trafic'**
  String get typeTrafic;

  /// No description provided for @typeRefugeSuspect.
  ///
  /// In fr, this message translates to:
  /// **'Refuge suspect'**
  String get typeRefugeSuspect;

  /// No description provided for @typeAutre.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get typeAutre;

  /// No description provided for @locationDisabled.
  ///
  /// In fr, this message translates to:
  /// **'Service de localisation désactivé'**
  String get locationDisabled;

  /// No description provided for @addDescription.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez ajouter une description'**
  String get addDescription;

  /// No description provided for @incidentReported.
  ///
  /// In fr, this message translates to:
  /// **'Incident signalé avec succès'**
  String get incidentReported;

  /// No description provided for @criticalIncident.
  ///
  /// In fr, this message translates to:
  /// **'Incident critique'**
  String get criticalIncident;

  /// No description provided for @criticalIncidentHint.
  ///
  /// In fr, this message translates to:
  /// **'Cochez si la situation nécessite une intervention urgente'**
  String get criticalIncidentHint;

  /// No description provided for @camera.
  ///
  /// In fr, this message translates to:
  /// **'Caméra'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In fr, this message translates to:
  /// **'Galerie'**
  String get gallery;

  /// No description provided for @sendReport.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le signalement'**
  String get sendReport;

  /// No description provided for @describeIncident.
  ///
  /// In fr, this message translates to:
  /// **'Décrivez l\'incident…'**
  String get describeIncident;

  /// No description provided for @locating.
  ///
  /// In fr, this message translates to:
  /// **'Localisation en cours...'**
  String get locating;

  /// No description provided for @locationUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Position non disponible, prenez une photo ou activez le GPS'**
  String get locationUnavailable;

  /// No description provided for @createUser.
  ///
  /// In fr, this message translates to:
  /// **'Créer un utilisateur'**
  String get createUser;

  /// No description provided for @manageAssignment.
  ///
  /// In fr, this message translates to:
  /// **'Gérer l\'affectation'**
  String get manageAssignment;

  /// No description provided for @active.
  ///
  /// In fr, this message translates to:
  /// **'Actif'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In fr, this message translates to:
  /// **'Inactif'**
  String get inactive;

  /// No description provided for @activate.
  ///
  /// In fr, this message translates to:
  /// **'Activer'**
  String get activate;

  /// No description provided for @deactivate.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver'**
  String get deactivate;

  /// No description provided for @roleRequired.
  ///
  /// In fr, this message translates to:
  /// **'Rôle *'**
  String get roleRequired;

  /// No description provided for @fullNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Nom complet *'**
  String get fullNameRequired;

  /// No description provided for @emailAddressRequired.
  ///
  /// In fr, this message translates to:
  /// **'Adresse email *'**
  String get emailAddressRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Email invalide'**
  String get emailInvalid;

  /// No description provided for @cinOptional.
  ///
  /// In fr, this message translates to:
  /// **'CIN (optionnel)'**
  String get cinOptional;

  /// No description provided for @phoneOptional.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone (optionnel)'**
  String get phoneOptional;

  /// No description provided for @serviceOptional.
  ///
  /// In fr, this message translates to:
  /// **'Service (optionnel)'**
  String get serviceOptional;

  /// No description provided for @cinInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Le CIN doit contenir exactement 8 chiffres'**
  String get cinInvalid;

  /// No description provided for @required.
  ///
  /// In fr, this message translates to:
  /// **'Requis'**
  String get required;

  /// No description provided for @noNone.
  ///
  /// In fr, this message translates to:
  /// **'— Aucun —'**
  String get noNone;

  /// No description provided for @noNoneF.
  ///
  /// In fr, this message translates to:
  /// **'— Aucune —'**
  String get noNoneF;

  /// No description provided for @selectOption.
  ///
  /// In fr, this message translates to:
  /// **'— Sélectionner —'**
  String get selectOption;

  /// No description provided for @noParcellInForest.
  ///
  /// In fr, this message translates to:
  /// **'Aucune parcelle dans cette forêt.'**
  String get noParcellInForest;

  /// No description provided for @assignmentOf.
  ///
  /// In fr, this message translates to:
  /// **'Affectation de {name}'**
  String assignmentOf(String name);

  /// No description provided for @currentAssignment.
  ///
  /// In fr, this message translates to:
  /// **'Affectation actuelle : {label}'**
  String currentAssignment(String label);

  /// No description provided for @chooseForest.
  ///
  /// In fr, this message translates to:
  /// **'1. Choisir la forêt'**
  String get chooseForest;

  /// No description provided for @chooseParcelle.
  ///
  /// In fr, this message translates to:
  /// **'2. Choisir la parcelle'**
  String get chooseParcelle;

  /// No description provided for @agentToParcelle.
  ///
  /// In fr, this message translates to:
  /// **'Agent → Parcelle'**
  String get agentToParcelle;

  /// No description provided for @supervisorToForest.
  ///
  /// In fr, this message translates to:
  /// **'Superviseur → Forêt'**
  String get supervisorToForest;

  /// No description provided for @noPermissionsAssigned.
  ///
  /// In fr, this message translates to:
  /// **'Aucune permission assignée'**
  String get noPermissionsAssigned;

  /// No description provided for @roleNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom du rôle *'**
  String get roleNameLabel;

  /// No description provided for @selected.
  ///
  /// In fr, this message translates to:
  /// **'sélectionnées'**
  String get selected;

  /// No description provided for @noRolesHint.
  ///
  /// In fr, this message translates to:
  /// **'Créez les rôles et leurs permissions\npour gérer les accès au système.'**
  String get noRolesHint;

  /// No description provided for @editService.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le service'**
  String get editService;

  /// No description provided for @serviceNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom du service *'**
  String get serviceNameLabel;

  /// No description provided for @type.
  ///
  /// In fr, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @willBeDeleted.
  ///
  /// In fr, this message translates to:
  /// **'sera supprimé. Les utilisateurs rattachés n\'auront plus de service assigné.'**
  String get willBeDeleted;

  /// No description provided for @noServicesDefined.
  ///
  /// In fr, this message translates to:
  /// **'Aucun service créé'**
  String get noServicesDefined;

  /// No description provided for @noServicesHint.
  ///
  /// In fr, this message translates to:
  /// **'Créez les services administratifs de la Direction\nGénérale des Forêts.'**
  String get noServicesHint;

  /// No description provided for @total.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @unknownArea.
  ///
  /// In fr, this message translates to:
  /// **'Surface inconnue'**
  String get unknownArea;

  /// No description provided for @delimited.
  ///
  /// In fr, this message translates to:
  /// **'Délimitée'**
  String get delimited;

  /// No description provided for @noLimit.
  ///
  /// In fr, this message translates to:
  /// **'Sans limite'**
  String get noLimit;

  /// No description provided for @deleteForestWarning.
  ///
  /// In fr, this message translates to:
  /// **'Cette action supprimera définitivement la forêt et toutes ses parcelles associées.'**
  String get deleteForestWarning;

  /// No description provided for @noForestsHint.
  ///
  /// In fr, this message translates to:
  /// **'Créez votre première forêt et délimitez\nses zones géographiques sur la carte.'**
  String get noForestsHint;

  /// No description provided for @noForestsRegistered.
  ///
  /// In fr, this message translates to:
  /// **'Aucune forêt enregistrée'**
  String get noForestsRegistered;

  /// No description provided for @editForest.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la forêt'**
  String get editForest;

  /// No description provided for @information.
  ///
  /// In fr, this message translates to:
  /// **'Informations'**
  String get information;

  /// No description provided for @forestNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la forêt *'**
  String get forestNameLabel;

  /// No description provided for @region.
  ///
  /// In fr, this message translates to:
  /// **'Région'**
  String get region;

  /// No description provided for @spatialBoundary.
  ///
  /// In fr, this message translates to:
  /// **'Délimitation spatiale'**
  String get spatialBoundary;

  /// No description provided for @noBoundaryDefined.
  ///
  /// In fr, this message translates to:
  /// **'Aucune limite définie'**
  String get noBoundaryDefined;

  /// No description provided for @pointsMinThree.
  ///
  /// In fr, this message translates to:
  /// **'point(s), min. 3'**
  String get pointsMinThree;

  /// No description provided for @points.
  ///
  /// In fr, this message translates to:
  /// **'points'**
  String get points;

  /// No description provided for @stopDrawing.
  ///
  /// In fr, this message translates to:
  /// **'Arrêter le dessin'**
  String get stopDrawing;

  /// No description provided for @drawBoundary.
  ///
  /// In fr, this message translates to:
  /// **'Dessiner la limite'**
  String get drawBoundary;

  /// No description provided for @drawingHint.
  ///
  /// In fr, this message translates to:
  /// **'Tapez sur la carte pour ajouter des points.\nMinimum 3 points pour former un polygone.'**
  String get drawingHint;

  /// No description provided for @drawingModeActive.
  ///
  /// In fr, this message translates to:
  /// **'Mode dessin actif, Tapez pour ajouter des points'**
  String get drawingModeActive;

  /// No description provided for @deleteParcelleWarning.
  ///
  /// In fr, this message translates to:
  /// **'Cette parcelle sera supprimée définitivement.'**
  String get deleteParcelleWarning;

  /// No description provided for @others.
  ///
  /// In fr, this message translates to:
  /// **'autres'**
  String get others;

  /// No description provided for @noParcelles.
  ///
  /// In fr, this message translates to:
  /// **'Aucune parcelle'**
  String get noParcelles;

  /// No description provided for @noParcellesHint.
  ///
  /// In fr, this message translates to:
  /// **'Dessinez des zones de patrouille à l\'intérieur de cette forêt.'**
  String get noParcellesHint;

  /// No description provided for @errorOccurred.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue'**
  String get errorOccurred;

  /// No description provided for @editParcelle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la parcelle'**
  String get editParcelle;

  /// No description provided for @newParcelle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle parcelle'**
  String get newParcelle;

  /// No description provided for @parcelleNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la parcelle *'**
  String get parcelleNameLabel;

  /// No description provided for @parcelleBoundary.
  ///
  /// In fr, this message translates to:
  /// **'Délimitation de la parcelle'**
  String get parcelleBoundary;

  /// No description provided for @noPolygonDrawn.
  ///
  /// In fr, this message translates to:
  /// **'Aucun polygone dessiné'**
  String get noPolygonDrawn;

  /// No description provided for @legend.
  ///
  /// In fr, this message translates to:
  /// **'Légende'**
  String get legend;

  /// No description provided for @drawingInsideForestHint.
  ///
  /// In fr, this message translates to:
  /// **'Tapez dans la forêt pour ajouter des points'**
  String get drawingInsideForestHint;

  /// No description provided for @accountInfo.
  ///
  /// In fr, this message translates to:
  /// **'Informations du compte'**
  String get accountInfo;

  /// No description provided for @memberSince.
  ///
  /// In fr, this message translates to:
  /// **'Membre depuis'**
  String get memberSince;

  /// No description provided for @cin.
  ///
  /// In fr, this message translates to:
  /// **'CIN'**
  String get cin;

  /// No description provided for @phone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get phone;

  /// No description provided for @systemStats.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques système'**
  String get systemStats;

  /// No description provided for @contactSupervisor.
  ///
  /// In fr, this message translates to:
  /// **'Contactez votre superviseur pour une affectation.'**
  String get contactSupervisor;

  /// No description provided for @reliabilityScore.
  ///
  /// In fr, this message translates to:
  /// **'Score de fiabilité'**
  String get reliabilityScore;

  /// No description provided for @scoreComingSoon.
  ///
  /// In fr, this message translates to:
  /// **'Disponible après le Sprint 4. Continuez à signaler des incidents !'**
  String get scoreComingSoon;

  /// No description provided for @contactAdmin.
  ///
  /// In fr, this message translates to:
  /// **'Contactez l\'administrateur.'**
  String get contactAdmin;

  /// No description provided for @incidentOverview.
  ///
  /// In fr, this message translates to:
  /// **'Vue d\'ensemble des incidents'**
  String get incidentOverview;

  /// No description provided for @editUser.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l\'utilisateur'**
  String get editUser;

  /// No description provided for @noUsersHint.
  ///
  /// In fr, this message translates to:
  /// **'Créez des comptes pour les agents,\nsuperviseurs et administrateurs.'**
  String get noUsersHint;

  /// No description provided for @activationEmailNote.
  ///
  /// In fr, this message translates to:
  /// **'Un email d\'activation sera envoyé à cet utilisateur pour qu\'il définisse son mot de passe.'**
  String get activationEmailNote;

  /// No description provided for @supervisorCommentBy.
  ///
  /// In fr, this message translates to:
  /// **'Commentaire de {name}'**
  String supervisorCommentBy(String name);

  /// No description provided for @selectForestFirst.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez d\'abord une forêt'**
  String get selectForestFirst;

  /// No description provided for @actions.
  ///
  /// In fr, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @authError401.
  ///
  /// In fr, this message translates to:
  /// **'Email ou mot de passe incorrect'**
  String get authError401;

  /// No description provided for @authError403.
  ///
  /// In fr, this message translates to:
  /// **'Accès refusé'**
  String get authError403;

  /// No description provided for @authError404.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur introuvable'**
  String get authError404;

  /// No description provided for @authErrorNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de connexion. Vérifiez votre réseau.'**
  String get authErrorNetwork;

  /// No description provided for @forestContext.
  ///
  /// In fr, this message translates to:
  /// **'Contexte forestier'**
  String get forestContext;

  /// No description provided for @geoContextUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Contexte géographique indisponible'**
  String get geoContextUnavailable;

  /// No description provided for @geoContextPending.
  ///
  /// In fr, this message translates to:
  /// **'Localisation forestière en cours d\'enrichissement…'**
  String get geoContextPending;

  /// No description provided for @area.
  ///
  /// In fr, this message translates to:
  /// **'Superficie'**
  String get area;

  /// No description provided for @geoContextNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Hors zone forestière enregistrée'**
  String get geoContextNotFound;

  /// No description provided for @admin.
  ///
  /// In fr, this message translates to:
  /// **'Administrateur'**
  String get admin;

  /// No description provided for @ha.
  ///
  /// In fr, this message translates to:
  /// **'ha'**
  String get ha;
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
      <String>['ar', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
