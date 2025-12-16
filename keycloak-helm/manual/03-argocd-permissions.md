# Configuración de Permisos para ArgoCD

## Descripción

Este documento describe cómo otorgar los permisos necesarios al controlador de ArgoCD para que pueda gestionar recursos en el namespace de Keycloak.

## Problema

Por defecto, el ArgoCD Application Controller solo tiene permisos para gestionar recursos en ciertos namespaces. Si intentas desplegar la aplicación de Keycloak sin estos permisos, verás errores como:

```
servicemonitors.monitoring.coreos.com "rhbk-demo-metrics" is forbidden: 
User "system:serviceaccount:openshift-gitops:openshift-gitops-argocd-application-controller" 
cannot patch resource "servicemonitors" in API group "monitoring.coreos.com" 
in the namespace "keycloak"
```

## Prerequisito

- OpenShift GitOps/ArgoCD instalado
- Acceso con permisos de cluster-admin

## Solución: Crear RoleBinding

### Opción 1: Usando kubectl (Recomendada)

Ejecuta el siguiente comando para otorgar permisos de administrador al ArgoCD Application Controller en el namespace de Keycloak:

```bash
kubectl create rolebinding argocd-admin \
  -n keycloak \
  --clusterrole=admin \
  --serviceaccount=openshift-gitops:openshift-gitops-argocd-application-controller
```

**Salida esperada:**
```
rolebinding.rbac.authorization.k8s.io/argocd-admin created
```

### Opción 2: Usando un archivo YAML

Si prefieres gestionar esto como código, crea un archivo `argocd-rolebinding.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: argocd-admin
  namespace: keycloak
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: admin
subjects:
- kind: ServiceAccount
  name: openshift-gitops-argocd-application-controller
  namespace: openshift-gitops
```

Aplica el archivo:

```bash
kubectl apply -f argocd-rolebinding.yaml
```

### Opción 3: Para múltiples namespaces

Si vas a desplegar aplicaciones en múltiples namespaces, puedes crear RoleBindings en cada uno:

```bash
for ns in keycloak grafana-operator other-namespace; do
  kubectl create rolebinding argocd-admin \
    -n $ns \
    --clusterrole=admin \
    --serviceaccount=openshift-gitops:openshift-gitops-argocd-application-controller \
    --dry-run=client -o yaml | kubectl apply -f -
done
```

## Verificación

### Verificar que el RoleBinding fue creado

```bash
kubectl get rolebinding argocd-admin -n keycloak -o yaml
```

**Salida esperada:**
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: argocd-admin
  namespace: keycloak
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: admin
subjects:
- kind: ServiceAccount
  name: openshift-gitops-argocd-application-controller
  namespace: openshift-gitops
```

### Verificar permisos del ServiceAccount

```bash
kubectl auth can-i create servicemonitor \
  --as=system:serviceaccount:openshift-gitops:openshift-gitops-argocd-application-controller \
  -n keycloak
```

**Salida esperada:** `yes`

### Probar sincronización de ArgoCD

Después de crear el RoleBinding, fuerza una sincronización de la aplicación:

```bash
kubectl patch application keycloak \
  -n openshift-gitops \
  --type merge \
  -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}'
