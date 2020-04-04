#!/bin/bash
set -euo pipefail

sed -i 's/:1000:100:/:'$PUID':100:/g' /etc/passwd
chown -R nobody:users /usr/src

if ! [ -e index.php -a -e inc/class_core.php ]; then
	echo >&2 "MyBB not found in $PWD - copying now..."
	if [ "$(ls -A)" ]; then
		echo >&2 "WARNING: $PWD is not empty - press Ctrl+C now if this is an error!"
		( set -x; ls -A; sleep 10 )
	fi
	tar cf - --one-file-system -C /usr/src/mybb-mybb_1822 . | tar xf -
        chown -R nobody:users /var/www
        echo >&2 "Complete! MyBB ${MYBB_VERSION} has been successfully copied to $PWD"
fi

unset PHP_MD5 PHP_INI_DIR GPG_KEYS PHP_LDFLAGS PHP_SHA256 \
      PHPIZE_DEPS PHP_URL PHP_EXTRA_CONFIGURE_ARGS SHLVL \
      PHP_CFLAGS PHP_ASC_URL PHP_CPPFLAGS SUPERVISOR_ENABLED \
      SUPERVISOR_PROCESS_NAME SUPERVISOR_GROUP_NAME

unset PUID TZ
exec "$@"
