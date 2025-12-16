# Información relevante:

# Nuestro ultimo container
https://catalog.redhat.com/en/software/containers/rhbk/keycloak-rhel9/64f0add883a29ec473d40906#containerfile

# Migrando a Quarkus
https://www.keycloak.org/migration/migrating-to-quarkus

# Configuraciones soportadas
https://access.redhat.com/articles/7033107?extIdCarryOver=true&sc_cid=RHCTG0180000382536


# Demo

## Despliegue nuevo prereq
kubectl create namespace keycloak-dev
kubectl create rolebinding argocd-admin-dev --clusterrole=admin --serviceaccount=openshift-gitops:openshift-gitops-argocd-application-controller -n keycloak-dev

#
kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: keycloak-prod
  namespace: openshift-gitops
spec:
  project: default
  source:
    repoURL: git@github-rh:jcepedav/keycloak-app.git
    targetRevision: main
    path: keycloak-helm
    helm:
      valueFiles:
        - values.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: keycloak-prod
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - ServerSideApply=true
EOF

## Prerequisitos:
export NAMESPACE=keycloak

oc create project $NAMESPACE

kubectl create rolebinding argocd-admin -n $NAMESPACE$ --clusterrole=admin --serviceaccount=openshift-gitops:openshift-gitops-argocd-application-controller

## Metricas

### Sesiones activas
keycloak_sessions

### Requests HTTP
http_server_requests_seconds_count

### Uso de JVM
jvm_memory_used_bytes

### Latencia de requests
http_server_requests_seconds_sum


## Algunas acciones

### instalar con Helm
helm install keycloak . --namespace keycloak --wait --timeout 10m

### instalar con GitOps
kubectl apply -f argocd-application.yaml

#### Forzar el refresco del despligue:
kubectl patch application keycloak -n openshift-gitops --type merge -p '{"operation":null}'

