# Conneqt Security Server Docker Image

Conneqt Security server Docker image includes the Conneqt Security server software. The version of the Conneqt Security server is the same as the Docker image tag.
`conneqt/xroad-securityserver:6.25.0-1` has the Conneqt Security server version 6.25.0-1, installed on Ubuntu 18.04 .

## Usage

Conneqt Security server Docker container requires an external PostgreSQL database.

Use following docker-compose file as a minimal example.

```
services:
  ss01:
    image: conneqt/xroad-securityserver:6.25.0-1
    depends_on:
      - postgres
    environment:
      - PX_INSTANCE=JP-TEST
      - PX_MEMBER_CLASS=COM
      - PX_MEMBER_CODE=0170121212121
      - PX_SS_CODE=ss01
      - PX_SS_PUBLIC_ENDPOINT=ss01.localdomain
      - PX_TSA_NAME=TEST of Planetway Timestamping Authority 2020
      - PX_TSA_URL=https://tsa.test.planetcross.net
      - PX_TOKEN_PIN=...
      - PX_ADMINUI_USER=admin
      - PX_ADMINUI_PASSWORD=...
      - POSTGRES_HOST=postgres
      - POSTGRES_PORT=5432
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=password
      - PX_SERVERCONF_PASSWORD=...
      - PX_MESSAGELOG_PASSWORD=...
      - PX_OPMONITOR_PASSWORD=...
      - PX_POPULATE_DATABASE=true
      - PX_ENROLL=true
    ports:
      - "2080:2080"
      - "4000:4000"
      - "5500:5500"
      - "5577:5577"
      - "5588:5588"
      - "8000:80"
      - "8443:443"
    volumes:
      # .p12 files and keyconf.xml
      - "px-ss-signer:/etc/xroad/signer"
      # mlog.zip files are stored here, and ./backup contains backups
      - "px-ss-xroad:/var/lib/xroad"

  postgres:
    image: postgres:10
    environment:
      POSTGRES_PASSWORD: password
    ports:
      - "5432:5432"
    volumes:
      - "px-ss-postgres:/var/lib/postgresql/data"

volumes:
  px-ss-postgres:
  px-ss-signer:
  px-ss-xroad:
```

To start the Security server, run following command.

```
docker-compose up
```

