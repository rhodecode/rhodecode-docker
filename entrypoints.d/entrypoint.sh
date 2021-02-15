#!/usr/bin/env bash
set -Eeo pipefail

function config_copy() {
  # copy over the configs if they don't exist
  for f in /etc/rhodecode/conf_build/*; do
    fname=${f##*/}
    if [ ! -f "/etc/rhodecode/conf/$fname" ]; then
        echo "$fname not exists copying over as default conf..."
        cp -v $f /etc/rhodecode/conf/$fname
    fi
  done

}

function db_upgrade() {
  echo 'ENTRYPOINT: Upgrading database.'
  /var/opt/rhodecode_bin/bin/rc-upgrade-db $MAIN_INI_PATH --force-yes
}

function db_init() {

  gosu $RC_USER \
    /home/$RC_USER/.rccontrol/$RC_TYPE_ID/profile/bin/rc-setup-app \
    $MAIN_INI_PATH \
    --force-yes \
    --skip-existing-db \
    --user=$RHODECODE_USER_NAME \
    --password=$RHODECODE_USER_PASS \
    --email=$RHODECODE_USER_EMAIL \
    --repos=$RHODECODE_REPO_DIR
}

function rhodecode_setup() {
  for f in /home/$RC_USER/.rccontrol/bootstrap/*.py; do
    fname=${f##*/}

    echo "Running script $fname on $RC_TYPE_ID"
    gosu $RC_USER /home/$RC_USER/.rccontrol/$RC_TYPE_ID/profile/bin/rc-ishell $MAIN_INI_PATH <<< "%run $f"

  done
}

function generate_ssh_keys() {
  keys_dir=/etc/rhodecode/conf/ssh

  if [[ ! -d $keys_dir ]]; then
    echo "Generating $keys_dir/ssh_host_rsa_key ..."
    gosu "$RC_USER" mkdir -p $keys_dir
  fi

  # Generate ssh host key for the first time
  if [[ ! -f $keys_dir/ssh_host_rsa_key ]]; then
    echo "Generating $keys_dir/ssh_host_rsa_key ..."
    gosu "$RC_USER" ssh-keygen -f $keys_dir/ssh_host_rsa_key -N '' -t rsa
    gosu "$RC_USER" chmod 0600 $keys_dir/ssh_host_rsa_key
  fi

  if [[ ! -f $keys_dir/ssh_host_ecdsa_key ]]; then
    echo "Generating $keys_dir/ssh_host_ecdsa_key ..."
    gosu "$RC_USER" ssh-keygen -f $keys_dir/ssh_host_ecdsa_key -N '' -t ecdsa
    gosu "$RC_USER" chmod 0600 $keys_dir/ssh_host_ecdsa_key
  fi

  if [[ ! -f $keys_dir/ssh_host_ed25519_key ]]; then
    echo "Generating $keys_dir/ssh_host_ed25519_key ..."
    gosu "$RC_USER" ssh-keygen -f $keys_dir/ssh_host_ed25519_key -N '' -t ed25519
    gosu "$RC_USER" chmod 0600 $keys_dir/ssh_host_ed25519_key
  fi

  if [[ ! -f $keys_dir/authorized_keys ]]; then
    echo "Generating $keys_dir/authorized_keys..."
    gosu "$RC_USER" touch $keys_dir/authorized_keys
  fi

  sed -i "s/AllowUsers USER/AllowUsers $RC_USER/" $SSHD_CONF_FILE
}


echo "ENTRYPOINT: Running $RC_APP_TYPE with cmd '$1'"

if [ "$SSH_BOOTSTRAP" = 1 ]; then
  # generate SSH keys
  generate_ssh_keys
fi

isLikelyWeb=
case "$1" in
	supervisord | pserve | gunicorn ) isLikelyWeb=1 ;;
esac

if [[ $RC_APP_TYPE = "rhodecode_http" ]]; then

  DB_INIT_FILE=/var/opt/rhodecode_data/.dbinit_bootstrapped
  # Avoid DB_INIT to run 2x
  if [[ ! -e $DB_INIT_FILE ]]; then
    echo "ENTRYPOINT: Starting $RC_APP_TYPE initial db bootstrap"

    db_init

    gosu $RC_USER touch "$DB_INIT_FILE"
    echo "ENTRYPOINT: marked as db-bootstrapped at $DB_INIT_FILE"

  fi

  BOOTSTRAP_FILE=/var/opt/rhodecode_data/.setup_bootstrapped
  # Avoid destroying bootstrapping by simple start/stop
  if [[ ! -e $BOOTSTRAP_FILE ]]; then
    echo "ENTRYPOINT: Starting $RC_APP_TYPE initial bootstrap"

    # copy over default configuration files
    config_copy

    # setup application with specific options
    if [ "$SETUP_APP" = 1 ]; then
      rhodecode_setup
    fi

    gosu $RC_USER touch "$BOOTSTRAP_FILE"
    echo "ENTRYPOINT: marked as setup-bootstrapped at $BOOTSTRAP_FILE"

  fi

  if [ "$DB_UPGRADE" = 1 ]; then
    # run DB migrate
    db_upgrade
  fi

fi


if [ "$RC_APP_PROC" = 1 ]; then
  # Fix problem with zombie processes when using executables like supervisord/gunicorn
  set -- tini -- "$@"
  set -- gosu $RC_USER "$@"
fi

if [ "$RC_APP_TYPE" = "rhodecode_sshd" ]; then
  # Fix problem with Missing privilege separation directory error
  mkdir -p /run/sshd
fi

exec "$@"
