# Operators Helm Chart

Este chart instala los operadores necesarios para Keycloak y Grafana en OpenShift.

## Componentes

- **Grafana Operator**: Desplegado en el namespace `grafana-operator`
- **Red Hat SSO Operator (RHBK)**: Desplegado en el namespace `keycloak`

## Instalación

```bash
helm install operators ./operators --create-namespace
```

## Configuración

Ver `values.yaml` para opciones de configuración.

## Orden de Instalación

Este chart debe ser instalado **primero** antes de los otros charts (keycloak y observability).
