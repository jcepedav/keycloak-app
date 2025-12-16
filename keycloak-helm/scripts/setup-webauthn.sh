#!/bin/bash
set -e

KC_URL="https://rhbk-demo-keycloak.apps.cluster-lqrqg.lqrqg.sandbox1285.opentlc.com"

# Obtener token
echo "Obteniendo token de acceso..."
TOKEN=$(curl -sk -X POST "$KC_URL/realms/master/protocol/openid-connect/token" \
  -d "client_id=admin-cli" \
  -d "username=temp-admin" \
  -d "password=2d5312bed1a84871b53a54fbc3d12912" \
  -d "grant_type=password" 2>/dev/null | jq -r '.access_token')

if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
  echo "Error: No se pudo obtener token"
  exit 1
fi

echo "Token obtenido exitosamente"

# Obtener el flujo browser
echo "Obteniendo información del flujo browser..."
BROWSER_FLOW_ID=$(curl -sk -H "Authorization: Bearer $TOKEN" \
  "$KC_URL/admin/realms/master/authentication/flows" 2>/dev/null | \
  jq -r '.[] | select(.alias=="browser") | .id')

echo "Browser Flow ID: $BROWSER_FLOW_ID"

# Obtener ejecuciones usando el alias en lugar del ID
echo "Obteniendo ejecuciones del browser flow..."
EXECUTIONS=$(curl -sk -H "Authorization: Bearer $TOKEN" \
  "$KC_URL/admin/realms/master/authentication/flows/browser/executions" 2>/dev/null)

echo "Ejecuciones actuales:"
if echo "$EXECUTIONS" | jq -e 'type == "array"' > /dev/null 2>&1; then
  echo "$EXECUTIONS" | jq -r '.[] | "- \(.displayName) (providerId: \(.providerId))"'
else
  echo "Error al obtener ejecuciones. Response:"
  echo "$EXECUTIONS"
fi

# Buscar el sub-flow de "forms"
FORMS_FLOW_ID=$(echo "$EXECUTIONS" | jq -r '.[] | select(.displayName=="forms") | .flowId')

if [ -z "$FORMS_FLOW_ID" ] || [ "$FORMS_FLOW_ID" = "null" ]; then
  echo "Error: No se encontró el sub-flow 'forms'"
  exit 1
fi

echo "Forms Flow ID: $FORMS_FLOW_ID"

# Obtener ejecuciones del forms flow usando alias
echo "Obteniendo ejecuciones del forms flow..."
FORMS_EXECUTIONS=$(curl -sk -H "Authorization: Bearer $TOKEN" \
  "$KC_URL/admin/realms/master/authentication/flows/forms/executions" 2>/dev/null)

echo "Ejecuciones del forms flow:"
echo "$FORMS_EXECUTIONS" | jq -r '.[] | "- \(.displayName) (providerId: \(.providerId))"'

# Verificar si WebAuthn ya está agregado
WEBAUTHN_EXISTS=$(echo "$FORMS_EXECUTIONS" | jq -r '.[] | select(.providerId=="webauthn-authenticator-passwordless") | .id')

if [ -n "$WEBAUTHN_EXISTS" ] && [ "$WEBAUTHN_EXISTS" != "null" ]; then
  echo "WebAuthn Passwordless ya existe en el flujo"
  echo "Actualizando configuración a ALTERNATIVE..."
  
  curl -sk -X PUT -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    "$KC_URL/admin/realms/master/authentication/flows/$FORMS_FLOW_ID/executions" \
    -d "{
      \"id\": \"$WEBAUTHN_EXISTS\",
      \"requirement\": \"ALTERNATIVE\"
    }" 2>/dev/null
  
  echo "WebAuthn configurado como ALTERNATIVE"
else
  echo "Agregando WebAuthn Passwordless al flujo forms..."
  
  # Buscar el sub-flow "Browser - Conditional 2FA"
  CONDITIONAL_2FA_ID=$(echo "$FORMS_EXECUTIONS" | jq -r '.[] | select(.displayName=="Browser - Conditional 2FA") | .flowId')
  
  if [ -n "$CONDITIONAL_2FA_ID" ] && [ "$CONDITIONAL_2FA_ID" != "null" ]; then
    echo "Agregando WebAuthn al sub-flow 'Browser - Conditional 2FA' (ID: $CONDITIONAL_2FA_ID)..."
    
    # Obtener el alias del sub-flow
    CONDITIONAL_2FA_ALIAS=$(curl -sk -H "Authorization: Bearer $TOKEN" \
      "$KC_URL/admin/realms/master/authentication/flows" 2>/dev/null | \
      jq -r ".[] | select(.id==\"$CONDITIONAL_2FA_ID\") | .alias")
    
    echo "Alias del sub-flow: $CONDITIONAL_2FA_ALIAS"
    
    # Agregar la ejecución de WebAuthn usando el endpoint correcto
    RESULT=$(curl -sk -X POST -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      "$KC_URL/admin/realms/master/authentication/flows/$CONDITIONAL_2FA_ALIAS/executions/execution" \
      -d '{
        "provider": "webauthn-authenticator-passwordless"
      }' 2>/dev/null)
    
    if [ -z "$RESULT" ]; then
      echo "WebAuthn Passwordless agregado exitosamente"
    else
      echo "Resultado: $RESULT"
    fi
  else
    echo "No se encontró el sub-flow 'Browser - Conditional 2FA'"
    exit 1
  fi
  
  sleep 2
  
  # Obtener el ID de la nueva ejecución
  FORMS_EXECUTIONS_NEW=$(curl -sk -H "Authorization: Bearer $TOKEN" \
    "$KC_URL/admin/realms/master/authentication/flows/$FORMS_FLOW_ID/executions" 2>/dev/null)
  
  WEBAUTHN_EXEC_ID=$(echo "$FORMS_EXECUTIONS_NEW" | jq -r '.[] | select(.providerId=="webauthn-authenticator-passwordless") | .id')
  
  if [ -n "$WEBAUTHN_EXEC_ID" ] && [ "$WEBAUTHN_EXEC_ID" != "null" ]; then
    echo "Configurando WebAuthn como ALTERNATIVE..."
    
    curl -sk -X PUT -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      "$KC_URL/admin/realms/master/authentication/flows/$FORMS_FLOW_ID/executions" \
      -d "{
        \"id\": \"$WEBAUTHN_EXEC_ID\",
        \"requirement\": \"ALTERNATIVE\"
      }" 2>/dev/null
    
    echo "WebAuthn configurado como ALTERNATIVE"
  fi
fi

echo ""
echo "✅ Configuración completada!"
echo ""
echo "Ahora ve a: $KC_URL/realms/master/account/"
echo "Ve a 'Signing in' y deberías ver la opción 'Security Key' o 'Passwordless'"
