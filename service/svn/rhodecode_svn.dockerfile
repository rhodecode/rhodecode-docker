FROM debian:buster
MAINTAINER RhodeCode Inc. <support@rhodecode.com>

ENV \
    RC_USER=rhodecode \
    MOD_DAV_SVN_CONF_FILE=/etc/rhodecode/conf/svn/mod_dav_svn.conf

RUN \
echo "** install base svn packages **" && \
  apk update && \
  apk add --no-cache \
    tini \
    bash \
    curl \
    apache2 \
    apache2-utils \
    apache2-webdav \
    mod_dav_svn \
    subversion

# configure the system user
# explicitly set uid/gid to guarantee that it won't change in the future
# the values 999:999 are identical to the current user/group id assigned
RUN \
echo "** Create system user $RC_USER **" && \
  groupadd --system --gid 999 $RC_USER && \
  useradd --system --gid $RC_USER --uid 999 --shell /bin/bash $RC_USER


RUN \
echo "**** cleanup ****" && \
    apk del tzdata python2 && \
    rm -f /tmp/* && \
    rm -rf /var/lib/apt/lists/* \
    rm -rf /var/cache/apk/*

RUN \
    echo "**** Apache config cleanup ****" && \
    rm -f /etc/apache2/conf.d/info.conf \
          /etc/apache2/conf.d/mpm.conf \
          /etc/apache2/conf.d/userdir.conf


COPY svn/virtualhost.conf /etc/apache2/conf.d/

# copy entrypoints
COPY entrypoints.d/svn-entrypoint.sh /opt/entrypoints.d/svn-entrypoint.sh
RUN chmod +x /opt/entrypoints.d/svn-entrypoint.sh

RUN \
    echo $(strings /usr/lib/apache2/mod_dav_svn.so | grep 'Powered by') > /var/opt/dav.version && \
    mkdir -p /run/apache2 && \
    mkdir -p /var/opt/www && \
    echo "export APACHE_RUN_USER=${RC_USER}" > /etc/apache2/envvars && \
    echo "export APACHE_RUN_GROUP=${RC_USER}" >> /etc/apache2/envvars && \
    sed -i "s/User apache/User ${RC_USER}/g" /etc/apache2/httpd.conf && \
    sed -i "s/Group apache/Group ${RC_USER}/g" /etc/apache2/httpd.conf

# repo store volume
VOLUME /var/opt/rhodecode_repo_store

# config volume
VOLUME /etc/rhodecode/conf

# logs volume
VOLUME /var/log/rhodecode

ENTRYPOINT ["/opt/entrypoints.d/svn-entrypoint.sh"]

CMD ["apachectl", "-D", "FOREGROUND"]
