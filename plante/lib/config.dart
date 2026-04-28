// Configuration simple pour l'URL du backend.
// Laisser `backendBaseUrl` vide pour utiliser la détection automatique
// (emulateur Android -> 10.0.2.2, iOS -> localhost, appareil réel -> IP locale).
// Pour tests sur appareil réel, définir directement l'URL complète du backend LAN.
// Exemple: 'http://192.168.0.106:8000'
// IMPORTANT: le port doit correspondre à celui d'uvicorn (run_backend.ps1 => 8000).
const String backendBaseUrl = 'http://192.168.0.102:8000'; // override auto-detection

// Optionnel: adresse LAN de la machine si vous préférez l'utiliser ailleurs.
const String backendLocalIp = '192.168.0.106';
