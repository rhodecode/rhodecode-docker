#!/usr/bin/env bash
set -Eeo pipefail


function generate_ssh_keys() {
  keys_dir=/etc/rhodecode/conf/ssh

  if [[ ! -d $keys_dir ]]; then
    echo "Generating $keys_dir/ssh_host_rsa_key ..."
    mkdir -p $keys_dir
  fi

  # Generate ssh host key for the first time
  if [[ ! -f $keys_dir/ssh_host_rsa_key ]]; then
    echo "Generating $keys_dir/ssh_host_rsa_key ..."
    ssh-keygen -f $keys_dir/ssh_host_rsa_key -N '' -t rsa
    chmod 0600 $keys_dir/ssh_host_rsa_key
  fi

  if [[ ! -f $keys_dir/ssh_host_ecdsa_key ]]; then
    echo "Generating $keys_dir/ssh_host_ecdsa_key ..."
    ssh-keygen -f $keys_dir/ssh_host_ecdsa_key -N '' -t ecdsa
    chmod 0600 $keys_dir/ssh_host_ecdsa_key
  fi

  if [[ ! -f $keys_dir/ssh_host_ed25519_key ]]; then
    echo "Generating $keys_dir/ssh_host_ed25519_key ..."
    ssh-keygen -f $keys_dir/ssh_host_ed25519_key -N '' -t ed25519
    chmod 0600 $keys_dir/ssh_host_ed25519_key
  fi

  if [[ ! -f $keys_dir/authorized_keys ]]; then
    echo "Generating $keys_dir/authorized_keys..."
    touch $keys_dir/authorized_keys
  fi

  sed -i "s/AllowUsers USER/AllowUsers $RC_USER/" $SSHD_CONF_FILE
}

echo "ENTRYPOINT: Running with cmd '$1'"


if [ "$SSH_BOOTSTRAP" = 1 ]; then
  # generate SSH keys
  generate_ssh_keys
fi

mkdir -p /run/sshd
exec "$@"
