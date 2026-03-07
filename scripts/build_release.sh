#!/usr/bin/env bash
# Gera o App Bundle assinado para release (Play Store).
# Requer: android/key.properties e o keystore (.jks) configurados.
# Ver: android/key.properties.template

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
KEY_PROPERTIES="$PROJECT_ROOT/android/key.properties"

cd "$PROJECT_ROOT"

echo "==> Verificando key.properties..."
if [[ ! -f "$KEY_PROPERTIES" ]]; then
  echo "ERRO: android/key.properties nao encontrado."
  echo ""
  echo "Crie o arquivo copiando o exemplo:"
  echo "  cp android/key.properties.template android/key.properties"
  echo ""
  echo "Edite android/key.properties com suas credenciais reais:"
  echo "  storePassword=SENHA_DO_KEYSTORE"
  echo "  keyPassword=SENHA_DA_CHAVE"
  echo "  keyAlias=upload"
  echo "  storeFile=/caminho/absoluto/para/upload-keystore.jks"
  echo ""
  echo "Para criar um keystore novo:"
  echo "  keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload"
  exit 1
fi

echo "==> flutter pub get"
flutter pub get

echo "==> flutter analyze"
flutter analyze

echo "==> flutter test"
flutter test

echo "==> flutter build appbundle --release"
flutter build appbundle --release

AAB_PATH="$PROJECT_ROOT/build/app/outputs/bundle/release/app-release.aab"
echo ""
echo "=========================================="
echo "Build assinado gerado com sucesso!"
echo "=========================================="
echo ""
echo "Arquivo: $AAB_PATH"
echo ""
echo "Proximos passos:"
echo "  1. Acesse https://play.google.com/console"
echo "  2. Testar > Teste interno > Criar nova versao"
echo "  3. Faca upload do arquivo acima"
echo ""
