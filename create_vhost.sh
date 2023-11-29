#!/bin/bash

# Default values
PHP_VERSION="8.2"
SSL_ENABLED=false
SSL_CERT_FILE=""
SSL_KEY_FILE=""

# Function to display usage information
usage() {
    echo "Usage: $0 -s <site_name> [-p <php_version>] [-ssl]"
    echo "Options:"
    echo "  -s   Site name (e.g., example.test)"
    echo "  -p   PHP version (default is 8.2, optional: 8.1, 7.4)"
    echo "  -ssl Enable SSL"
    exit 1
}

# Function to generate SSL certificate and key
generate_ssl() {
    sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "/etc/ssl/private/$SITE_NAME.key" \
        -out "/etc/ssl/certs/$SITE_NAME.crt" \
        -subj "/C=US/ST=State/L=City/O=Organization/OU=Unit/CN=$SITE_NAME"
    SSL_CERT_FILE="/etc/ssl/certs/$SITE_NAME.crt"
    SSL_KEY_FILE="/etc/ssl/private/$SITE_NAME.key"
}

# Function to update /etc/hosts file
update_hosts_file() {
    HOSTS_ENTRY="127.0.0.1       $SITE_NAME"
    sudo sed -i "/# The following lines are desirable for IPv6 capable hosts/ i $HOSTS_ENTRY" /etc/hosts
}

# Parse command line options
OPTIONS=$(getopt -o s:p: -l site-name:,php-version:,ssl -- "$@")
eval set -- "$OPTIONS"

while true; do
    case "$1" in
        -s|--site-name)
            SITE_NAME="$2"
            shift 2
            ;;
        -p|--php-version)
            PHP_VERSION="$2"
            shift 2
            ;;
        --ssl)
            SSL_ENABLED=true
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            usage
            ;;
    esac
done

# Check if required options are provided
if [ -z "$SITE_NAME" ]; then
    echo "Site name is required."
    usage
fi

# Set up virtual host configuration
VHOST_CONF="/etc/apache2/sites-available/$SITE_NAME.conf"
VHOST_PUBLIC_FOLDER="/var/www/$SITE_NAME/public"
VHOST_MAIN_FOLDER="/var/www/$SITE_NAME"


# Create the directory for the site
sudo mkdir -p "$VHOST_PUBLIC_FOLDER"
sudo chown -R $USER:www-data "$VHOST_MAIN_FOLDER"
sudo chmod -R o+r "$VHOST_MAIN_FOLDER"
sudo chmod -R g+w "$VHOST_MAIN_FOLDER"



# Create the virtual host configuration for HTTP (port 80)
HTTP_SECTION="
<VirtualHost $SITE_NAME:80>
    ServerAdmin admin@$SITE_NAME
    ServerName $SITE_NAME
    ServerAlias www.$SITE_NAME
    DocumentRoot $VHOST_PUBLIC_FOLDER
    DirectoryIndex index.php  

    <Directory $VHOST_PUBLIC_FOLDER>
        Options +Indexes
        AllowOverride All
        Require all granted
    </Directory>

    <FilesMatch \.php$>
        # For Apache version 2.4.10 and above, use SetHandler to run PHP as a fastCGI process server
        SetHandler \"proxy:unix:/run/php/php$PHP_VERSION-fpm.sock|fcgi://localhost\"
    </FilesMatch>

    ErrorLog \${APACHE_LOG_DIR}/${SITE_NAME}_error.log
    CustomLog \${APACHE_LOG_DIR}/${SITE_NAME}_access.log combined
</VirtualHost>
"

# Create the virtual host configuration for HTTPS (port 443)
HTTPS_SECTION=""
if [ "$SSL_ENABLED" = true ]; then
    generate_ssl
    HTTPS_SECTION="
<VirtualHost $SITE_NAME:443>
    ServerAdmin admin@$SITE_NAME
    ServerName $SITE_NAME
    ServerAlias www.$SITE_NAME
    DocumentRoot $VHOST_PUBLIC_FOLDER
    DirectoryIndex index.php

    <Directory $VHOST_PUBLIC_FOLDER>
        Options +Indexes
        AllowOverride All
        Require all granted
    </Directory>

    <FilesMatch \.php$>
        # For Apache version 2.4.10 and above, use SetHandler to run PHP as a fastCGI process server
        SetHandler \"proxy:unix:/run/php/php$PHP_VERSION-fpm.sock|fcgi://localhost\"
    </FilesMatch>

    ErrorLog \${APACHE_LOG_DIR}/${SITE_NAME}_error.log
    CustomLog \${APACHE_LOG_DIR}/${SITE_NAME}_access.log combined

    SSLEngine on
    SSLCertificateFile $SSL_CERT_FILE
    SSLCertificateKeyFile $SSL_KEY_FILE
</VirtualHost>
"
fi

# Concatenate the HTTP and HTTPS sections and create the virtual host configuration
{ echo "$HTTP_SECTION"; echo "$HTTPS_SECTION"; } | sudo tee "$VHOST_CONF" > /dev/null



# Set the index.php file path
INDEX_FILE="$VHOST_PUBLIC_FOLDER/index.php"

# Check if index.php already exists
if [ ! -e "$INDEX_FILE" ]; then
    # Create index.php in the public folder
    echo "<?php phpinfo(); ?>" | sudo tee "$INDEX_FILE" > /dev/null

    # Set ownership for the index.php file
    sudo chown "$USER:www-data" "$INDEX_FILE"
fi


# Enable the site
sudo a2ensite $SITE_NAME

# Reload and Restart Apache to apply changes
sudo systemctl reload apache2
sudo systemctl restart apache2

# Update /etc/hosts file
update_hosts_file

echo "Virtual host for $SITE_NAME created successfully."

# If SSL is enabled, inform the user about the generated certificate and key
if [ "$SSL_ENABLED" = true ]; then
    echo "SSL certificate and key files generated:"
    echo "  Certificate: $SSL_CERT_FILE"
    echo "  Key: $SSL_KEY_FILE"
fi
