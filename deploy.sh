#!/bin/bash

YOUR_DOMAIN="yourdomain.com"
REPO_URL="https://github.com/temikom/ifa-legacy-portal.git"
PROJECT_DIR="/ifa-legacy"
BUILD_FOLDER="dist"  

apt update -y

echo "Installing Git, Curl, Node.js, and Nginx..."
apt install git curl nginx -y

curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

echo "Cloning GitHub repository..."
rm -rf $PROJECT_DIR
git clone $REPO_URL $PROJECT_DIR

echo "Building project..."
cd $PROJECT_DIR
npm install
npm run build

echo "Configuring NGINX..."
NGINX_CONF="/etc/nginx/sites-available/ifa-legacy"
rm -f $NGINX_CONF

cat <<EOF >> $NGINX_CONF
server {
    listen 80;
    server_name $YOUR_DOMAIN www.$YOUR_DOMAIN;

    root $PROJECT_DIR/$BUILD_FOLDER;
    index index.html;

    location / {
        try_files \$uri \$uri/ /index.html;
    }
}
EOF

ln -sf $NGINX_CONF /etc/nginx/sites-enabled/

nginx -t && systemctl restart nginx

echo "Installing Certbot for HTTPS..."
apt install certbot python3-certbot-nginx -y

echo "Requesting SSL certificate..."
certbot --nginx -d $YOUR_DOMAIN -d www.$YOUR_DOMAIN --non-interactive --agree-tos -m admin@$YOUR_DOMAIN

echo "Deployment complete!"
echo "Your site is live at: https://$YOUR_DOMAIN"
