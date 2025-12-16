#!/bin/bash
set -e

KC_URL="https://rhbk-demo-keycloak.apps.cluster-lqrqg.lqrqg.sandbox1285.opentlc.com"

echo "============================================"
echo " Configuración WebAuthn Passwordless"
echo "============================================"
echo ""

# Obtener token
echo "[1/3] Obteniendo token de acceso..."
TOKEN=$(curl -sk -X POST "$KC_URL/realms/master/protocol/openid-connect/token" \
  -d "client_id=admin-cli" \
  -d "username=temp-admin" \
  -d "password=2d5312bed1a84871b53a54fbc3d12912" \
  -d "grant_type=password" 2>/dev/null | jq -r '.access_token')

if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
  echo "❌ Error: No se pudo obtener token"
  exit 1
fi

echo "   ✓ Token obtenido"

# Verificar si el flujo browser-passwordless existe
echo ""
echo "[2/3] Verificando flujo browser-passwordless..."
FLOW_EXISTS=$(curl -sk -H "Authorization: Bearer $TOKEN" \
  "$KC_URL/admin/realms/master/authentication/flows" 2>/dev/null | \
  jq -r '.[] | select(.alias=="browser-passwordless") | .alias')

if [ "$FLOW_EXISTS" != "browser-passwordless" ]; then
  echo "   Creando flujo browser-passwordless..."
  curl -sk -X POST -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    "$KC_URL/admin/realms/master/authentication/flows/browser/copy" \
    -d '{"newName": "browser-passwordless"}' 2>/dev/null
  
  sleep 2
  echo "   ✓ Flujo creado"
else
  echo "   ✓ Flujo ya existe"
fi

# Configurar el realm para usar browser-passwordless
echo ""
echo "[3/3] Activando flujo browser-passwordless en el realm..."
curl -sk -X PUT -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  "$KC_URL/admin/realms/master" \
  -d '{"browserFlow": "browser-passwordless"}' 2>/dev/null

echo "   ✓ Flujo browser actualizado"

echo ""
echo "============================================"
echo "✅ Flujo base configurado"
echo "============================================"
echo ""
echo "CONFIGURACIÓN MANUAL NECESARIA:"
echo ""
echo "El flujo browser-passwordless está activo pero necesita ajustes manuales:"
echo ""
echo "1. Ve a Admin Console:"
echo "   $KC_URL/admin/master/console/#/master/authentication"
echo ""
echo "2. En la pestaña 'Flows', selecciona 'browser-passwordless'"
echo ""
echo "3. Encuentra el sub-flow 'Browser - Conditional 2FA'"
echo ""
echo "4. En ese sub-flow, haz clic en el '+'  para agregar un paso"
echo ""
echo "5. Selecciona 'WebAuthn Passwordless Authenticator'"
echo ""
echo "6. Configúralo como 'Alternative' (mismo nivel que Password)"
echo ""
echo "7. Guarda los cambios"
echo ""
echo "Después de esto, los usuarios podrán:"
echo "- Ir a Account Console: $KC_URL/realms/master/account/"
echo "- Registrar su dispositivo biométrico en 'Signing in'"
echo "- Autenticarse sin contraseña"
echo ""
