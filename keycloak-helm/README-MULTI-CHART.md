# Keycloak Deployment - Multi-Chart Structure

Este repositorio contiene la infraestructura como código para desplegar Red Hat Build of Keycloak (RHBK) en OpenShift con observabilidad completa usando Grafana.

## Estructura del Proyecto

El proyecto está organizado en **3 Helm Charts independientes**:

```
keycloak-helm/
├── operators/          # Chart 1: Instalación de operadores
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── README.md
│   └── templates/
│       ├── 00-grafana-operator.yaml
│       └── 01-rhsso-operator.yaml
│
├── keycloak/           # Chart 2: Despliegue de Keycloak
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── README.md
│   └── templates/
│       ├── 02-rhbk-db-secret-secret.yaml
│       ├── 03-postgresql-statefulset.yaml
│       ├── 04-keycloak-cert-manager-certificate.yaml
│       └── 05-rhbk-demo-keycloak.yaml
│
└── observability/      # Chart 3: Stack de observabilidad
    ├── Chart.yaml
    ├── values.yaml
    ├── README.md
    └── templates/
        ├── 06-servicemonitor.yaml
        ├── 07-grafana-dashboard.yaml
        ├── 08-grafana-instance.yaml
        ├── 08a-grafana-admin-credentials.yaml
        ├── 09-grafana-datasource.yaml
        ├── 09a-grafana-serviceaccount-rbac.yaml
        └── 10-grafana-route.yaml
```

## Orden de Instalación

### 1. Operadores (Primero)
```bash
helm install operators ./operators --create-namespace
```

Este chart instala:
- Grafana Operator (namespace: grafana-operator)
- Red Hat SSO Operator / RHBK Operator (namespace: keycloak)

### 2. Keycloak (Segundo)
```bash
helm install keycloak ./keycloak --namespace keycloak --create-namespace
```

Este chart despliega:
- PostgreSQL StatefulSet
- Secretos de base de datos
- Certificado TLS
- Instancia de Keycloak

### 3. Observability (Tercero)
```bash
helm install observability ./observability --namespace keycloak
```

Este chart despliega:
- Instancia de Grafana
- Datasource de Prometheus con autenticación
- Dashboard de Keycloak
- ServiceMonitor para métricas
- ServiceAccount y permisos RBAC

## Despliegue con ArgoCD

El archivo `argocd-applications.yaml` contiene las definiciones de las 3 aplicaciones de ArgoCD:

```bash
oc apply -f argocd-applications.yaml
```

Esto creará:
- `keycloak-operators`: Aplicación para operadores
- `keycloak-app`: Aplicación para Keycloak
- `keycloak-observability`: Aplicación para observabilidad

Las aplicaciones están configuradas con **sync automático** y las dependencias están documentadas.

## URLs de Acceso

Después del despliegue completo:

- **Keycloak**: `https://rhbk-demo-keycloak.apps.<cluster-domain>`
- **Grafana**: `https://grafana-keycloak.apps.<cluster-domain>`
  - Usuario: `root`
  - Contraseña: `secret`

## Ventajas de la Estructura Multi-Chart

✅ **Separación de concerns**: Cada componente tiene su propio ciclo de vida  
✅ **Reutilización**: Los charts pueden ser usados independientemente  
✅ **Mantenimiento**: Más fácil actualizar componentes específicos  
✅ **Flexibilidad**: Permite instalar solo lo necesario  
✅ **Escalabilidad**: Facilita agregar nuevos componentes  

## Configuración

Cada chart tiene su propio archivo `values.yaml` que puede ser personalizado:

- **operators/values.yaml**: Habilitar/deshabilitar operadores
- **keycloak/values.yaml**: Configuración de Keycloak y PostgreSQL
- **observability/values.yaml**: Configuración de Grafana y datasources

## Documentación Adicional

- [Operators README](./operators/README.md)
- [Keycloak README](./keycloak/README.md)
- [Observability README](./observability/README.md)
- [Manual de configuración](./manual/)
- [Scripts de automatización](./scripts/)

## Solución de Problemas

### Verificar estado de las aplicaciones
```bash
oc get application -n openshift-gitops
```

### Ver logs de sincronización
```bash
oc logs -n openshift-gitops deployment/openshift-gitops-application-controller
```

### Verificar operadores
```bash
oc get subscription -n grafana-operator
oc get subscription -n keycloak
```

### Verificar Keycloak
```bash
oc get keycloak -n keycloak
oc get pods -n keycloak
```

### Verificar Grafana
```bash
oc get grafana,grafanadatasource,grafanadashboard -n keycloak
```

## Contribución

Para contribuir a este proyecto:

1. Crea una rama desde `main`
2. Realiza tus cambios
3. Prueba localmente con `helm template`
4. Crea un Pull Request

## Licencia

[Tu licencia aquí]
