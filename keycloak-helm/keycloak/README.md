# Keycloak Helm Chart

Este chart despliega Red Hat Build of Keycloak (RHBK) con PostgreSQL como base de datos.

## Componentes

- **PostgreSQL StatefulSet**: Base de datos para Keycloak
- **Keycloak Custom Resource**: Instancia de RHBK
- **Secrets**: Credenciales de base de datos
- **Certificate**: Certificado TLS para Keycloak

## Pre-requisitos

- El chart `operators` debe estar instalado primero
- Cert-manager debe estar disponible en el cluster

## Instalación

```bash
helm install keycloak ./keycloak --namespace keycloak --create-namespace
```

## Acceso

Una vez desplegado, Keycloak estará disponible en:
```
https://rhbk-demo-keycloak.apps.<cluster-domain>
```

## Configuración

Ver `values.yaml` para personalizar:
- Dominio del cluster
- Credenciales de base de datos
- Número de instancias
- Nombre de la aplicación
