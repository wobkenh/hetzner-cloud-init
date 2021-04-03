#!/bin/bash

while [[ $# -gt 0 ]]
do
key="$1"

case $key in
  --hcloud-token)
    TOKEN="$2"
    shift
    shift
  ;;
  --whitelisted-ips)
    WHITELIST_S="$2"
    shift
    shift
  ;;
  --floating-ips)
    FLOATING_IPS="--floating-ips"
    shift
  ;;
  *)
    shift
  ;;
esac
done

FLOATING_IPS=${FLOATING_IPS:-""}


wget https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
chmod +x jq-linux64
mv jq-linux64 /usr/local/bin/jq


curl -o /usr/local/bin/update-config.sh https://raw.githubusercontent.com/wobkenh/hetzner-cloud-init/master/update-config.sh

chmod +x /usr/local/bin/update-config.sh

IFS=', ' read -r -a WHITELIST <<< "$WHITELIST_S"

for IP in "${WHITELIST[@]}"; do
  ufw allow from "$IP"
done

ufw allow from 10.43.0.0/16
ufw allow from 10.42.0.0/16
ufw allow from 10.0.0.0/16 # default private network cidr
ufw allow from 10.244.0.0/16 # in case we use the default cidr expected by the cloud controller manager

ufw -f default deny incoming
ufw -f default allow outgoing

ufw -f enable

cat <<EOF >> /etc/crontab
* * * * * root /usr/local/bin/update-config.sh --hcloud-token ${TOKEN} --whitelisted-ips ${WHITELIST_S} ${FLOATING_IPS}
EOF

/usr/local/bin/update-config.sh --hcloud-token ${TOKEN} --whitelisted-ips ${WHITELIST_S} ${FLOATING_IPS}

echo "Miau ist wuff"
