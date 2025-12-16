# Configuración de WebAuthn Passwordless

## Descripción

Este documento describe cómo configurar la autenticación sin contraseña (passwordless) usando WebAuthn en Keycloak. Esto permite a los usuarios autenticarse usando biometría (Touch ID, Face ID, huella digital) o llaves de seguridad físicas (YubiKey).

## Prerequisitos

- Keycloak desplegado y funcionando
- Acceso a Keycloak Admin Console
- Navegador moderno con soporte WebAuthn (Chrome, Safari, Edge, Firefox)
- Dispositivo con biometría o llave de seguridad FIDO2

## Navegadores y Dispositivos Soportados

| Navegador | macOS | Windows | Linux | iOS/iPadOS | Android |
|-----------|-------|---------|-------|------------|---------|
| Chrome    | ✅    | ✅      | ✅    | ✅         | ✅      |
| Safari    | ✅    | ❌      | ❌    | ✅         | ❌      |
| Edge      | ✅    | ✅      | ✅    | ❌         | ❌      |
| Firefox   | ✅    | ✅      | ✅    | ❌         | ✅      |

## Paso 1: Ejecutar el Script de Configuración Base

El script `scripts/setup-webauthn-passwordless.sh` prepara el flujo de autenticación:

```bash
cd /Users/juank1400/redhat/keycloak/keycloak-helm
./scripts/setup-webauthn-passwordless.sh
```

Este script:
1. Crea una copia del flujo `browser` llamado `browser-passwordless`
2. Configura el realm para usar este nuevo flujo

**Nota:** Este script solo prepara la base. La configuración de WebAuthn Passwordless debe hacerse manualmente en la siguiente sección.

## Paso 2: Configurar WebAuthn Passwordless en Admin Console

### 2.1 Acceder a la Consola de Administración

1. Ve a Keycloak Admin Console:
   ```
   https://<KEYCLOAK_ROUTE>/admin/master/console/
   ```

2. Inicia sesión con las credenciales de administrador:
   ```bash
   kubectl get secret rhbk-demo-initial-admin -n keycloak \
     -o jsonpath='{.data.username}' | base64 -d && echo
   
   kubectl get secret rhbk-demo-initial-admin -n keycloak \
     -o jsonpath='{.data.password}' | base64 -d && echo
   ```

### 2.2 Configurar el Flujo de Autenticación

1. En el menú lateral, ve a **"Authentication"**

2. En la pestaña **"Flows"**, selecciona **"browser-passwordless"** del menú desplegable

3. Verás una estructura similar a:
   ```
   browser-passwordless
   ├── Cookie (ALTERNATIVE)
   ├── Kerberos (DISABLED)
   ├── Identity Provider Redirector (ALTERNATIVE)
   └── browser-passwordless forms (ALTERNATIVE)
       ├── Username Password Form (REQUIRED)
       └── browser-passwordless Browser - Conditional 2FA (CONDITIONAL)
           ├── Condition - user configured (REQUIRED)
           └── Condition - credential (ALTERNATIVE)
               ├── OTP Form (ALTERNATIVE)
               ├── WebAuthn Authenticator (ALTERNATIVE)
               └── Recovery Authentication Code Form (ALTERNATIVE)
   ```

4. Encuentra el sub-flow **"browser-passwordless Browser - Conditional 2FA"** y expándelo

5. Dentro de ese sub-flow, haz clic en el botón **"+" (Add step)**

6. En el diálogo que aparece, selecciona **"WebAuthn Passwordless Authenticator"**

7. Configura el requirement como **"Alternative"**

8. Asegúrate de que quede al mismo nivel que:
   - OTP Form
   - WebAuthn Authenticator
   - Recovery Authentication Code Form

9. Haz clic en **"Save"**

### 2.3 Habilitar Required Action

1. Ve a la pestaña **"Required actions"**

2. Busca **"Webauthn Register Passwordless"**

3. Marca la casilla **"Enabled"**

4. (Opcional) Marca **"Default Action"** si quieres que todos los usuarios nuevos sean obligados a registrar un dispositivo

5. Haz clic en **"Save"**

### 2.4 Configurar WebAuthn Policy (Opcional)

1. Ve a **"Realm settings"** → **"Security defenses"** → **"WebAuthn Passwordless Policy"**

2. Configuraciones recomendadas:
   - **Relying Party Entity Name:** "Red Hat Keycloak Demo" (o el nombre de tu aplicación)
   - **Signature Algorithms:** ES256, RS256
   - **Relying Party ID:** (dejar vacío para usar el dominio actual)
   - **Attestation Conveyance Preference:** none
   - **Authenticator Attachment:** platform (para biometría del dispositivo)
   - **Require Resident Key:** Yes
   - **User Verification Requirement:** required
   - **Timeout:** 60 segundos

3. Haz clic en **"Save"**

## Paso 3: Registrar un Dispositivo Biométrico (Como Usuario)

### 3.1 Acceder al Account Console

