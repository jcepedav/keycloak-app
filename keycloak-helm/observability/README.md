# Observability Helm Chart

Este chart despliega el stack de observabilidad para monitorear Keycloak usando Grafana.

## Componentes

- **Grafana Instance**: Instancia de Grafana con configuración personalizada
- **Grafana Datasource**: Conexión a Prometheus/Thanos Querier
- **Grafana Dashboard**: Dashboard predefinido para métricas de Keycloak
- **ServiceMonitor**: Configuración para scraping de métricas
- **ServiceAccount y RBAC**: Permisos para acceder a Prometheus en OpenShift

## Pre-requisitos

- El chart `operators` debe estar instalado (Grafana Operator)
- Keycloak debe estar desplegado para visualizar métricas

## Instalación

```bash
helm install observability ./observability --namespace keycloak
```

## Acceso a Grafana

URL: `https://grafana-keycloak.apps.<cluster-domain>`

Credenciales por defecto:
- Usuario: `root`
- Contraseña: `secret`

## Características

### Autenticación con Prometheus

El datasource está configurado para autenticarse automáticamente con Thanos Querier en OpenShift usando un ServiceAccount token.

### Dashboard de Keycloak

Incluye métricas como:
- Uso de memoria JVM
- Solicitudes HTTP
- Sesiones activas
- Y más...

## Configuración

Ver `values.yaml` para personalizar:
- Credenciales de Grafana
- URL de Prometheus
- Configuración del ServiceAccount
