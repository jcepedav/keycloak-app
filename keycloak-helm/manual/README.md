# Configuración Manual de Keycloak

Esta carpeta contiene la documentación de los pasos que deben ejecutarse manualmente porque no pueden ser automatizados completamente con GitOps.

## Documentos disponibles

1. **[01-google-identity-provider.md](01-google-identity-provider.md)** - Configuración de Google como Identity Provider
2. **[02-webauthn-passwordless.md](02-webauthn-passwordless.md)** - Configuración de autenticación biométrica sin contraseña
3. **[03-argocd-permissions.md](03-argocd-permissions.md)** - Permisos necesarios para ArgoCD

## Orden de ejecución

Los pasos manuales deben ejecutarse en el siguiente orden:

1. Primero: Permisos de ArgoCD (03-argocd-permissions.md)
2. Después del despliegue: Google Identity Provider (01-google-identity-provider.md)
3. Después del despliegue: WebAuthn Passwordless (02-webauthn-passwordless.md)

## Prerequisitos

- Cluster OpenShift/Kubernetes funcionando
- kubectl configurado y conectado al cluster
- Acceso a Google Cloud Console (para Google IDP)
- Navegador moderno con soporte para WebAuthn
