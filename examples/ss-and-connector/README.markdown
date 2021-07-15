Security server and Connector in one docker-compose.yml example
===============================================================

## Overview

This directory contains an example local development environment,
where you can launch a Security server and Connector containers with a single command.

```
% docker-compose up
```

## Invoke a service directly against Connector

Connector proxy is listening on port 8085 on the Docker host.
You can invoke the service on Connector proxy directly as follows.

```
% curl -v "http://localhost:8085/api/service/selectExample" \
       -H "Content-Type: application/json" \
       -d '{"id":1}'
* Connected to localhost (::1) port 8085 (#0)
> POST /api/service/selectExample HTTP/1.1
> Host: localhost:8085
> User-Agent: curl/7.64.1
> Accept: */*
> Content-Type: application/json
> Content-Length: 8
>
< HTTP/1.1 200
< Content-Type: application/json;charset=UTF-8
< Transfer-Encoding: chunked
< Date: Thu, 15 Jul 2021 00:40:08 GMT
<
{"rows":[{"id":1,"col_1":"col_1_row_1","col_2":"col_2_row_1"}]}
```

## Create subsystems and services, and give access

Open `https://localhost:4000/` and login with the credentials in `PX_ADMINUI_USER` and `PX_ADMINUI_PASSWORD` environment variables.

![Login](images/login.png)

Click the "ADD SUBSYSTEM" button and create "democlient" and "demoprovider" subsystems.

![Create subsystems](images/subsystem.png)

Set the connection type of the "democlient" subsystem to "HTTP". This is to simplify the demo experience and not recommended for production use.

![Connection type](images/connectiontype.png)

Create a service in the "demoprovider" subsystem, named "example" with `http://proxy:8085/api/openapi.json`.  
Docker network resolves the `proxy` hostname and forwards the traffic to the proxy Docker container.

![Service](images/service.png)

Also set the Service URL to `http://proxy:8085/api/service`.

![Service URL](images/serviceurl.png)

Click the "ADD SUBJECTS" button and give access to "democlient".

![Add subject](images/addsubject.png)

## Invoke a service through X-Road

After creating subsystems and service entries, giving access to the service to your subsystem,
you can invoke the service that is running on Connector,
through the Security server, as follows.

```
% curl -v "http://localhost:8000/r1/JP-TEST/COM/0170121212121/demoprovider/example/selectExample" \
       -H "X-Road-Client: JP-TEST/COM/0170121212121/democlient" \
       -H "Content-Type: application/json" \
       -d '{"id":1}'
* Connected to localhost (::1) port 8000 (#0)
> POST /r1/JP-TEST/COM/0170121212121/demoprovider/example/selectExample HTTP/1.1
> Host: localhost:8000
> User-Agent: curl/7.64.1
> Accept: */*
> X-Road-Client: JP-TEST/COM/0170121212121/democlient
> Content-Type: application/json
> Content-Length: 8
>
< HTTP/1.1 200
< Content-Type: application/json;charset=utf-8
< Date: Thu, 15 Jul 2021 00:37:55 GMT
< x-road-id: JP-TEST-9059ec99-420f-43bb-b454-84cca69fa8dc
< x-road-client: JP-TEST/COM/0170121212121/democlient
< x-road-service: JP-TEST/COM/0170121212121/demoprovider/example
< x-road-request-id: b13059ba-505f-4a29-a621-3d4c088d8e78
< x-road-request-hash: BVododmQwRsRisJpu3tTVjI4d+71h2UezpPGt3e4EeT3qq7/RSd3+tiH6IVC50vCYGqm4EwrmNmOuLLepaM07g==
< Content-Length: 63
<
{"rows":[{"id":1,"col_1":"col_1_row_1","col_2":"col_2_row_1"}]}
```

Note the difference between this curl script and the previous one, in the path and the header.  
Security server is a thin proxy, both from the client's point of view and from the service provider's point of view.
