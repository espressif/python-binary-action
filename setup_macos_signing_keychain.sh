#!/bin/bash
# Import macOS Developer ID certificate into a temporary keychain for PyInstaller build-time signing.
# Required env: MACOS_SIGNING_IDENTITY, MACOS_CERTIFICATE (base64 .p12), MACOS_CERTIFICATE_PWD.
# The keychain persists for the remainder of the job (not deleted on exit).

set -eu
set +x

: "${MACOS_SIGNING_IDENTITY:?macos-signing-identity required}"
: "${MACOS_CERTIFICATE:?macos-certificate required}"
: "${MACOS_CERTIFICATE_PWD:?macos-certificate-pwd required}"

KEYCHAIN_NAME="pyinstaller-build.keychain"
KEYCHAIN_PATH="${HOME}/Library/Keychains/${KEYCHAIN_NAME}-db"
KEYCHAIN_PASSWORD=$(openssl rand -hex 32)
CERT_PASSWORD=$(printf '%s' "$MACOS_CERTIFICATE_PWD" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

# Register values for GitHub Actions log redaction (also covers downstream steps in this job).
echo "::add-mask::${MACOS_CERTIFICATE}"
echo "::add-mask::${MACOS_CERTIFICATE_PWD}"
echo "::add-mask::${CERT_PASSWORD}"
echo "::add-mask::${KEYCHAIN_PASSWORD}"

unset MACOS_CERTIFICATE_PWD

CERT_FILE=$(mktemp)
trap 'rm -f "$CERT_FILE"' EXIT

echo "Setting up keychain for PyInstaller code signing..."
security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_NAME" 2>/dev/null || true
security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"

_cert_b64=$(printf '%s' "$MACOS_CERTIFICATE" | tr -d ' \r\n\t')
unset MACOS_CERTIFICATE
if ! printf '%s' "$_cert_b64" | base64 --decode > "$CERT_FILE" 2>/dev/null; then
  printf '%s' "$_cert_b64" | base64 -D > "$CERT_FILE" 2>/dev/null || {
    echo "Error: macos-certificate could not be decoded. Use base64-encoded .p12 contents." >&2
    exit 1
  }
fi
unset _cert_b64
[ -s "$CERT_FILE" ] || { echo "Error: decoded certificate is empty." >&2; exit 1; }

if ! security import "$CERT_FILE" -f pkcs12 -k "$KEYCHAIN_PATH" -P "$CERT_PASSWORD" \
  -T /usr/bin/codesign -T /usr/bin/security 2>/dev/null; then
  echo "Error: Failed to import certificate into keychain." >&2
  exit 1
fi
unset CERT_PASSWORD

security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
unset KEYCHAIN_PASSWORD

existing=$(security list-keychains -d user | sed 's/^[[:space:]]*"//;s/"[[:space:]]*$//' | tr '\n' ' ')
# shellcheck disable=SC2086
security list-keychains -d user -s "$KEYCHAIN_PATH" $existing
security default-keychain -s "$KEYCHAIN_PATH"

echo "Keychain ready for identity: $MACOS_SIGNING_IDENTITY"
