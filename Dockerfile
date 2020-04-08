FROM php:7.4.4-fpm-alpine

LABEL maintainer="Robbio <github.com/pigr8>" \
      architecture="amd64/x86_64" \
      alpine-version="3.11.2" \
      apache-version="2.4.43" \
      php-fpm-version="7.4.4" \
      myBB-version="1.8.2.2" \
      org.opencontainers.image.title="mybb-fpm-apache" \
      org.opencontainers.image.description="myBB image running on Alpine Linux." \
      org.opencontainers.image.url="https://hub.docker.com/r/pigr8/mybb-fpm-apache/" \
      org.opencontainers.image.source="https://github.com/pigr8/mybb-fpm-apache"

RUN apk add --no-cache \
		bash \
		sed \
		tzdata \
		apache2 \
		apache2-proxy \
		apache2-http2 \
		apache2-ssl \
		supervisor

RUN set -ex; \
	\
	apk add --no-cache --virtual .build-deps \
		$PHPIZE_DEPS \
		libmemcached-dev \
		freetype-dev \
		libjpeg-turbo-dev \
		libpng-dev \
		libwebp-dev \
		libxpm-dev \
		postgresql-dev \
	; \
	\
#	docker-php-ext-configure gd --with-gd --with-webp-dir --with-jpeg-dir --with-png-dir --with-freetype-dir --with-xpm-dir --with-zlib-dir; \
        docker-php-ext-configure gd --with-freetype --with-jpeg; \
        docker-php-ext-install -j "$(nproc)" \
		gd \
		mysqli \
		opcache \
		pgsql \
		zip \
		exif \
	; \
	pecl channel-update pecl.php.net; \
	pecl install memcached redis; \
	docker-php-ext-enable memcached redis; \
	\
	runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)"; \
	apk add --virtual .mybb-phpexts-rundeps $runDeps; \
	apk del .build-deps

RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=2'; \
		echo 'opcache.fast_shutdown=1'; \
                echo 'opcache.enable_cli=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini

RUN { \
		echo 'error_reporting = E_ERROR | E_WARNING | E_PARSE | E_CORE_ERROR | E_CORE_WARNING | E_COMPILE_ERROR | E_COMPILE_WARNING | E_RECOVERABLE_ERROR'; \
		echo 'display_errors = Off'; \
		echo 'display_startup_errors = Off'; \
		echo 'log_errors = On'; \
		echo 'error_log = /dev/stderr'; \
		echo 'log_errors_max_len = 1024'; \
		echo 'ignore_repeated_errors = On'; \
		echo 'ignore_repeated_source = Off'; \
		echo 'html_errors = Off'; \
	} > /usr/local/etc/php/conf.d/error-logging.ini

RUN { \
                echo 'file_uploads=On'; \
                echo 'upload_max_filesize=10M'; \
                echo 'post_max_size=10M'; \
                echo 'max_execution_time=20'; \
                echo 'memory_limit=256M'; \
        } > /usr/local/etc/php/conf.d/mybb-recommended.ini

VOLUME /var/www/html

ENV TZ Europe/Rome
ENV PUID 1000

RUN sed -i 's/:65534:65534:nobody:\/:/:1000:100:nobody:\/var\/www:/g' /etc/passwd && \
    sed -i '/^\s*www-data/ d' /etc/passwd /etc/group && \
    sed -i '/^\s*apache/ d' /etc/passwd /etc/group && \
    sed -i 's/user = www-data/user = nobody/g' /usr/local/etc/php-fpm.d/www.conf && \
    sed -i 's/group = www-data/group = users/g' /usr/local/etc/php-fpm.d/www.conf

RUN set -ex; \
	curl -o mybb.tar.gz -fSL "https://github.com/mybb/mybb/archive/mybb_1822.tar.gz"; \
	tar -xzf mybb.tar.gz -C /usr/src/; \
	rm mybb.tar.gz; \
	chown -R nobody:users /usr/src/*

COPY config/httpd.conf /etc/apache2/
COPY entrypoint.sh /usr/bin/
COPY config/supervisord.conf /etc/
RUN chmod +x /usr/bin/entrypoint.sh

EXPOSE 80
EXPOSE 443

ENTRYPOINT ["entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
