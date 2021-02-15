FROM debian:buster
MAINTAINER RhodeCode Inc. <support@rhodecode.com>

# env are runtime/build
ENV \
    TZ="UTC" \
    RC_USER=rhodecode \
    RHODECODE_USER_NAME=rhodecode \
    SSHD_CONF_FILE=/etc/rhodecode/sshd_config

RUN \
echo "** install base packages **" && \
set -eux; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
        bash \
        tzdata \
        vim \
        openssl \
        openssh-server \
	; \
	rm -rf /var/lib/apt/lists/*;

#	# reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
#	apt-mark auto '.*' > /dev/null; \
#	[ -z "$savedAptMark" ] || apt-mark manual $savedAptMark; \
#	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false

# configure the system user
# explicitly set uid/gid to guarantee that it won't change in the future
# the values 999:999 are identical to the current user/group id assigned
RUN \
echo "** Create system user $RC_USER **" && \
  groupadd --system --gid 999 $RC_USER && \
  useradd --system --gid $RC_USER --uid 999 --shell /bin/bash $RC_USER


RUN \
echo "** prepare rhodecode store and cache **" && \
  install -d -m 0700 -o $RC_USER -g $RC_USER /home/$RC_USER/.ssh

# set the defult bash shell
SHELL ["/bin/bash", "-c"]

# Fix and set a timezone
RUN \
echo "** configure the timezone **" && \
echo $TZ > /etc/timezone

# expose our custom sshd config
COPY service/sshd/sshd_config $SSHD_CONF_FILE

USER root

RUN \
echo "**** cleanup ****" && \
    rm -f /tmp/* && \
    rm -rf /var/lib/apt/lists/* \
    rm -rf /var/cache/apk/*

# copy entrypoints
COPY entrypoints.d/ssh-entrypoint.sh /opt/entrypoints.d/ssh-entrypoint.sh
RUN chmod +x /opt/entrypoints.d/ssh-entrypoint.sh

# config volume
VOLUME /etc/rhodecode/conf

# logs volume
VOLUME /var/log/rhodecode

ENTRYPOINT ["/opt/entrypoints.d/ssh-entrypoint.sh"]

# compose can override this
CMD ["/usr/sbin/sshd", "-f", "/etc/rhodecode/sshd_config", "-D", "-e"]
