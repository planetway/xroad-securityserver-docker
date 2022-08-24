# xroad-securityserver

## Usage

[Helm](https://helm.sh) must be installed to use the charts.  Please refer to
Helm's [documentation](https://helm.sh/docs) to get started.

Once Helm has been set up correctly, add the repo as follows:

  helm repo add <alias> https://planetway.github.io/xroad-security-server

If you had already added this repo earlier, run `helm repo update` to retrieve
the latest versions of the packages.  You can then run `helm search repo
<alias>` to see the charts.

To install the <chart-name> chart:

    helm install my-<chart-name> <alias>/xroad-security-server

To uninstall the chart:

    helm delete my-<chart-name>

## What this chart does

xroad-securityserver helm chart deploys two sets of pods:

`<helm release name>-primary` - single pod which runs security server web based user interface, is responsible for automatic enrollment in case of `JP-TEST` instance, archives message logs etc.

`<helm release name>-secondary` - multiple pods (replica count can be configured with `xroadSecurityServer.secondaryReplicaCount`), responsible for handling incoming and outgoind traffic.

It creates following services:

`<helm release name>-primary` - service type is `ClusterIP`, exposes security server web based user interface, targets primary pod.

`<helm release name>-internal` - service type is `ClusterIP`, exposes HTTP and HTTPS interfaces for clients to consume xroad services, targets secondary pods.

`<helm release name>-public` - service type is `LoadBalancer`, exposes 5500/tcp (message exchange between security servers) and 5577/tcp (querying of OCSP responses between security servers), targets secondary pods. This service should be publicly available.

For data persistenace operators should configure:

- external database (for example Amazon RDS).
- shared storage (for example Amazon EFS).

Shared storage for pods should be configured with `xroadSecurityServer.extraVolumeMounts`, `xroadSecurityServer.extraVolumes` to `/etc/xroad/signer` (used by `xroad-signer` to store keys and token configuration) and `/var/lib/xroad` (used for messagelog archiving, backups etc).

Please see [examples](https://github.com/planetway/xroad-securityserver-docker/tree/master/examples/helm) for further details.
