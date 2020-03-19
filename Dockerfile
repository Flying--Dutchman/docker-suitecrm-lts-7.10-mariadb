FROM php:7.3-apache
ARG SUITECRM_VERSION=7.10.24

COPY entrypoint.sh php.custom.ini /
#/usr/local/etc/php/conf.d/

RUN apt-get update && apt-get install -y --no-install-recommends cron \
	git \
	libc-client-dev \
	libcurl4-openssl-dev \
    libfreetype6-dev \
	libjpeg62-turbo-dev \
	libkrb5-dev \
	libldap2-dev \
    libmcrypt-dev \
	libpng-dev \
	libpq-dev \
	libssl-dev \
	libxml2-dev \
	libzip-dev \
	unzip \
	zlib1g-dev \
	gosu \
	&& curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*
	
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
	&& docker-php-ext-configure intl \
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
    && docker-php-ext-install -j$(nproc) fileinfo gd imap ldap zip \
       mysqli pdo_mysql pdo_pgsql soap intl
	   
WORKDIR /tmp

#Setting UP SuiteCRM
RUN gosu www-data curl https://codeload.github.com/salesagility/SuiteCRM/zip/v${SUITECRM_VERSION} -o /tmp/master.zip \
    && gosu www-data unzip /tmp/master.zip \
    && gosu www-data mv SuiteCRM-*/* /var/www/html \
    && rm -rf /tmp/* \
    && echo "* * * * * cd /var/www/html; php -f cron.php > /dev/null 2>&1 " | crontab -

WORKDIR /var/www/html

#Setting Up config file redirect for proper use with docker volumes
RUN mkdir conf.d \
    && touch conf.d/config.php \
    && touch conf.d/config_override.php \
    && ln -s conf.d/config.php config.php \
    && ln -s conf.d/config_override.php config_override.php \
    && gosu www-data composer update --no-dev -n \
# custom php configurations
    && mv /php.custom.ini /usr/local/etc/php/conf.d/ \
# entrypoint
    && chmod +x /entrypoint.sh \
# cleanup
    && find /var/www/html -type d -name .git -prune -exec rm -rf {} ';' \
    && apt remove -y git \
    && apt autoremove -y \
    && apt clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
	
VOLUME /var/www/html/upload
VOLUME /var/www/html/conf.d
ENTRYPOINT ["/entrypoint.sh"]
EXPOSE 80
CMD ["gosu","www-data","apache2-foreground"]