Open the Security server admin UI on `https://localhost:4000/` (change localhost to docker server's host),
and login with the credentials set as `PX_ADMINUI_USER` and `PX_ADMINUI_PASSWORD` environment variables.  
In Chrome, you might see the "Your connection is not private" page. Click the "Advanced" button and "Proceed to localhost (unsafe)".

We recommend to give 4GB of RAM for a Security server Docker container running with default configuration.

## Configuration

### Environment variables

`PX_INSTANCE`: The X-Road instance to join. `JP` or `JP-TEST` values are accepted. Required. The appropriate configuration anchor is placed to `/etc/xroad/configuration-anchor.xml` depending on this value.

`PX_MEMBER_CLASS`: The X-Road member class of the Security server. `COM` or `ORG` values are accepted. Required.

`PX_MEMBER_CODE`: The X-Road member code of the Security server. Required. Use `0170121212121` for testing purposes. This is a reserved member code with a name "Docker Demo Company" and is shared between all the Docker image users. Please note that Planetway might periodically delete Security server codes that are registered under this member.

`PX_SS_CODE`: The X-Road Security server code. Required. eg: `ss01`.

`PX_SS_PUBLIC_ENDPOINT`: Public endpoint of X-Road Security server, used when registering security server with central server. Should be a real domain or IP.

`PX_TSA_NAME`, `PX_TSA_URL`: The Timestamping authority (TSA) and URL to use. Required. If `JP-TEST` is set as `PX_INSTANCE`, you can use `TEST of Planetway Timestamping Authority 2020` as `PX_TSA_NAME`, and `https://tsa.test.planetcross.net` as `PX_TSA_URL`.

`PX_TOKEN_PIN`: The PIN for the softtoken. Optional. If set, autologin is enabled. `PX_TOKEN_PIN` needs to be set when `PX_ENROLL` is true.

`PX_ADMINUI_USER`, `PX_ADMINUI_PASSWORD`: The Security server admin UI user name and password. Optional. If `PX_ADMINUI_USER` and `PX_ADMINUI_PASSWORD` are both set, a unix user is be created with the user name and password. This user will be a member of `xroad-security-officer`, `xroad-registration-officer`, `xroad-service-administrator`, `xroad-system-administrator` and `xroad-securityserver-observer` unix groups.

`POSTGRES_HOST`, `POSTGRES_PORT`, `POSTGRES_USER`, `POSTGRES_PASSWORD`: PostgreSQL host name, port, admin user name and password. Required for database initialization.

`PX_SERVERCONF_ADMIN_USER`, `PX_SERVERCONF_ADMIN_PASSWORD`, `PX_MESSAGELOG_ADMIN_USER`, `PX_MESSAGELOG_ADMIN_PASSWORD`, `PX_OPMONITOR_ADMIN_USER`, `PX_OPMONITOR_ADMIN_PASSWORD`: The PostgreSQL user name and password for the serverconf, messagelog and opmonitor databases, respectively. These are the user name and password of the PostgreSQL user that runs Liquibase to initialize and upgrade the database schema. Optional, and defaults to `POSTGRES_USER` and `POSTGRES_PASSWORD`.

`PX_SERVERCONF_USER`, `PX_MESSAGELOG_USER`, `PX_OPMONITOR_USER`: serverconf, messagelog and opmonitor user name. Optional, and defaults to `serverconf`, `messagelog` and `opmonitor` respectively.

`PX_SERVERCONF_PASSWORD`, `PX_MESSAGELOG_PASSWORD`, `PX_OPMONITOR_PASSWORD`: serverconf, messagelog and opmonitor user password. Required.

`PX_CHECKDB_USER`, `PX_CHECKDB_PASSWORD`: The PostgreSQL user name and password to check if the databases exist. Set these to `PX_SERVERCONF_USER` and `PX_SERVERCONF_PASSWORD` when you know the database is already set up, and you do not want to put the PostgreSQL admin user name and password in the environment variables. Optional, and defaults to `POSTGRES_USER` and `POSTGRES_PASSWORD`.

`PX_POPULATE_DATABASE`: A flag to enable the feature to populate the database to initialize the Security server. Optional, and defaults to false.

`PX_ENROLL`: A flag to enable the feature to automatically request authentication and signing certificates from the CA. See [Automatic Enrolling](#automatic-enrolling) section for details.

`PX_ENROLLMENT_PASSWORD`:

`PX_PROXY_XMS`, `PX_PROXY_XMX`, `PX_PROXY_METASPACE`:

`PX_NODE_TYPE`: When setting up a Security server under a load balancer (ref: [X-Road: External Load Balancer Installation Guide](https://github.com/nordic-institute/X-Road/blob/develop/doc/Manuals/LoadBalancing/ig-xlb_x-road_external_load_balancer_installation_guide.md)), Security server can be configured to be the "primary" node type or the "secondary" node type. A single primary node runs the admin UI where an administrator can modify the Security server configuration. Multiple secondary nodes do not modify the configuration. When set to "secondary", the Docker container do not run the xroad-proxy-ui-api process and do not archive message logs. Optional, and defaults to "primary".

### PX_INI_* and PX_CONF_* environment variables

In [X-Road Security Server User Guide](https://github.com/nordic-institute/X-Road/blob/develop/doc/Manuals/ug-ss_x-road_6_security_server_user_guide.md) you are often guided to edit two files to customize Security server's behavior. When using Docker, instead of populating a file and mounting it, we provide a feature to set environment variables to populate the configuration file on startup.

Environment variables that start with `PX_INI_` will be used to fill in /etc/xroad/conf.d/local.ini, and environment variables that start with `PX_CONF_` will be used to fill in /etc/xroad/services/local.conf .

The environment variables that match this pattern,

`PX_INI_{SECTION NAME}_{PARAMETER NAME}={VALUE}`

becomes

```
[SECTION NAME]
parameter-name=VALUE
```

for example,

`PX_INI_MESSAGELOG_ARCHIVE_PATH=/var/lib/xroad`

becomes

```
[message-log]
archive-path="/var/lib/xroad"
```

See tests/test.pl for more examples.

#### Check how environment variables are written into config files

```
docker run -it --rm -e PX_INI_MESSAGELOG_A=128 -e PX_CONF_PROXY_PARAMS=' -Xms1000m' conneqt/xroad-securityserver cat /etc/xroad/services/local.conf /etc/xroad/conf.d/local.ini
```

### Volumes vs bind mounts

Docker provides volumes and bind mount mechanisms to persist the data inside the container on the host.

Because of permission issues, we recommend to use Docker volumes, especially when mounting `/etc/xroad/signer` directory.

## Automatic Enrolling

In `JP-TEST` X-Road instance, we provide features to automate some onboarding processes.

1. Generate authentication and signing key
1. Create CSR for authentication and signing certificates
1. Send CSR to JP-TEST CA to retrieve authentication and signing ceritificates
1. Import authentication and signing certificates
1. Security server and subsystem registration is automatically approved.

## Logging

The Docker container logs to stdout as follows by default. These are logs captured when running the Security server with `docker-compose up`.

```
ss01_1      | {"timestamp":"2020-12-21T15:31:46.955Z","level":"INFO","thread":"https-jsse-nio-4000-exec-9","mdc":{"traceId":"e5df1fec570fabea","spanId":"e5df1fec570fabea","spanExportable":"false","X-Span-Export":"false","X-B3-SpanId":"e5df1fec570fabea","X-B3-TraceId":"e5df1fec570fabea"},"logger":"ee.ria.xroad.common.AuditLogger","message":"{\"event\":\"Log in user\",\"user\":\"admin\",\"url\":\"/login\",\"data\":{}}","context":"X-Road Proxy Admin REST API"}
ss01_1      | {"timestamp":"2020-12-21T15:32:00.002Z","level":"INFO","thread":"Proxy-akka.actor.default-dispatcher-5","logger":"ee.ria.xroad.proxy.messagelog.LogCleaner","message":"Removing archived records from database...","context":"X-Road Proxy"}
ss01_1      | {"timestamp":"2020-12-21T15:32:00.006Z","level":"INFO","thread":"Proxy-akka.actor.default-dispatcher-5","logger":"ee.ria.xroad.proxy.messagelog.LogCleaner","message":"No archived records to remove from database","context":"X-Road Proxy"}
```

Use Docker volumes or bind mount mechanisms to overwrite the logback configuration to modify the logging levels.
Configure the Docker logging driver to forward logs to where you wish.

## Kubernetes

We have included kubernetes manifests (`k8-charts/` directory) for local development environment. They can be taken as a base for production deployment.

Some important notes regarding kubernetes deployment:
- Deployment include `primary` (no replicas) and `secondary` pods (n replicas).
- The job of `primary` pod is to expose admin ui api for configuration and archive records in messagelog database.
- The job of `secondary` pods is to expose security server as a service to consumers running inside kubernetes cluster.

### Local development Environment

You should have docker desktop available/running and context switched to it.

Run `vagrant up` to apply manifests, use `kubectl` to check deployment/pod/service status.

## Production use

For production use, please contact [Technical support](#technical-support)

## Technical Support

Contact us for technical support.

* Using this Form https://planetway.com/contact/
* In Conneqt Community https://join.slack.com/t/conneqt-community/shared_invite/zt-ng88s0jn-UiXAIJz~XBxIn1xaF8pFNw

## License, Terms of Use

By downloading the Docker image, you represent that you have read, understood and agreed to be bound by the [Conneqt License Agreement](https://planetway.com/legal/PX_License_Agreement.pdf).

The files in this repository are licensed under [MIT License](LICENSE).
