# helm

It is possible to deploy security server with helm.

## Database

```
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install postgresql \
  --set auth.postgresPassword=secret bitnami/postgresql
```

## Persistent volume

```
kubectl apply -f xroad-securityserver-pvc.yaml
```

## Deploy security server as single instance

```
helm install --values values-single.yaml xroad-securityserver ../../charts/xroad-securityserver
```

## Deploy security server as HA

```
helm install --values values-ha.yaml xroad-securityserver ../../charts/xroad-securityserver
```

## Cleanup

```
helm uninstall xroad-securityserver
kubectl delete -f xroad-securityserver-pvc.yaml
helm uninstall postgresql
kubectl delete pvc data-postgresql-0
```

# Init container for secondary

Has been configured in a way that it check health of primary. So primary must be available for secondary to start.
