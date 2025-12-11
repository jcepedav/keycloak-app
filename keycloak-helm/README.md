# Keycloak Helm Chart

Este Helm Chart despliega Red Hat Single Sign-On (RHSSO) / Keycloak en OpenShift con PostgreSQL como base de datos.

## Prerrequisitos

- OpenShift 4.x o Kubernetes 1.19+
- Helm 3.x
- Acceso al catálogo de operadores de Red Hat (para RHSSO Operator)
- cert-manager instalado (para certificados TLS)

## Componentes Desplegados

1. **RHSSO Operator**: Operador que gestiona el ciclo de vida de Keycloak
2. **PostgreSQL StatefulSet**: Base de datos para Keycloak
3. **Keycloak**: Instancia de Red Hat Single Sign-On
4. **Certificado TLS**: Certificado gestionado por cert-manager
5. **Servicios y Secrets**: Configuración de conexión a base de datos

## Estructura del Chart

```
.
├── Chart.yaml                                    # Metadatos del chart
├── values.yaml                                   # Valores de configuración
├── templates/
│   ├── 01-rhsso-operator.yaml                   # Namespace, OperatorGroup y Subscription
│   ├── 02-rhbk-db-secret-secret.yaml            # Secret con credenciales de PostgreSQL
│   ├── 03-postgresql-statefulset.yaml           # StatefulSet y Service de PostgreSQL
│   ├── 04-keycloak-cert-manager-certificate.yaml # Certificado TLS
│   └── 05-rhbk-demo-keycloak.yaml               # Custom Resource de Keycloak
└── README.md
```

## Configuración

### values.yaml

Edita el archivo `values.yaml` para personalizar tu despliegue:

```yaml
keycloak:
  namespace: rhbk                                  # Se sobrescribe con --namespace
  clusterDomain: cluster-858h6.858h6.sandbox2642.opentlc.com  # Tu dominio de cluster
  keycloakAppName: rhbk-demo                       # Nombre de la aplicación
```

## Instalación

### 1. Login en OpenShift

```bash
oc login --token=<tu-token> --server=<tu-servidor>
```

### 2. Instalación Básica

Para instalar el chart en un namespace específico:

```bash
helm install rhbk-demo . --namespace <namespace> --create-namespace
```

Ejemplo:
```bash
helm install rhbk-demo . --namespace rhbk --create-namespace
```

### 3. Instalación con Espera

Para esperar a que todos los recursos estén listos:

```bash
helm install rhbk-demo . --namespace rhbk --create-namespace --wait --timeout 10m
```

### 4. Instalación en Modo Dry-Run

Para validar el chart sin aplicar cambios:

```bash
helm install rhbk-demo . --namespace rhbk --dry-run --debug
```

## Verificación del Despliegue

### Verificar el estado del release

```bash
helm status rhbk-demo --namespace rhbk
```

### Verificar los pods

```bash
kubectl get pods -n rhbk
```

Deberías ver:
- `keycloak-0`: Pod de Keycloak (READY 1/1)
- `postgresql-0`: Pod de PostgreSQL (READY 1/1)
- `rhsso-operator-*`: Pod del operador (READY 1/1)

### Verificar los servicios

```bash
kubectl get svc -n rhbk
```

### Obtener la URL de acceso

```bash
kubectl get route -n rhbk
```

La URL de Keycloak será algo como: `https://keycloak-<namespace>.apps.<cluster-domain>`

## Actualización

Para actualizar el chart después de modificar los valores:

```bash
helm upgrade rhbk-demo . --namespace rhbk
```

## Desinstalación

Para eliminar completamente el despliegue:

```bash
helm uninstall rhbk-demo --namespace rhbk
```

**Nota**: Esto eliminará todos los recursos excepto el namespace. Para eliminar también el namespace:

```bash
kubectl delete namespace rhbk
```

## Configuración Avanzada

### Namespace Dinámico

El chart usa `{{ .Release.Namespace }}` para configurar dinámicamente el namespace en todos los recursos. El namespace se especifica al ejecutar `helm install` con el flag `--namespace`.

### Base de Datos PostgreSQL

Por defecto, el chart despliega PostgreSQL con:
- **Usuario**: rhbk
- **Password**: rhbk
- **Base de datos**: rhbk
- **Puerto**: 5432
- **Tipo de servicio**: ClusterIP

Para cambiar las credenciales, edita `templates/02-rhbk-db-secret-secret.yaml` y `templates/03-postgresql-statefulset.yaml`.

### Certificados TLS

El chart usa cert-manager con el ClusterIssuer `zerossl-production-ec2`. Asegúrate de que:
1. cert-manager esté instalado
2. El ClusterIssuer `zerossl-production-ec2` esté configurado

Para usar un issuer diferente, edita `templates/04-keycloak-cert-manager-certificate.yaml`.

### Orden de Instalación

Los archivos en `templates/` tienen prefijos numéricos para controlar el orden de instalación:
1. Primero se instala el operador
2. Luego el secret de la base de datos
3. Después PostgreSQL
4. El certificado TLS
5. Finalmente Keycloak

## Troubleshooting

### Keycloak no puede conectarse a PostgreSQL

Verifica que el secret tenga el FQDN correcto:

```bash
kubectl get secret keycloak-db-secret -n rhbk -o jsonpath='{.data.POSTGRES_EXTERNAL_ADDRESS}' | base64 -d
```

Debe ser: `postgresql.<namespace>.svc.cluster.local`

### Verificar conectividad a PostgreSQL

```bash
kubectl run -it --rm debug-psql --image=postgres:15 --restart=Never -n rhbk --env="PGPASSWORD=rhbk" -- psql -h postgresql -U rhbk -d rhbk -c "SELECT 1"
```

### Ver logs de Keycloak

```bash
kubectl logs keycloak-0 -n rhbk --tail=50
```

### Ver logs de PostgreSQL

```bash
kubectl logs postgresql-0 -n rhbk --tail=50
```

### Verificar el estado del operador

```bash
kubectl get csv -n rhbk
```

## Credenciales por Defecto

- **Usuario admin de Keycloak**: `admin`
- **Password**: Se genera automáticamente. Para obtenerla:

```bash
kubectl get secret credential-keycloak -n rhbk -o jsonpath='{.data.ADMIN_PASSWORD}' | base64 -d
```

## Notas Importantes

1. **Operador RHSSO**: El operador crea automáticamente el servicio `keycloak-postgresql` de tipo ExternalName que apunta a tu servicio PostgreSQL.

2. **Persistencia**: El StatefulSet de PostgreSQL usa `emptyDir`, por lo que los datos se perderán si el pod se elimina. Para producción, considera usar PersistentVolumeClaims.

3. **Seguridad**: Las credenciales están en texto plano en el secret. Para producción, considera usar herramientas como Sealed Secrets o External Secrets Operator.

4. **Alta Disponibilidad**: El chart despliega una sola instancia de Keycloak (`instances: 1`). Para HA, incrementa este valor en `templates/05-rhbk-demo-keycloak.yaml`.

## Soporte

Para problemas o preguntas, consulta la documentación oficial:
- [Red Hat Single Sign-On](https://access.redhat.com/documentation/en-us/red_hat_single_sign-on)
- [Keycloak](https://www.keycloak.org/documentation)