```

Verifica el estado:

```bash
kubectl get application keycloak -n openshift-gitops
```

## Permisos Mínimos (Alternativa más Restrictiva)

Si no quieres otorgar el ClusterRole `admin`, puedes crear un Role personalizado con solo los permisos necesarios:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: argocd-keycloak-manager
  namespace: keycloak
rules:
# Core resources
- apiGroups: [""]
  resources: ["secrets", "services", "configmaps", "persistentvolumeclaims"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]

# Apps
- apiGroups: ["apps"]
  resources: ["deployments", "statefulsets", "replicasets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]

# Monitoring
- apiGroups: ["monitoring.coreos.com"]
  resources: ["servicemonitors"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]

# Operators
- apiGroups: ["operators.coreos.com"]
  resources: ["subscriptions", "operatorgroups", "clusterserviceversions"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]

# Keycloak CRDs
- apiGroups: ["k8s.keycloak.org"]
  resources: ["keycloaks", "keycloakrealmimports"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]

# Grafana CRDs
- apiGroups: ["grafana.integreatly.org"]
  resources: ["grafanas", "grafanadatasources", "grafanadashboards"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]

# Routes (OpenShift)
- apiGroups: ["route.openshift.io"]
  resources: ["routes"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]

# Cert-manager
- apiGroups: ["cert-manager.io"]
  resources: ["certificates"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]

# Batch (Jobs)
- apiGroups: ["batch"]
  resources: ["jobs"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: argocd-keycloak-manager
  namespace: keycloak
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: argocd-keycloak-manager
subjects:
- kind: ServiceAccount
  name: openshift-gitops-argocd-application-controller
  namespace: openshift-gitops
```

Aplica este archivo:

```bash
kubectl apply -f argocd-keycloak-role.yaml
```

## Cuándo Ejecutar Este Paso

Este paso debe ejecutarse **ANTES** de desplegar la aplicación de Keycloak con ArgoCD:

1. ✅ Instalar OpenShift GitOps
2. ✅ **Crear RoleBinding (ESTE PASO)**
3. ✅ Crear namespace keycloak (si no existe)
4. ✅ Aplicar ArgoCD Application

## Namespaces Requeridos

Para este proyecto, necesitas permisos en dos namespaces:

| Namespace | Propósito | RoleBinding Necesario |
|-----------|-----------|----------------------|
| `keycloak` | Keycloak, PostgreSQL, Cert-manager resources | ✅ Sí |
| `grafana-operator` | Grafana Operator | ✅ Sí |

Comandos:

```bash
# Keycloak namespace
kubectl create rolebinding argocd-admin \
  -n keycloak \
  --clusterrole=admin \
  --serviceaccount=openshift-gitops:openshift-gitops-argocd-application-controller

# Grafana Operator namespace
kubectl create rolebinding argocd-admin \
  -n grafana-operator \
  --clusterrole=admin \
  --serviceaccount=openshift-gitops:openshift-gitops-argocd-application-controller
```

## Solución de Problemas

### Error: "rolebinding.rbac.authorization.k8s.io already exists"

**Causa:** El RoleBinding ya fue creado anteriormente

**Solución:** No necesitas hacer nada, o elimínalo y recréalo:

```bash
kubectl delete rolebinding argocd-admin -n keycloak
kubectl create rolebinding argocd-admin -n keycloak \
  --clusterrole=admin \
  --serviceaccount=openshift-gitops:openshift-gitops-argocd-application-controller
```

### ArgoCD sigue mostrando errores de permisos

**Causa:** El RoleBinding puede tardar unos segundos en propagarse

**Solución:**
1. Espera 10-20 segundos
2. Fuerza una sincronización:
   ```bash
   kubectl patch application keycloak -n openshift-gitops \
     --type merge \
     -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}'
   ```

### Error al crear recursos en un namespace diferente

**Causa:** El RoleBinding solo otorga permisos en un namespace específico

**Solución:** Crea RoleBindings en todos los namespaces necesarios (ver sección "Opción 3")

## Consideraciones de Seguridad

⚠️ **Advertencia:** El ClusterRole `admin` otorga permisos amplios dentro del namespace. En producción, considera:

1. Usar permisos mínimos (ver sección "Permisos Mínimos")
2. Auditar regularmente los permisos otorgados
3. Usar Policy as Code (Open Policy Agent, Kyverno) para controlar qué puede desplegar ArgoCD
4. Implementar AppProjects en ArgoCD con restricciones específicas

## Referencias

- [ArgoCD RBAC](https://argo-cd.readthedocs.io/en/stable/operator-manual/rbac/)
- [Kubernetes RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [OpenShift GitOps Documentation](https://docs.openshift.com/gitops/latest/understanding_openshift_gitops/about-redhat-openshift-gitops.html)
