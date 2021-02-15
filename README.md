# RhodeCode Cluster

RhodeCode Cluster is a multi-node highly-scalable setup to run RhodeCode and
all its additional components in single environment using Docker.

Using a docker-compose this setup creates following services for RhodeCode:

- Nginx HTTP Server for load balancing and reverse proxy
- RhodeCode HTTP
- VCSServer for GIT/SVN/HG support
- SSH Server for cloning over SSH
- SVN webserver for HTTP support over SVN
- Celery workers for asynchronous tasks
- Celery beat for automation tasks
- Redis Database for caching
- Postgres database for persistent storage
- Channelstream websocket server for live components


## Pre requisites

Visit docker site and install docker (min version 20.10) and docker compose:

- https://docs.docker.com/engine/install/ 
- https://docs.docker.com/compose/install/


# Installation steps
Follow these steps to build and run the RhodeCode Cluster via Docker-compose.

## Download installer binaries

First start by fetching required installer binaries. This is required to create both
simple build and full compose setup.
Please check the `.env` file to adjust the version if needed.

`cd .boostrap/; ./download-artifacts.sh; cd ../`

This will download required files and put them into the `.cache` directory. 
This directory should look similar to that after downloads have finish:

```shell
drwxr-xr-x   8 rcdev  rcdev   256B Feb  8 13:35 .
drwxr-xr-x  14 rcdev  rcdev   448B Feb  8 10:40 ..
-rw-r--r--   1 rcdev  rcdev     0B Feb  8 20:44 .dirkeep
-rwxr-xr-x   1 rcdev  rcdev   241M Feb  8 13:35 RhodeCode-installer-linux-build20210208_0800
-rw-r--r--   1 rcdev  rcdev   156M Feb  8 13:35 RhodeCodeCommunity-4.24.1+x86_64-linux_build20210208_0800.tar.bz2
-rw-r--r--   1 rcdev  rcdev   171M Feb  8 13:35 RhodeCodeEnterprise-4.24.1+x86_64-linux_build20210208_0800.tar.bz2
-rw-r--r--   1 rcdev  rcdev   145M Feb  8 13:35 RhodeCodeVCSServer-4.24.1+x86_64-linux_build20210208_0800.tar.bz2
-rw-r--r--   1 rcdev  rcdev   109M Feb  8 13:35 locale-archive
```

## Set License for EE version

This setup would use a provided license from a file 
`config/compose/rhodecode_enterprise.license` If you have a full license, or a trial one
please save the license data inside this file, so it will be applied at creation.
This file can also be empty and license can be applied via a WEB interface.


## Run Docker compose build:

To create a full stack we need to run the database container, so it's ready to
build the docker image.

1) start with running the required database for the build stage in the background.
   
    ```shell
    docker-compose up --detach database
    ```
   
    This will start our postgres database, and expose it to the network. 
    We can now run the full installation. Database needs to be running for the next build command.
    
    ```shell
    docker-compose build rhodecode
    docker-compose build
    ```

Once we build the rhodecode app, we can run the whole stack using `docker-compose up`

```shell
docker-compose up
```

You can access Running RhodeCode under via Nginx under:
http://localhost:8888


In case for bigger setups docker-compose can scale more rhodecode/vcsserver workers:

```shell
docker-compose up --scale vcsserver=3 rhodecode=3
```

## Data structure

There are 4 volumes defined:

- `/var/log/rhodecode` # all logs from RhodeCode are saved in this volume
- `/etc/rhodecode/conf` # storing configuration files for rhodecode, vcsserver and supervisord, and some cache data
- `/var/opt/rhodecode_repo_store` # main repository storage where repositories would be stored
- `/var/opt/rhodecode_data` # data dir for rhodecode cache/lock files, or user sessions (for file backend)




Upgrade:

- pull the latest repo
- check .env file for correct update version
- re-build rhodecode
- docker-compose build rhodecode
- docker-compose stop
- docker-compose up















Logging is pushed to stdout from all services.

## Simple build

Build docker RhodeCode `Community` without any dependencies (redis, external db) using 
simple sqlite database and file based caches. 
This is a fully running instance good for small use with 3-5 users.

```shell
docker build -t rhodecode:4.23.2 -f rhodecode.dockerfile \
-e RHODECODE_TYPE=Community \
-e RHODECODE_VERSION=4.23.2 \
-e RHODECODE_DB=sqlite \
-e RHODECODE_USER_NAME=admin \
-e RHODECODE_USER_PASS=secret4 \
-e RHODECODE_USER_EMAIL=support@rhodecode.com \
.
```

note: for debugging better to add `--progress plain` into the build command to obtain all the output from the build.
To Build against existing running Postgres or MySQL you can specify:

    --build-arg RHODECODE_DB=postgresql://postgres:secret@database/rhodecode
    --build-arg RHODECODE_DB=mysql://root:secret@localhost/rhodecode?charset=utf8


To copy over the data into volumes use such command:
```shell
docker run -v logvolume:/data --name data_vol busybox true
docker cp . data_vol:/data
docker rm data_vol
```

Run the container, mounting the required volumes. By default the application would be
available at http://localhost:10020, and default login is (unless specified differently in the build command)

```
user: admin
password: secret4
```

We've not built our image using specific version. It's time to run it:

```shell
docker run \
  --name rhodecode-container \
  --publish 10020:10020 \
  --restart unless-stopped \
  --volume $PWD/config:/etc/rhodecode/conf \
  --volume $PWD/logs:/var/log/rhodecode \
  'rhodecode:4.23.2'
```

Enter container

```shell
docker exec -it rhodecode-container /bin/bash
```

Enter interactive shell

```shell
docker exec -it rhodecode-container /var/opt/rhodecode_bin/bin/rc-ishell /etc/rhodecode/conf/rhodecode.ini
```

Run Database migrations
```shell
docker exec -it rhodecode-container /var/opt/rhodecode_bin/bin/rc-upgrade-db /etc/rhodecode/conf/rhodecode.ini --force-yes
```