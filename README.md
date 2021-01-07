# RhodeCode Docker

## Download installer binaries

First start by fetching required installer binaries. This is required to create both
simple build and full compose setup.
Download needed installer files, version can be adjusted in the download script
Currently this is version 4.23.2, version can be adjusted in `.env` file

`cd .boostrap/; ./download-artifacts.sh; cd ../`

## docker compose:

There's a more advanced high-performance setup using docker-compose. 
It bootstraps additional services for RhodeCode:

- RhodeCode
- VCSServer
- SSH Server  
- Redis Database
- Postgres database
- Channelstream websocket server
- Celery workers, and automation scheduler
- SVN webserver for HTTP support
- Nginx HTTP Server

To create a full stack we need to run the database container, so it's ready to
build the docker image.

1) start with running the required database for the build stage in the background.
   
    ```shell
    docker-compose up --detach database
    ```
   
    This will start our postgres database, and expose it to the network. 
    We can now run the full installation. Database needs to be running for the next build command.
    
    ```shell
    docker-compose build rhodecode && docker-compose build
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



Logging is pushed to stdout from all services.

## Simple build

Build docker RhodeCode `Community` without any dependencies (redis, external db) using 
simple sqlite database and file based caches. 
This is a fully running instance good for small use with 3-5 users.

```shell
docker build -t rhodecode:4.23.2 -f rhodecode.dockerfile \
--build-arg RHODECODE_TYPE=Community \
--build-arg RHODECODE_VERSION=4.23.2 \
--build-arg RHODECODE_DB=sqlite \
--build-arg RHODECODE_USER=admin \
--build-arg RHODECODE_USER_PASS=secret4 \
--build-arg RHODECODE_USER_EMAIL=support@rhodecode.com \
.
```

note: for debugging better to add `--progress plain` into the build command to obtain all the output from the build.
To Build against existing running Postgres or MySQL you can specify:

    --build-arg RHODECODE_DB=postgresql://postgres:secret@database/rhodecode
    --build-arg RHODECODE_DB=mysql://root:secret@localhost/rhodecode?charset=utf8

There are 4 volumes defined:

- `/var/log/rhodecode` # all logs from RhodeCode are saved in this volume
- `/etc/rhodecode/conf` # storing configuration files for rhodecode, vcsserver and supervisord, and some cache data
- `/var/opt/rhodecode_repo_store` # main repository storage where repositories would be stored
- `/var/opt/rhodecode_data` # data dir for rhodecode cache/lock files, or user sessions (for file backend)


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