FROM ubuntu:groovy
MAINTAINER RhodeCode Inc. <support@rhodecode.com>

ARG TZ="UTC"
ARG LOCALE_TYPE=en_US.UTF-8
ARG RHODECODE_TYPE=Enterprise
# binary-install
ARG RHODECODE_VERSION=4.24.1

ARG RHODECODE_DB=sqlite
ARG RHODECODE_USER_NAME=admin
ARG RHODECODE_USER_PASS=secret4
ARG RHODECODE_USER_EMAIL=support@rhodecode.com

# env are runtime
ENV \
    TZ=${TZ} \
    LOCALE_TYPE=${LOCALE_TYPE} \
    \
    ## Define type we build, and the instance we'll create
    RHODECODE_TYPE=${RHODECODE_TYPE} \
    RC_TYPE_ID=enterprise-1 \
    \
    ## SETUP ARGS FOR INSTALLATION ##
    ## set version we build on, get from .env or set default ver
    RHODECODE_VERSION=${RHODECODE_VERSION} \
    \
    ## set DB, default sqlite
    RHODECODE_DB=${RHODECODE_DB} \
    \
    ## set app bootstrap required data
    RHODECODE_USER_NAME=${RHODECODE_USER_NAME} \
    RHODECODE_USER_PASS=${RHODECODE_USER_PASS} \
    RHODECODE_USER_EMAIL=${RHODECODE_USER_EMAIL} \
    \
    RC_USER=rhodecode \
    \
    # SVN CONFIG
    MOD_DAV_SVN_CONF_FILE=/etc/rhodecode/conf/svn/mod_dav_svn.conf \
    MOD_DAV_SVN_PORT=8090 \
    \
    # SSHD CONFIG
    SSHD_CONF_FILE=/etc/rhodecode/sshd_config \
    \
    BUILD_CONF=/etc/rhodecode/conf_build \
    BUILD_BIN_DIR=/var/opt/rhodecode_bin \
    RHODECODE_DATA_DIR=/var/opt/rhodecode_data \
    RHODECODE_REPO_DIR=/var/opt/rhodecode_repo_store \
    RHODECODE_HTTP_PORT=10020 \
    RHODECODE_VCS_PORT=10010 \
    RHODECODE_HOST=0.0.0.0 \
    RHODECODE_VCS_HOST=127.0.0.1

ENV \
    RCCONTROL=/home/$RC_USER/.rccontrol-profile/bin/rccontrol \
    SUPERVISOR_CONF=/home/$RC_USER/.rccontrol/supervisor/supervisord.ini \
    # make application scripts visible
    PATH=$PATH:/home/$RC_USER/.rccontrol-profile/bin

ENV SVN_LOCALE_DEPS apache2 apache2-utils libapache2-mod-svn
ENV SSH_LOCALE_DEPS openssh-server
ENV PYTHON_DEPS python2

