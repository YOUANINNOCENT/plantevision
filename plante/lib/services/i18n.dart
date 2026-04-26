import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service de traduction simple et centralisé.
/// Utilisation :
///   - `I18n.instance.setLocale('en')`  (persiste automatiquement)
///   - `I18n.tr('login.submit')`  depuis n'importe où
///   - Envelopper MaterialApp dans `ListenableBuilder(listenable: I18n.instance, ...)`
///     pour que toute l'app se rebuild quand la langue change.
class I18n extends ChangeNotifier {
  I18n._();
  static final I18n instance = I18n._();

  static const List<String> supported = ['fr', 'en', 'es', 'de', 'it'];

  String _code = 'fr';
  String get code => _code;

  /// Charge la langue sauvegardée (à appeler avant runApp).
  /// L'écran de sélection de langue ayant été supprimé, on force le français
  /// à chaque démarrage et on efface toute sélection précédente persistée.
  Future<void> load() async {
    _code = 'fr';
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('locale');
    } catch (_) {}
  }

  /// Change la langue et la persiste.
  Future<void> setLocale(String code) async {
    if (!supported.contains(code)) return;
    _code = code;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('locale', code);
    } catch (_) {}
    notifyListeners();
  }

  /// Récupère une traduction. Fallback : français puis clé brute.
  String t(String key) {
    final dict = _translations[_code];
    final fr = _translations['fr'];
    return dict?[key] ?? fr?[key] ?? key;
  }

  /// Raccourci statique.
  static String tr(String key) => instance.t(key);

  /// Label humain d'une langue (pour le sélecteur).
  static String labelFor(String code) {
    switch (code) {
      case 'fr':
        return 'Français';
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      case 'de':
        return 'Deutsch';
      case 'it':
        return 'Italiano';
      default:
        return code;
    }
  }

  static const Map<String, Map<String, String>> _translations = {
    // =====================
    // FRANÇAIS
    // =====================
    'fr': {
      // Navigation
      'nav.home': 'ACCUEIL',
      'nav.analyse': 'ANALYSER',
      'nav.history': 'HISTORIQUE',
      'nav.dashboard': 'TABLEAU',
      'nav.settings': 'PARAMÈTRES',

      // Commun
      'common.save': 'Enregistrer',
      'common.saveChanges': 'Enregistrer les modifications',
      'common.cancel': 'Annuler',
      'common.delete': 'Supprimer',
      'common.back': 'Retour',
      'common.close': 'Fermer',
      'common.retry': 'Réessayer',
      'common.help': 'Aide',
      'common.loading': 'Chargement…',
      'common.error': 'Erreur',
      'common.yes': 'Oui',
      'common.no': 'Non',
      'common.search': 'Rechercher',
      'common.unknown': '—',

      // Connexion
      'login.brandSubtitle': 'Le Botaniste Digital',
      'login.welcome': 'Bienvenue',
      'login.title': 'Connectez-vous à votre guide',
      'login.subtitle': 'Explorez le monde végétal avec précision.',
      'login.email': 'EMAIL',
      'login.password': 'MOT DE PASSE',
      'login.forgot': 'Oublié ?',
      'login.submit': 'Se connecter',
      'login.newUser': 'Nouveau sur Vision ? ',
      'login.createAccount': 'Créer un compte',
      'login.emailIncorrect': 'Email incorrect',
      'login.passwordIncorrect': 'Mot de passe incorrect',
      'login.welcomeUser': 'Bienvenue',

      // Inscription
      'signup.title': 'Créer un compte',
      'signup.subtitle':
          'Rejoignez la communauté des botanistes digitaux.',
      'signup.fullName': 'NOM COMPLET',
      'signup.submit': 'Créer un compte',
      'signup.haveAccount': 'Déjà un compte ? ',
      'signup.accountExists': 'Un compte existe déjà avec cet email',
      'signup.success': 'Compte créé, connecte-toi pour continuer',

      // Historique
      'history.title': 'Historique',
      'history.empty': 'Aucune analyse enregistrée',

      // Tableau de bord
      'dashboard.section': 'TABLEAU DE BORD',
      'dashboard.title': 'Analyse des Données',
      'dashboard.totalScans': 'TOTAL SCANS',
      'dashboard.percentToxic': '% TOXIQUES',
      'dashboard.species': 'ESPÈCES',
      'dashboard.distribution': 'Répartition Florale',
      'dashboard.edible': 'COMESTIBLES',
      'dashboard.medicinal': 'MÉDICINALES',
      'dashboard.toxic': 'TOXIQUES',
      'dashboard.dominant': 'DOMINANT',
      'dashboard.locations': 'Localisation des Scans',
      'dashboard.locationsSub':
          'Concentration géographique des dernières analyses',
      'dashboard.alerts': 'Alertes Actives',
      'dashboard.viewAll': 'VOIR TOUT',
      'dashboard.noLocation':
          'Aucune localisation\nScanne une plante avec le GPS activé',

      // Scanner
      'scanner.hint': 'PLACER LE SPÉCIMEN AU CENTRE',
      'scanner.import': 'Importer',
      'scanner.flash': 'Flash',
      'scanner.sending': 'Envoi en cours…',
      'scanner.done': 'Analyse terminée',
      'scanner.imageSelected': 'Image sélectionnée',
      'scanner.send': 'Envoyer',
      'scanner.serverUnavailable': 'Serveur temporairement indisponible',
      'scanner.serverNotResponding': 'Le serveur ne répond pas',

      // Résultat
      'result.identified': 'IDENTIFIÉ',
      'result.notIdentified': 'Non identifié',
      'result.family': 'Famille',
      'result.plantHealth': 'Santé de la plante',
      'result.scientificName': 'Nom scientifique',
      'result.toxicity': 'Toxicité & Sécurité',
      'result.level': 'Niveau',
      'result.traditionalUses': 'Usages traditionnels',
      'result.edible': 'COMESTIBLE',
      'result.medicinal': 'MÉDICINALE',
      'result.askExpert': 'Besoin de conseils d\'expert ?',
      'result.askExpertSub':
          'Notre Botaniste IA peut vous guider sur l\'entretien, la récolte ou les bienfaits spécifiques de cette plante.',
      'result.askIA': 'Poser une question à l\'IA',
      'result.loadingInfo': 'Chargement des informations botaniques…',

      // Paramètres
      'settings.title': 'Paramètres du compte',
      'settings.saveChanges': 'Enregistrer les modifications',
      'settings.saved': 'Profil mis à jour avec succès',
      'settings.changePassword': 'Changer le mot de passe',
      'settings.deleteAccount': 'Supprimer le compte',

      // Mot de passe
      'password.title': 'Changer le mot de passe',
      'password.heading': 'Sécurisez votre compte',
      'password.subtitle':
          'Maintenez l\'accès à votre herbier numérique en utilisant un mot de passe robuste et unique.',
      'password.current': 'MOT DE PASSE ACTUEL',
      'password.new': 'NOUVEAU MOT DE PASSE',
      'password.confirm': 'CONFIRMER LE NOUVEAU MOT DE PASSE',
      'password.strength': 'Force du mot de passe',
      'password.submit': 'Mettre à jour le mot de passe',
      'password.updating': 'Mise à jour…',
      'password.updated': 'Mot de passe mis à jour avec succès',
      'password.currentWrong': 'Mot de passe actuel incorrect',
      'password.mismatch': 'Les deux mots de passe ne correspondent pas',

      // Langue
      'language.title': 'Langue',
      'language.subtitle': 'Choisissez votre langue préférée',
      'language.saved': 'Langue mise à jour',
    },

    // =====================
    // ENGLISH
    // =====================
    'en': {
      'nav.home': 'HOME',
      'nav.analyse': 'ANALYZE',
      'nav.history': 'HISTORY',
      'nav.dashboard': 'DASHBOARD',
      'nav.settings': 'SETTINGS',

      'common.save': 'Save',
      'common.saveChanges': 'Save changes',
      'common.cancel': 'Cancel',
      'common.delete': 'Delete',
      'common.back': 'Back',
      'common.close': 'Close',
      'common.retry': 'Retry',
      'common.help': 'Help',
      'common.loading': 'Loading…',
      'common.error': 'Error',
      'common.yes': 'Yes',
      'common.no': 'No',
      'common.search': 'Search',
      'common.unknown': '—',

      'login.brandSubtitle': 'The Digital Botanist',
      'login.welcome': 'Welcome',
      'login.title': 'Sign in to your guide',
      'login.subtitle': 'Explore the plant world with precision.',
      'login.email': 'EMAIL',
      'login.password': 'PASSWORD',
      'login.forgot': 'Forgot?',
      'login.submit': 'Sign in',
      'login.newUser': 'New to Vision? ',
      'login.createAccount': 'Create an account',
      'login.emailIncorrect': 'Incorrect email',
      'login.passwordIncorrect': 'Incorrect password',
      'login.welcomeUser': 'Welcome',

      'signup.title': 'Create an account',
      'signup.subtitle': 'Join the community of digital botanists.',
      'signup.fullName': 'FULL NAME',
      'signup.submit': 'Create account',
      'signup.haveAccount': 'Already have an account? ',
      'signup.accountExists': 'An account already exists with this email',
      'signup.success': 'Account created, sign in to continue',

      'history.title': 'History',
      'history.empty': 'No analysis recorded',

      'dashboard.section': 'DASHBOARD',
      'dashboard.title': 'Data Analysis',
      'dashboard.totalScans': 'TOTAL SCANS',
      'dashboard.percentToxic': '% TOXIC',
      'dashboard.species': 'SPECIES',
      'dashboard.distribution': 'Floral Distribution',
      'dashboard.edible': 'EDIBLE',
      'dashboard.medicinal': 'MEDICINAL',
      'dashboard.toxic': 'TOXIC',
      'dashboard.dominant': 'DOMINANT',
      'dashboard.locations': 'Scan Locations',
      'dashboard.locationsSub':
          'Geographical concentration of recent analyses',
      'dashboard.alerts': 'Active Alerts',
      'dashboard.viewAll': 'VIEW ALL',
      'dashboard.noLocation':
          'No location yet\nScan a plant with GPS enabled',

      'scanner.hint': 'CENTER THE SPECIMEN',
      'scanner.import': 'Import',
      'scanner.flash': 'Flash',
      'scanner.sending': 'Sending…',
      'scanner.done': 'Analysis complete',
      'scanner.imageSelected': 'Image selected',
      'scanner.send': 'Send',
      'scanner.serverUnavailable': 'Server temporarily unavailable',
      'scanner.serverNotResponding': 'Server not responding',

      'result.identified': 'IDENTIFIED',
      'result.notIdentified': 'Not identified',
      'result.family': 'Family',
      'result.plantHealth': 'Plant health',
      'result.scientificName': 'Scientific name',
      'result.toxicity': 'Toxicity & Safety',
      'result.level': 'Level',
      'result.traditionalUses': 'Traditional uses',
      'result.edible': 'EDIBLE',
      'result.medicinal': 'MEDICINAL',
      'result.askExpert': 'Need expert advice?',
      'result.askExpertSub':
          'Our AI Botanist can guide you on care, harvest or specific benefits of this plant.',
      'result.askIA': 'Ask the AI',
      'result.loadingInfo': 'Loading botanical information…',

      'settings.title': 'Account settings',
      'settings.saveChanges': 'Save changes',
      'settings.saved': 'Profile updated successfully',
      'settings.changePassword': 'Change password',
      'settings.deleteAccount': 'Delete account',

      'password.title': 'Change password',
      'password.heading': 'Secure your account',
      'password.subtitle':
          'Keep access to your digital herbarium with a strong and unique password.',
      'password.current': 'CURRENT PASSWORD',
      'password.new': 'NEW PASSWORD',
      'password.confirm': 'CONFIRM NEW PASSWORD',
      'password.strength': 'Password strength',
      'password.submit': 'Update password',
      'password.updating': 'Updating…',
      'password.updated': 'Password updated successfully',
      'password.currentWrong': 'Current password is incorrect',
      'password.mismatch': 'Passwords do not match',

      'language.title': 'Language',
      'language.subtitle': 'Choose your preferred language',
      'language.saved': 'Language updated',
    },

    // =====================
    // ESPAÑOL
    // =====================
    'es': {
      'nav.home': 'INICIO',
      'nav.analyse': 'ANALIZAR',
      'nav.history': 'HISTORIAL',
      'nav.dashboard': 'PANEL',
      'nav.settings': 'AJUSTES',

      'common.save': 'Guardar',
      'common.saveChanges': 'Guardar cambios',
      'common.cancel': 'Cancelar',
      'common.delete': 'Eliminar',
      'common.back': 'Volver',
      'common.close': 'Cerrar',
      'common.retry': 'Reintentar',
      'common.help': 'Ayuda',
      'common.loading': 'Cargando…',
      'common.error': 'Error',
      'common.yes': 'Sí',
      'common.no': 'No',
      'common.search': 'Buscar',
      'common.unknown': '—',

      'login.brandSubtitle': 'El Botánico Digital',
      'login.welcome': 'Bienvenido',
      'login.title': 'Inicia sesión en tu guía',
      'login.subtitle': 'Explora el mundo vegetal con precisión.',
      'login.email': 'CORREO',
      'login.password': 'CONTRASEÑA',
      'login.forgot': '¿Olvidada?',
      'login.submit': 'Iniciar sesión',
      'login.newUser': '¿Nuevo en Vision? ',
      'login.createAccount': 'Crear una cuenta',
      'login.emailIncorrect': 'Correo incorrecto',
      'login.passwordIncorrect': 'Contraseña incorrecta',
      'login.welcomeUser': 'Bienvenido',

      'signup.title': 'Crear una cuenta',
      'signup.subtitle': 'Únete a la comunidad de botánicos digitales.',
      'signup.fullName': 'NOMBRE COMPLETO',
      'signup.submit': 'Crear cuenta',
      'signup.haveAccount': '¿Ya tienes una cuenta? ',
      'signup.accountExists': 'Ya existe una cuenta con este correo',
      'signup.success': 'Cuenta creada, inicia sesión para continuar',

      'history.title': 'Historial',
      'history.empty': 'Sin análisis registrados',

      'dashboard.section': 'PANEL',
      'dashboard.title': 'Análisis de Datos',
      'dashboard.totalScans': 'TOTAL ESCANEOS',
      'dashboard.percentToxic': '% TÓXICOS',
      'dashboard.species': 'ESPECIES',
      'dashboard.distribution': 'Distribución Floral',
      'dashboard.edible': 'COMESTIBLES',
      'dashboard.medicinal': 'MEDICINALES',
      'dashboard.toxic': 'TÓXICAS',
      'dashboard.dominant': 'DOMINANTE',
      'dashboard.locations': 'Ubicación de Escaneos',
      'dashboard.locationsSub':
          'Concentración geográfica de los análisis recientes',
      'dashboard.alerts': 'Alertas Activas',
      'dashboard.viewAll': 'VER TODO',
      'dashboard.noLocation':
          'Sin ubicación\nEscanea una planta con el GPS activado',

      'scanner.hint': 'CENTRA EL ESPÉCIMEN',
      'scanner.import': 'Importar',
      'scanner.flash': 'Flash',
      'scanner.sending': 'Enviando…',
      'scanner.done': 'Análisis completo',
      'scanner.imageSelected': 'Imagen seleccionada',
      'scanner.send': 'Enviar',
      'scanner.serverUnavailable': 'Servidor temporalmente no disponible',
      'scanner.serverNotResponding': 'El servidor no responde',

      'result.identified': 'IDENTIFICADA',
      'result.notIdentified': 'No identificada',
      'result.family': 'Familia',
      'result.plantHealth': 'Salud de la planta',
      'result.scientificName': 'Nombre científico',
      'result.toxicity': 'Toxicidad y Seguridad',
      'result.level': 'Nivel',
      'result.traditionalUses': 'Usos tradicionales',
      'result.edible': 'COMESTIBLE',
      'result.medicinal': 'MEDICINAL',
      'result.askExpert': '¿Necesitas consejo experto?',
      'result.askExpertSub':
          'Nuestro Botánico IA puede orientarte sobre el cuidado, la cosecha o los beneficios específicos de esta planta.',
      'result.askIA': 'Preguntar a la IA',
      'result.loadingInfo': 'Cargando información botánica…',

      'settings.title': 'Ajustes de la cuenta',
      'settings.saveChanges': 'Guardar cambios',
      'settings.saved': 'Perfil actualizado correctamente',
      'settings.changePassword': 'Cambiar contraseña',
      'settings.deleteAccount': 'Eliminar cuenta',

      'password.title': 'Cambiar contraseña',
      'password.heading': 'Protege tu cuenta',
      'password.subtitle':
          'Mantén el acceso a tu herbario digital con una contraseña fuerte y única.',
      'password.current': 'CONTRASEÑA ACTUAL',
      'password.new': 'NUEVA CONTRASEÑA',
      'password.confirm': 'CONFIRMAR NUEVA CONTRASEÑA',
      'password.strength': 'Fuerza de la contraseña',
      'password.submit': 'Actualizar contraseña',
      'password.updating': 'Actualizando…',
      'password.updated': 'Contraseña actualizada correctamente',
      'password.currentWrong': 'La contraseña actual es incorrecta',
      'password.mismatch': 'Las contraseñas no coinciden',

      'language.title': 'Idioma',
      'language.subtitle': 'Elige tu idioma preferido',
      'language.saved': 'Idioma actualizado',
    },

    // =====================
    // DEUTSCH
    // =====================
    'de': {
      'nav.home': 'START',
      'nav.analyse': 'SCANNEN',
      'nav.history': 'VERLAUF',
      'nav.dashboard': 'ÜBERSICHT',
      'nav.settings': 'EINSTELLUNGEN',

      'common.save': 'Speichern',
      'common.saveChanges': 'Änderungen speichern',
      'common.cancel': 'Abbrechen',
      'common.delete': 'Löschen',
      'common.back': 'Zurück',
      'common.close': 'Schließen',
      'common.retry': 'Erneut versuchen',
      'common.help': 'Hilfe',
      'common.loading': 'Lädt…',
      'common.error': 'Fehler',
      'common.yes': 'Ja',
      'common.no': 'Nein',
      'common.search': 'Suchen',
      'common.unknown': '—',

      'login.brandSubtitle': 'Der digitale Botaniker',
      'login.welcome': 'Willkommen',
      'login.title': 'Melde dich bei deinem Führer an',
      'login.subtitle': 'Erkunde die Pflanzenwelt mit Präzision.',
      'login.email': 'E-MAIL',
      'login.password': 'PASSWORT',
      'login.forgot': 'Vergessen?',
      'login.submit': 'Anmelden',
      'login.newUser': 'Neu bei Vision? ',
      'login.createAccount': 'Konto erstellen',
      'login.emailIncorrect': 'Falsche E-Mail',
      'login.passwordIncorrect': 'Falsches Passwort',
      'login.welcomeUser': 'Willkommen',

      'signup.title': 'Konto erstellen',
      'signup.subtitle':
          'Tritt der Gemeinschaft digitaler Botaniker bei.',
      'signup.fullName': 'VOLLSTÄNDIGER NAME',
      'signup.submit': 'Konto erstellen',
      'signup.haveAccount': 'Schon ein Konto? ',
      'signup.accountExists': 'Mit dieser E-Mail existiert bereits ein Konto',
      'signup.success': 'Konto erstellt, melde dich zum Fortfahren an',

      'history.title': 'Verlauf',
      'history.empty': 'Keine Analyse gespeichert',

      'dashboard.section': 'ÜBERSICHT',
      'dashboard.title': 'Datenanalyse',
      'dashboard.totalScans': 'SCANS GESAMT',
      'dashboard.percentToxic': '% GIFTIG',
      'dashboard.species': 'ARTEN',
      'dashboard.distribution': 'Pflanzenverteilung',
      'dashboard.edible': 'ESSBAR',
      'dashboard.medicinal': 'HEIL-',
      'dashboard.toxic': 'GIFTIG',
      'dashboard.dominant': 'DOMINANT',
      'dashboard.locations': 'Scan-Standorte',
      'dashboard.locationsSub': 'Geografische Konzentration der Analysen',
      'dashboard.alerts': 'Aktive Warnungen',
      'dashboard.viewAll': 'ALLE ANZEIGEN',
      'dashboard.noLocation':
          'Kein Standort\nScanne eine Pflanze mit aktiviertem GPS',

      'scanner.hint': 'EXEMPLAR ZENTRIEREN',
      'scanner.import': 'Import',
      'scanner.flash': 'Blitz',
      'scanner.sending': 'Senden…',
      'scanner.done': 'Analyse abgeschlossen',
      'scanner.imageSelected': 'Bild ausgewählt',
      'scanner.send': 'Senden',
      'scanner.serverUnavailable': 'Server vorübergehend nicht verfügbar',
      'scanner.serverNotResponding': 'Server antwortet nicht',

      'result.identified': 'IDENTIFIZIERT',
      'result.notIdentified': 'Nicht identifiziert',
      'result.family': 'Familie',
      'result.plantHealth': 'Pflanzengesundheit',
      'result.scientificName': 'Wissenschaftlicher Name',
      'result.toxicity': 'Toxizität & Sicherheit',
      'result.level': 'Stufe',
      'result.traditionalUses': 'Traditionelle Verwendungen',
      'result.edible': 'ESSBAR',
      'result.medicinal': 'HEILEND',
      'result.askExpert': 'Brauchst du Expertenrat?',
      'result.askExpertSub':
          'Unser KI-Botaniker kann dich zu Pflege, Ernte oder spezifischen Vorteilen dieser Pflanze beraten.',
      'result.askIA': 'Die KI fragen',
      'result.loadingInfo': 'Botanische Informationen werden geladen…',

      'settings.title': 'Kontoeinstellungen',
      'settings.saveChanges': 'Änderungen speichern',
      'settings.saved': 'Profil erfolgreich aktualisiert',
      'settings.changePassword': 'Passwort ändern',
      'settings.deleteAccount': 'Konto löschen',

      'password.title': 'Passwort ändern',
      'password.heading': 'Sichere dein Konto',
      'password.subtitle':
          'Behalte den Zugang zu deinem digitalen Herbarium mit einem starken, einzigartigen Passwort.',
      'password.current': 'AKTUELLES PASSWORT',
      'password.new': 'NEUES PASSWORT',
      'password.confirm': 'NEUES PASSWORT BESTÄTIGEN',
      'password.strength': 'Passwortstärke',
      'password.submit': 'Passwort aktualisieren',
      'password.updating': 'Aktualisiere…',
      'password.updated': 'Passwort erfolgreich aktualisiert',
      'password.currentWrong': 'Aktuelles Passwort ist falsch',
      'password.mismatch': 'Passwörter stimmen nicht überein',

      'language.title': 'Sprache',
      'language.subtitle': 'Wähle deine bevorzugte Sprache',
      'language.saved': 'Sprache aktualisiert',
    },

    // =====================
    // ITALIANO
    // =====================
    'it': {
      'nav.home': 'HOME',
      'nav.analyse': 'ANALIZZA',
      'nav.history': 'CRONOLOGIA',
      'nav.dashboard': 'DASHBOARD',
      'nav.settings': 'IMPOSTAZIONI',

      'common.save': 'Salva',
      'common.saveChanges': 'Salva modifiche',
      'common.cancel': 'Annulla',
      'common.delete': 'Elimina',
      'common.back': 'Indietro',
      'common.close': 'Chiudi',
      'common.retry': 'Riprova',
      'common.help': 'Aiuto',
      'common.loading': 'Caricamento…',
      'common.error': 'Errore',
      'common.yes': 'Sì',
      'common.no': 'No',
      'common.search': 'Cerca',
      'common.unknown': '—',

      'login.brandSubtitle': 'Il Botanico Digitale',
      'login.welcome': 'Benvenuto',
      'login.title': 'Accedi alla tua guida',
      'login.subtitle': 'Esplora il mondo vegetale con precisione.',
      'login.email': 'EMAIL',
      'login.password': 'PASSWORD',
      'login.forgot': 'Dimenticata?',
      'login.submit': 'Accedi',
      'login.newUser': 'Nuovo su Vision? ',
      'login.createAccount': 'Crea un account',
      'login.emailIncorrect': 'Email non corretta',
      'login.passwordIncorrect': 'Password non corretta',
      'login.welcomeUser': 'Benvenuto',

      'signup.title': 'Crea un account',
      'signup.subtitle': 'Unisciti alla comunità dei botanici digitali.',
      'signup.fullName': 'NOME COMPLETO',
      'signup.submit': 'Crea account',
      'signup.haveAccount': 'Hai già un account? ',
      'signup.accountExists': 'Esiste già un account con questa email',
      'signup.success': 'Account creato, accedi per continuare',

      'history.title': 'Cronologia',
      'history.empty': 'Nessuna analisi registrata',

      'dashboard.section': 'DASHBOARD',
      'dashboard.title': 'Analisi dei Dati',
      'dashboard.totalScans': 'SCANSIONI TOTALI',
      'dashboard.percentToxic': '% TOSSICHE',
      'dashboard.species': 'SPECIE',
      'dashboard.distribution': 'Distribuzione Floreale',
      'dashboard.edible': 'COMMESTIBILI',
      'dashboard.medicinal': 'MEDICINALI',
      'dashboard.toxic': 'TOSSICHE',
      'dashboard.dominant': 'DOMINANTE',
      'dashboard.locations': 'Posizione Scansioni',
      'dashboard.locationsSub':
          'Concentrazione geografica delle analisi recenti',
      'dashboard.alerts': 'Avvisi Attivi',
      'dashboard.viewAll': 'VEDI TUTTO',
      'dashboard.noLocation':
          'Nessuna posizione\nScansiona una pianta con il GPS attivato',

      'scanner.hint': 'CENTRA IL CAMPIONE',
      'scanner.import': 'Importa',
      'scanner.flash': 'Flash',
      'scanner.sending': 'Invio…',
      'scanner.done': 'Analisi completata',
      'scanner.imageSelected': 'Immagine selezionata',
      'scanner.send': 'Invia',
      'scanner.serverUnavailable': 'Server temporaneamente non disponibile',
      'scanner.serverNotResponding': 'Il server non risponde',

      'result.identified': 'IDENTIFICATA',
      'result.notIdentified': 'Non identificata',
      'result.family': 'Famiglia',
      'result.plantHealth': 'Salute della pianta',
      'result.scientificName': 'Nome scientifico',
      'result.toxicity': 'Tossicità e Sicurezza',
      'result.level': 'Livello',
      'result.traditionalUses': 'Usi tradizionali',
      'result.edible': 'COMMESTIBILE',
      'result.medicinal': 'MEDICINALE',
      'result.askExpert': 'Hai bisogno di consigli esperti?',
      'result.askExpertSub':
          'Il nostro Botanico IA può guidarti nella cura, nella raccolta o sui benefici specifici di questa pianta.',
      'result.askIA': 'Chiedi all\'IA',
      'result.loadingInfo': 'Caricamento informazioni botaniche…',

      'settings.title': 'Impostazioni account',
      'settings.saveChanges': 'Salva modifiche',
      'settings.saved': 'Profilo aggiornato con successo',
      'settings.changePassword': 'Cambia password',
      'settings.deleteAccount': 'Elimina account',

      'password.title': 'Cambia password',
      'password.heading': 'Proteggi il tuo account',
      'password.subtitle':
          'Mantieni l\'accesso al tuo erbario digitale con una password forte e unica.',
      'password.current': 'PASSWORD ATTUALE',
      'password.new': 'NUOVA PASSWORD',
      'password.confirm': 'CONFERMA NUOVA PASSWORD',
      'password.strength': 'Forza della password',
      'password.submit': 'Aggiorna password',
      'password.updating': 'Aggiornamento…',
      'password.updated': 'Password aggiornata con successo',
      'password.currentWrong': 'Password attuale non corretta',
      'password.mismatch': 'Le password non coincidono',

      'language.title': 'Lingua',
      'language.subtitle': 'Scegli la tua lingua preferita',
      'language.saved': 'Lingua aggiornata',
    },
  };
}
