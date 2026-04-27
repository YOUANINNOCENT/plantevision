// Configuration de l'URL du backend.
//
// Priorité (du plus haut au plus bas) :
//   1. Variable de build `--dart-define=BACKEND_URL=https://...`
//      Utilisée pour le build web Netlify (production) ET pour les builds
//      flutter run en local quand on veut pointer sur Render.
//   2. Constante `_kFallbackBackendUrl` ci-dessous (pratique pour le LAN
//      pendant le développement Flutter mobile sur ton WiFi).
//   3. Auto-detection (api_service.dart) : 10.0.2.2 sur emulateur Android,
//      127.0.0.1 sinon.
//
// Exemples :
//   flutter run --dart-define=BACKEND_URL=https://plante-backend-xxxx.onrender.com
//   flutter build web --release --dart-define=BACKEND_URL=https://plante-backend-xxxx.onrender.com

const String _kBackendUrlFromEnv = String.fromEnvironment('BACKEND_URL');

/// URL de fallback utilisée quand --dart-define=BACKEND_URL n'est pas fourni.
/// Laisse vide ('') pour activer l'auto-détection LAN.
/// Mets ton IP locale type 'http://192.168.0.106:8000' pour tester sur ton
/// téléphone connecté au même WiFi que ton PC.
const String _kFallbackBackendUrl = '';

/// URL effective du backend, exposée au reste de l'app.
/// Note : on compare a '' au lieu de .isNotEmpty parce que `String.isNotEmpty`
/// n'est pas evaluable dans une expression `const` en Dart.
const String backendBaseUrl = _kBackendUrlFromEnv == ''
    ? _kFallbackBackendUrl
    : _kBackendUrlFromEnv;

/// Adresse LAN brute (encore utilisée à un endroit ou deux historiquement).
const String backendLocalIp = '192.168.0.106';