RUN \
echo "** install base packages **" && \
set -eux; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	apt-get update; \
	DEBIAN_FRONTEND="noninteractive" \
	apt-get install -y --no-install-recommends \
        tini \
        bash \
        binutils \
        tzdata \
        locales \
        openssl \
        curl \
        sudo \
        gosu \
        bzip2 \
        ca-certificates \
        $PYTHON_DEPS \
        $SSH_LOCALE_DEPS \
        $SVN_LOCALE_DEPS \
	; \
	rm -rf /var/lib/apt/lists/*;

RUN \
echo "** Configure the python executable for py2/3 compat **" && \
ISPY=$(which python3 || which python2) && \
if [ -n $ISPY ] ; then ln -s $ISPY /usr/bin/python ; fi

RUN \
echo "** Configure the locales **" && \
    sed -i "s/^# ${LOCALE_TYPE}/${LOCALE_TYPE}/g" /etc/locale.gen && \
    locale-gen

# locale-archive is a fix for old nix glibc2.26 locales available
ENV \
    LOCALE_ARCHIVE=/var/opt/locale-archive \
    LANG=${LOCALE_TYPE} \
    LANGUAGE=${LOCALE_TYPE} \
    LC_ALL=${LOCALE_TYPE}

# configure the system user
# explicitly set uid/gid to guarantee that it won't change in the future
# the values 999:999 are identical to the current user/group id assigned
RUN \
echo "** Create system user $RC_USER **" && \
  groupadd --system --gid 999 $RC_USER && \
  useradd --system --gid $RC_USER --uid 999 --shell /bin/bash $RC_USER && \
  usermod -G $RC_USER $RC_USER

# set the defult bash shell
SHELL ["/bin/bash", "-c"]

# Fix and set a timezone
RUN \
echo "** configure the timezone **" && \
rm /etc/localtime && cp /usr/share/zoneinfo/$TZ /etc/localtime && \
echo $TZ > /etc/timezone


RUN \
echo "** prepare rhodecode store and cache **" && \
  install -d -m 0700 -o $RC_USER -g $RC_USER /nix && \
  install -d -m 0755 -o $RC_USER -g $RC_USER /opt/rhodecode && \
  install -d -m 0755 -o $RC_USER -g $RC_USER /var/opt/rhodecode_bin && \
  install -d -m 0755 -o $RC_USER -g $RC_USER $RHODECODE_REPO_DIR && \
  install -d -m 0755 -o $RC_USER -g $RC_USER $RHODECODE_DATA_DIR && \
  install -d -m 0755 -o $RC_USER -g $RC_USER $BUILD_CONF && \
  install -d -m 0755 -o $RC_USER -g $RC_USER /home/$RC_USER/ && \
  install -d -m 0755 -o $RC_USER -g $RC_USER /home/$RC_USER/.rccontrol && \
  install -d -m 0755 -o $RC_USER -g $RC_USER /home/$RC_USER/.rccontrol/cache && \
  install -d -m 0755 -o $RC_USER -g $RC_USER /home/$RC_USER/.rccontrol/bootstrap && \
  install -d -m 0700 -o $RC_USER -g $RC_USER /home/$RC_USER/.ssh && \
  install -d -m 0700 -o $RC_USER -g $RC_USER /home/$RC_USER/.rhoderc

# expose our custom sshd config
COPY service/sshd/sshd_config $SSHD_CONF_FILE

# Apache SVN setup
RUN \
    echo "**** Apache config cleanup ****" && \
    rm -f /etc/apache2/conf.d/info.conf \
          /etc/apache2/conf.d/mpm.conf \
          /etc/apache2/conf.d/userdir.conf && \
    rm -f /etc/apache2/sites-enabled/* && \
    rm -f /etc/apache2/sites-available/*

# custom SVN virtualhost
COPY service/svn/virtualhost.conf /etc/apache2/sites-enabled/

RUN \
echo "**** Apache config ****" && \
    echo $(strings /usr/lib/apache2/modules/mod_dav_svn.so | grep 'Powered by') > /var/opt/dav.version && \
    mkdir -p /run/apache2 && \
    mkdir -p /var/opt/www && \
    echo "unset HOME" > /etc/apache2/envvars && \
    echo "export APACHE_RUN_USER=${RC_USER}" >> /etc/apache2/envvars && \
    echo "export APACHE_PID_FILE=/var/run/apache2/apache2.pid" >> /etc/apache2/envvars && \
    echo "export APACHE_RUN_DIR=/var/run/apache2" >> /etc/apache2/envvars && \
    echo "export APACHE_LOCK_DIR=/var/lock/apache2" >> /etc/apache2/envvars && \
    echo "export APACHE_RUN_USER=${RC_USER}" >> /etc/apache2/envvars && \
    echo "export APACHE_RUN_GROUP=${RC_USER}" >> /etc/apache2/envvars && \
    sed -i "s/Listen 80/Listen ${MOD_DAV_SVN_PORT}/g" /etc/apache2/ports.conf


# Copy artifacts
COPY --chown=$RC_USER:$RC_USER .cache/* /home/$RC_USER/.rccontrol/cache/
COPY --chown=$RC_USER:$RC_USER config/compose/rhodecode_enterprise.license /home/$RC_USER/.rccontrol/bootstrap/
COPY --chown=$RC_USER:$RC_USER service/rhodecode/bootstrap/* /home/$RC_USER/.rccontrol/bootstrap/

RUN \
echo "**** locale-archive path ****" && \
    mv -v /home/$RC_USER/.rccontrol/cache/locale-archive /var/opt/locale-archive

# change to non-root user for RUN commands
USER $RC_USER
WORKDIR /home/$RC_USER

RUN \
echo "** install rhodecode control **" && \
  cd /home/$RC_USER/.rccontrol/cache && \
  INSTALLER=$(ls -Art /home/$RC_USER/.rccontrol/cache/RhodeCode-installer-* | tail -n 1) && \
  chmod +x ${INSTALLER} && \
  ${INSTALLER} --accept-license && \
  ${RCCONTROL} self-init && \
  cp -v /home/$RC_USER/.rccontrol-profile/etc/ca-bundle.crt $BUILD_CONF/ && \
  echo "Done"

RUN \
echo "** install vcsserver ${RHODECODE_VERSION} **" && \
  ${RCCONTROL} install VCSServer --version ${RHODECODE_VERSION} --start-at-boot=yes --accept-license --offline \
  '{"host":"'"$RHODECODE_VCS_HOST"'", "port":"'"$RHODECODE_VCS_PORT"'"}' && \
  VCSSERVER_PATH=/home/$RC_USER/.rccontrol/vcsserver-1 && \
  rm -rf $BUILD_BIN_DIR/vcs_bin && ln -s ${VCSSERVER_PATH}/profile/bin $BUILD_BIN_DIR/vcs_bin && \
  cp -v ${VCSSERVER_PATH}/vcsserver.ini $BUILD_CONF/vcsserver.ini

RUN \
echo "** install rhodecode ${RHODECODE_TYPE} ${RHODECODE_VERSION} **" && \
  RHODECODE_DB_INIT=sqlite && \
  ${RCCONTROL} install ${RHODECODE_TYPE} --version ${RHODECODE_VERSION} --start-at-boot=yes --accept-license --offline \
  '{"host":"'"$RHODECODE_HOST"'", "port":"'"$RHODECODE_HTTP_PORT"'", "username":"'"$RHODECODE_USER_NAME"'", "password":"'"$RHODECODE_USER_PASS"'", "email":"'"$RHODECODE_USER_EMAIL"'", "repo_dir":"'"$RHODECODE_REPO_DIR"'", "database": "'"$RHODECODE_DB_INIT"'", "skip_existing_db": "1"}' && \
  RHODECODE_PATH=/home/$RC_USER/.rccontrol/${RC_TYPE_ID} && \
  rm -rf $BUILD_BIN_DIR/bin && ln -s ${RHODECODE_PATH}/profile/bin $BUILD_BIN_DIR/ && \
  cp -v ${RHODECODE_PATH}/rhodecode.ini $BUILD_CONF/rhodecode.ini && \
  cp -v ${RHODECODE_PATH}/gunicorn_conf.py $BUILD_CONF/gunicorn_conf.py && \
  cp -v ${RHODECODE_PATH}/search_mapping.ini $BUILD_CONF/search_mapping.ini && \
  mkdir -p $RHODECODE_DATA_DIR/static && cp -r ${RHODECODE_PATH}/public/* $RHODECODE_DATA_DIR/static/ && \
  rm ${RHODECODE_PATH}/rhodecode.db


RUN \
echo "** configure supervisord **" && \
  cp -v ${SUPERVISOR_CONF} $BUILD_CONF/ && \
  sed -i "s/self_managed_supervisor = False/self_managed_supervisor = True/g" /home/$RC_USER/.rccontrol.ini && \
  echo "done"

USER root


RUN \
echo "**** cleanup ****" && \
    apt-get remove -y $PYTHON_DEPS && \
    apt-get autoclean -y && \
    rm -f /tmp/* && \
    rm -f /home/$RC_USER/.rccontrol/cache/RhodeCode-installer-* && \
    rm -f /home/$RC_USER/.rccontrol/cache/*.bz2 && \
    rm -rf /var/lib/apt/lists/* \
    rm -rf /var/cache/apk/* \
    rm ${SUPERVISOR_CONF}

# copy entrypoints
COPY entrypoints.d/entrypoint.sh /opt/entrypoints.d/entrypoint.sh
RUN chmod +x /opt/entrypoints.d/entrypoint.sh

# config volume
VOLUME /etc/rhodecode/conf

# repo store volume
VOLUME /var/opt/rhodecode_repo_store

# data volume
VOLUME /var/opt/rhodecode_data

# logs volume
VOLUME /var/log/rhodecode

ENTRYPOINT ["/opt/entrypoints.d/entrypoint.sh"]

# compose can override this
CMD ["supervisord", "--nodaemon", "-c", "/etc/rhodecode/conf/supervisord.ini"]