1. Ve a:
   ```
   https://<KEYCLOAK_ROUTE>/realms/master/account/
   ```

2. Inicia sesión con tu usuario (puede ser con Google o usuario/contraseña tradicional)

### 3.2 Registrar el Dispositivo

1. En el menú lateral, ve a **"Account security"** → **"Signing in"**

2. Busca la sección **"Security Key"** o **"Passwordless"**

3. Haz clic en **"Set up Security Key"** o el botón de agregar (+)

4. El navegador te pedirá permiso para acceder al dispositivo biométrico:
   - **macOS/Mac:** "¿Deseas usar Touch ID para iniciar sesión?"
   - **Windows:** "Windows Hello" o mensaje similar
   - **iOS/Android:** Solicitud de huella o Face ID

5. Sigue las instrucciones del navegador para registrar tu biometría

6. Dale un nombre descriptivo al dispositivo:
   - "MacBook Touch ID"
   - "iPhone Face ID"
   - "YubiKey"

7. Haz clic en **"Register"** o **"Save"**

## Paso 4: Probar la Autenticación Passwordless

1. Cierra sesión de Keycloak

2. Ve a:
   ```
   https://<KEYCLOAK_ROUTE>/realms/master/account/
   ```

3. Ingresa tu nombre de usuario

4. En lugar de contraseña, deberías ver la opción **"Use Security Key"** o un ícono de biometría

5. Haz clic en esa opción

6. El navegador te pedirá usar tu biometría

7. Usa Touch ID/Face ID/Huella

8. ¡Deberías iniciar sesión sin contraseña!

## Estructura del Flujo Final

Después de la configuración, el flujo debería verse así:

```
browser-passwordless
├── Cookie (ALTERNATIVE)
├── Identity Provider Redirector (ALTERNATIVE)
└── browser-passwordless forms (ALTERNATIVE)
    ├── Username Password Form (REQUIRED)
    └── browser-passwordless Browser - Conditional 2FA (CONDITIONAL)
        └── Condition - credential (ALTERNATIVE)
            ├── OTP Form (ALTERNATIVE)
            ├── WebAuthn Authenticator (ALTERNATIVE)
            ├── WebAuthn Passwordless Authenticator (ALTERNATIVE) ← NUEVO
            └── Recovery Authentication Code Form (ALTERNATIVE)
```

## Solución de Problemas

### No aparece la opción "Security Key" en Account Console

**Causa:** El flujo no está configurado correctamente

**Solución:**
1. Verifica que "WebAuthn Passwordless Authenticator" esté agregado al flujo
2. Verifica que "Webauthn Register Passwordless" esté habilitado en Required Actions
3. Recarga la página del Account Console

### Error "This device doesn't support WebAuthn"

**Causa:** El navegador o dispositivo no soporta WebAuthn

**Solución:**
- Usa un navegador moderno actualizado
- Asegúrate de estar usando HTTPS
- Prueba con otro navegador

### Error "Could not update flow: It is illegal to add execution to a built in flow"

**Causa:** Estás intentando modificar el flujo "browser" original (built-in)

**Solución:**
- Usa el flujo "browser-passwordless" que es una copia editable
- El script `setup-webauthn-passwordless.sh` ya creó esta copia

### El navegador no pide biometría

**Causa:** Puede haber múltiples causas

**Solución:**
1. Verifica que tu dispositivo tiene biometría habilitada
2. En macOS, ve a System Settings → Touch ID & Password
3. En Windows, ve a Settings → Sign-in options → Windows Hello
4. Prueba con una llave de seguridad física si está disponible

### Error "NotAllowedError: The operation either timed out or was not allowed"

**Causa:** El usuario canceló la operación o el timeout expiró

**Solución:**
- Intenta de nuevo
- Aumenta el timeout en WebAuthn Policy (default 60 segundos)

## Ventajas de WebAuthn Passwordless

✅ **Seguridad mejorada:** No hay contraseñas que puedan ser robadas o filtradas
✅ **Experiencia de usuario:** Login más rápido y conveniente
✅ **Resistente a phishing:** Los credentials están vinculados al dominio
✅ **Multi-dispositivo:** Puedes registrar múltiples dispositivos (laptop, teléfono, YubiKey)
✅ **Sin instalación:** No requiere apps adicionales, es nativo del navegador

## Casos de Uso

- **Aplicaciones empresariales:** Login seguro y rápido para empleados
- **Portales de clientes:** Experiencia de usuario mejorada
- **Aplicaciones móviles:** Usar Face ID o huella en lugar de contraseña
- **Ambientes de alta seguridad:** Combinar con MFA tradicional para defensa en profundidad

## Referencias

- [Keycloak WebAuthn Documentation](https://www.keycloak.org/docs/latest/server_admin/#webauthn)
- [W3C WebAuthn Specification](https://www.w3.org/TR/webauthn/)
- [FIDO Alliance](https://fidoalliance.org/)
- [Can I use WebAuthn?](https://caniuse.com/webauthn)
