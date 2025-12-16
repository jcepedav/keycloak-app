# Configuración de Google Identity Provider

## Descripción

Este documento describe cómo configurar Google como proveedor de identidad (Identity Provider) en Keycloak para permitir que los usuarios inicien sesión con sus cuentas de Google.

## Prerequisitos

- Keycloak desplegado y funcionando
- Acceso a Google Cloud Console
- Secret `google-identity-provider-secret` creado en el namespace de Keycloak

## Paso 1: Crear OAuth 2.0 Client ID en Google Cloud Console

1. Ve a [Google Cloud Console - Credentials](https://console.cloud.google.com/apis/credentials)

2. Selecciona o crea un proyecto

3. Haz clic en **"Create Credentials"** → **"OAuth 2.0 Client ID"**

4. Si es la primera vez, configura la pantalla de consentimiento OAuth:
   - User Type: External
   - App name: Keycloak Demo (o el nombre que prefieras)
   - User support email: tu email
   - Developer contact information: tu email

5. Crea el OAuth Client ID:
   - Application type: **Web application**
   - Name: **Keycloak RHBK Demo**
   - Authorized redirect URIs:
     ```
     https://<KEYCLOAK_ROUTE>/realms/master/broker/google/endpoint
     ```
     Ejemplo:
     ```
     https://rhbk-demo-keycloak.apps.cluster-lqrqg.lqrqg.sandbox1285.opentlc.com/realms/master/broker/google/endpoint
     ```

6. Guarda el **Client ID** y **Client Secret**

## Paso 2: Crear Secret en Kubernetes

Crea un archivo `.env` local (NO lo agregues a Git):

```bash
client_id=TU_GOOGLE_CLIENT_ID
Client_secret=TU_GOOGLE_CLIENT_SECRET
```

Ejecuta el siguiente comando para crear el secret:

```bash
source .env && kubectl create secret generic google-identity-provider-secret \
  -n keycloak \
  --from-literal=clientId="$client_id" \
  --from-literal=clientSecret="$Client_secret" \
  --dry-run=client -o yaml | kubectl apply -f -
```

## Paso 3: Configurar Google Identity Provider en Keycloak

### Opción A: Configuración Manual (Recomendada)

1. Accede a Keycloak Admin Console:
   ```
   https://<KEYCLOAK_ROUTE>/admin/master/console/
   ```

2. Ve a **"Identity providers"** en el menú lateral

3. Haz clic en **"Add provider"** → Selecciona **"Google"**

4. Configura:
   - **Alias:** `google`
   - **Display name:** `Google`
   - **Client ID:** (pega tu Client ID de Google)
   - **Client Secret:** (pega tu Client Secret de Google)

5. Haz clic en **"Save"**

### Opción B: Usar el Job de Kubernetes (Requiere ajustes)

El Job `scripts/job-google-idp-setup.yaml` puede ser usado pero requiere que el secret esté creado primero.

```bash
kubectl apply -f scripts/job-google-idp-setup.yaml
```

**Nota:** Este Job puede fallar si Keycloak no está completamente listo. Verifica los logs:

```bash
kubectl logs -n keycloak -l job-name=keycloak-google-idp-setup
```

## Paso 4: Verificar la Configuración

1. Abre una ventana de incógnito en tu navegador

2. Ve a la URL de Keycloak:
   ```
   https://<KEYCLOAK_ROUTE>/realms/master/account/
   ```

3. Deberías ver el botón **"Sign in with Google"**

4. Haz clic y prueba iniciar sesión con tu cuenta de Google

## Solución de Problemas

### El botón de Google no aparece

- Verifica que el Identity Provider esté habilitado en la consola de administración
- Revisa que el redirect URI en Google Cloud Console sea exacto (incluyendo https://)

### Error de redirect_uri_mismatch

- Asegúrate de que la URL de redirección en Google Cloud Console coincida exactamente con:
  ```
  https://<KEYCLOAK_ROUTE>/realms/master/broker/google/endpoint
  ```

### Usuario redirigido a /admin/master/console/ sin permisos

- Esto es normal en el primer login con Google
- El usuario de Google no tiene permisos de administrador por defecto
- Para probar, usa el Account Console en lugar de Admin Console:
  ```
  https://<KEYCLOAK_ROUTE>/realms/master/account/
  ```

## Seguridad

- **NUNCA** commits el archivo `.env` a Git
- El `.gitignore` debe incluir `.env`
- Las credenciales solo existen en el Secret de Kubernetes
- Considera usar External Secrets Operator o Sealed Secrets para producción

## Referencias

- [Keycloak Google Identity Provider](https://www.keycloak.org/docs/latest/server_admin/#google)
- [Google OAuth 2.0 Setup](https://support.google.com/cloud/answer/6158849)
