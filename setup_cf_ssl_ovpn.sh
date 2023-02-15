#!/bin/bash

# Collect variables
read -p "Please enter domain e.g. vpn.domain.com: " DOMAIN
read -p "Please enter Cloudflare token: " TOKEN

# Install snap service
apt update && apt install snapd -y

# Make sure snap is up to date
snap install core; snap refresh core

# Install certbot
snap install --classic certbot

# Prepare the certbot command
ln -s /snap/bin/certbot /usr/bin/certbot

# Confirm plugin containment level
snap set certbot trust-plugin-with-root=ok

# Install cloudflare plugin
snap install certbot-dns-cloudflare

# Create credential file 
mkdir -p /root/.secrets/certbot
echo "dns_cloudflare_api_token = $TOKEN" >> /root/.secrets/certbot/cloudflare.ini

# Set credential file permisisons
chmod 600 /root/.secrets/certbot/cloudflare.ini

# Generate certificate
certbot certonly --dns-cloudflare --dns-cloudflare-credentials /root/.secrets/certbot/cloudflare.ini -d $DOMAIN

# Create script to import certificate to OpenVPN
echo '#!/bin/bash
/usr/local/openvpn_as/scripts/sacli --key "cs.priv_key" --value_file "/etc/letsencrypt/live/'$DOMAIN'/privkey.pem" ConfigPut
/usr/local/openvpn_as/scripts/sacli --key "cs.cert" --value_file "/etc/letsencrypt/live/'$DOMAIN'/fullchain.pem" ConfigPut
/usr/local/openvpn_as/scripts/sacli start' >> /usr/bin/import_ovpn_cert.sh

# Make script executable
chmod +x /usr/bin/import_ovpn_cert.sh

### Add cronjob to import certificate to OpenVPN monthly
crontab -l > import_ovpn-cert.cron
echo "0 1 1 * * /usr/bin/import_ovpn_cert.sh" >> import_ovpn-cert.cron
crontab import_ovpn-cert.cron
rm import_ovpn-cert.cron

# Initial import of certificate to OpenVPN
/usr/local/openvpn_as/scripts/sacli --key "cs.priv_key" --value_file "/etc/letsencrypt/live/$DOMAIN/privkey.pem" ConfigPut
/usr/local/openvpn_as/scripts/sacli --key "cs.cert" --value_file "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ConfigPut
/usr/local/openvpn_as/scripts/sacli start