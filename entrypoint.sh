#!/bin/bash
set -euo pipefail

# Applying desidered PUID to user Nobody
sed -i 's/:1000:100:/:'$PUID':100:/g' /etc/passwd

if [ ! -e /var/www/html/index.php ] && [ ! -e /var/www/html/wp-includes/version.php ]; then
    echo "WordPress is missing, installing now."
	if [[ "$DB_HOST" = "db" && "$DB_NAME" = "wordpress" && "$DB_USER" = "wordpress" && "$DB_PASSWORD" = "wordpress" ]]; then
            echo "No configuration provided, installing Wordpress with Wizard support."
	    rm /usr/src/wordpress/wp-config.php /usr/src/wordpress/wp-secrets.php
	else
            echo "Data provided with -e variables, auto configuring Wordpress."
            curl --silent -f https://api.wordpress.org/secret-key/1.1/salt/ >> /usr/src/wordpress/wp-secrets.php && \
	    sed -i "s/'DB_HOST', 'db'/'DB_HOST', '$DB_HOST'/g" /usr/src/wordpress/wp-config.php && \
            sed -i "s/'DB_NAME', 'wordpress'/'DB_NAME', '$DB_NAME'/g" /usr/src/wordpress/wp-config.php && \
            sed -i "s/'DB_USER', 'wordpress'/'DB_USER', '$DB_USER'/g" /usr/src/wordpress/wp-config.php && \
            sed -i "s/'DB_PASSWORD', 'wordpress'/'DB_PASSWORD', '$DB_PASSWORD'/g" /usr/src/wordpress/wp-config.php
        fi
    chown -R nobody:users /usr/src/wordpress && \
    cp -R /usr/src/wordpress/* /var/www/html && \
    chown -R nobody:users /var/www/html
    echo "Done, Wordpress is ready to use."
fi
# Unset compiled variables for PHP
unset PHP_MD5 PHP_INI_DIR GPG_KEYS PHP_LDFLAGS PHP_SHA256 \
      PHPIZE_DEPS PHP_URL PHP_EXTRA_CONFIGURE_ARGS SHLVL \
      PHP_CFLAGS PHP_ASC_URL PHP_CPPFLAGS SUPERVISOR_ENABLED \
      SUPERVISOR_PROCESS_NAME SUPERVISOR_GROUP_NAME
# Unset user variables
unset DB_HOST DB_NAME DB_USER DB_PASSWORD PUID TZ
exec "$@"
