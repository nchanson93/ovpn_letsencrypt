#!/bin/bash

# Install snap service
apt update && apt isntall snapd

# Make sure snap is up to date
snap isntall core; snap refresh core

# Install certbot
snap install --classic certbot

# Prepare the certbot command
ln -s /snap/bin/certbot /usr/bin/certbot

# Confirm plugin containment level
snap set certbot trust-plugin-with-root=ok

# Install cloudflare plugin
snap install certbot-dns-cloudflare

# Create credential file 
echo "dns_cloudflare_api_token = $TOKEN" >> /root/.secrets/certbot/cloudflare.ini

# Set credential file permisisons
chmod 600 /root/.secrets/certbot/cloudflare.ini

# Generate certificate
certbot certonly --dns-cloudflare --dns-cloudflare-credentials /root/.secrets/certbot/cloudflare.ini -d $DOMAIN

# Create script to import certificate to OpenVPN
echo #!/bin/bash \
/usr/local/openvpn_as/scripts/sacli --key "cs.priv_key" --value_file "/etc/letsencrypt/live/vpn.DOMAIN.com/privkey.pem" ConfigPut \
/usr/local/openvpn_as/scripts/sacli --key "cs.cert" --value_file "/etc/letsencrypt/live/vpn.DOMAIN.com/fullchain.pem" ConfigPut \
/usr/local/openvpn_as/scripts/sacli start \
>> /usr/bin/import_ovpn_cert.sh

# Make script executable
chmod +x /usr/bin/import_ovpn_cert.sh

# Initial import of certificate to OpenVPN
/usr/local/openvpn_as/scripts/sacli --key "cs.priv_key" --value_file "/etc/letsencrypt/live/vpn.DOMAIN.com/privkey.pem" ConfigPut
/usr/local/openvpn_as/scripts/sacli --key "cs.cert" --value_file "/etc/letsencrypt/live/vpn.DOMAIN.com/fullchain.pem" ConfigPut
/usr/local/openvpn_as/scripts/sacli start

