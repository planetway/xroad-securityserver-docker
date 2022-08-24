# Helm examples

## Local development

### Database

```
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install postgresql \
  --set auth.postgresPassword=secret bitnami/postgresql
```

### Persistent volume

```
kubectl apply -f xroad-securityserver-pvc.yaml
```

### Security server

```
helm repo add xroad-securityserver https://planetway.github.io/xroad-securityserver-docker
helm install --values values.yaml xroad-securityserver xroad-securityserver/xroad-securityserver
```

### Cleanup

```
helm uninstall xroad-securityserver
kubectl delete -f xroad-securityserver-pvc.yaml
helm uninstall postgresql
kubectl delete pvc data-postgresql-0
```

# Init container for secondary

Has been configured in a way that it check health of primary. So primary must be available for secondary to start.
