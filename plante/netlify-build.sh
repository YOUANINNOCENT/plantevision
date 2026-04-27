#!/usr/bin/env bash
# Script de build Netlify pour Flutter Web.
# Telecharge le SDK Flutter, active le support web, build en release.
#
# Variables d'environnement attendues (definies dans Netlify > Site settings > Environment) :
#   - BACKEND_URL    : URL publique du backend Render (ex: https://plante-backend-xxxx.onrender.com)
#   - GROQ_API_KEY   : cle Groq pour le chat IA cote client
#   - FLUTTER_VERSION : version Flutter a installer (defaut: 3.24.5)

set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.24.5}"
FLUTTER_CHANNEL="${FLUTTER_CHANNEL:-stable}"

echo "==> Installation Flutter $FLUTTER_VERSION ($FLUTTER_CHANNEL)"
if [ ! -d "$HOME/flutter" ]; then
  curl -fsSL "https://storage.googleapis.com/flutter_infra_release/releases/${FLUTTER_CHANNEL}/linux/flutter_linux_${FLUTTER_VERSION}-${FLUTTER_CHANNEL}.tar.xz" \
    -o /tmp/flutter.tar.xz
  mkdir -p "$HOME"
  tar xf /tmp/flutter.tar.xz -C "$HOME"
  rm /tmp/flutter.tar.xz
fi
export PATH="$HOME/flutter/bin:$PATH"

# Empeche Flutter de contacter Google Analytics pendant le build CI
flutter --disable-analytics
flutter config --no-analytics
flutter config --enable-web

echo "==> Version Flutter installee :"
flutter --version

echo "==> Recuperation des dependances pub"
flutter pub get

echo "==> Build Flutter Web (release)"
# On injecte les variables sensibles via --dart-define pour qu'elles ne soient
# jamais en clair dans le code source.
BACKEND_URL_VAL="${BACKEND_URL:-}"
GROQ_API_KEY_VAL="${GROQ_API_KEY:-}"

if [ -z "$BACKEND_URL_VAL" ]; then
  echo "WARN: BACKEND_URL non definie dans l'environnement Netlify."
  echo "      L'app va tomber en fallback sur l'auto-detection."
fi
if [ -z "$GROQ_API_KEY_VAL" ]; then
  echo "WARN: GROQ_API_KEY non definie. Le chat IA renverra une erreur 401."
fi

flutter build web \
  --release \
  --dart-define=BACKEND_URL="$BACKEND_URL_VAL" \
  --dart-define=GROQ_API_KEY="$GROQ_API_KEY_VAL"

echo "==> Build OK, contenu dans build/web :"
ls -la build/web | head -20
