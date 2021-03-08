FROM php:7.3-apache
ARG SUITECRM_VERSION=7.10.24
ARG MARIADB_VERSION=10.5.9
ARG COMPOSER_VERSION=1.10.20

ENV SUITECRM_DB=suitecrmdb
ENV SUITECRM_USER=suitecrmusr
ENV SUITECRM_PASS=suitecrmusrpass
ENV SUITECRM_ROOT_PASS=XGrCd5QKzJR9A3SuaDwdktLxABBM7RAq2P5GCj2X2Sa7F48VUAPjDA4NcMcs2vJb0YRDq8r0CidhMgmRCcq2C9FW4G2RVGz2tyX6LEX9UeeGNV9o6yBGav6eQxuH3kpK

# Add MariaDB user
# RUN groupadd -r mysql && useradd -r -g mysql mysql

COPY entrypoint.sh php.custom.ini /

RUN \
# Install packages
    apt-get update && apt-get install -y --no-install-recommends \
    cron \
	dos2unix \
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
	wget \
	libaio1 \
	mariadb-client \
# Install composer
	&& curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer --version=${COMPOSER_VERSION} \
# Cleanup APT
	&& apt autoremove -y \
	&& apt clean \
	&& rm -rf /var/lib/apt/lists/* \
	
	
# ############### MARIADB SETUP ##############
	&& mkdir -p /opt/mariadb/data \
	&& chown -R www-data:www-data /opt/mariadb \
	&& gosu www-data wget -O /opt/mariadb/mariadb-10.5.9-linux-x86_64.tar.gz https://downloads.mariadb.org/interstitial/mariadb-10.5.9/bintar-linux-x86_64/mariadb-10.5.9-linux-x86_64.tar.gz/from/http%3A//mirror2.hs-esslingen.de/mariadb/ \
	&& gosu www-data tar xf /opt/mariadb/mariadb-10.5.9-linux-x86_64.tar.gz -C /opt/mariadb \
	&& gosu www-data ln -s /opt/mariadb/mariadb-10.5.9-linux-x86_64 /opt/mariadb/mysql \
	&& chown -R www-data:www-data /opt/mariadb \
	&& /opt/mariadb/mysql/scripts/mysql_install_db --user=www-data --basedir=/opt/mariadb/mysql --datadir=/opt/mariadb/data \
	&& ln -s /opt/mariadb/mysql/support-files/mysql.server /etc/init.d/mysql \
	&& update-rc.d mysql defaults \
	
	
# ############### APACHE SETUP ##############
# Listen on non privilaged ports
	&& sed -i 's/Listen 80$/Listen 8080/g' /etc/apache2/ports.conf \
	&& sed -i 's/Listen 443$/Listen 8443/g' /etc/apache2/ports.conf \
	&& rm -rf /var/log/apache2/* \
	&& touch /var/log/apache2/access.log /var/log/apache2/error.log /var/log/apache2/other_vhosts_access.log \
	&& chown -R www-data:www-data /var/log/apache2 \
# PHP extensions
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
	&& docker-php-ext-configure intl \
	&& docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
	&& docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
	&& docker-php-ext-install -j$(nproc) fileinfo gd imap ldap zip mysqli pdo_mysql pdo_pgsql soap intl \
	
	
# ############### SUITECRM SETUP ##############
# Setting up SuiteCRM
    && gosu www-data curl https://codeload.github.com/salesagility/SuiteCRM/zip/v${SUITECRM_VERSION} -o /tmp/master.zip \
	&& gosu www-data unzip /tmp/master.zip -d /tmp \
	&& gosu www-data mv /tmp/SuiteCRM-*/* /var/www/html \
	&& rm -rf /tmp/* \
	&& echo "* * * * * cd /var/www/html; php -f cron.php > /dev/null 2>&1 " | crontab - \
# Setting up file redirection for docker volumes
	&& mkdir /var/www/docker.d \
# Log file
	&& mkdir /var/www/docker.d/logs \
	&& touch /var/www/docker.d/logs/suitecrm.log \
	&& ln -s /var/www/docker.d/logs/suitecrm.log /var/www/html/suitecrm.log \
# Config
	&& mkdir /var/www/docker.d/conf.d \
	&& touch /var/www/docker.d/conf.d/config.php \
	&& touch /var/www/docker.d/conf.d/config_override.php \
	&& ln -s /var/www/docker.d/conf.d/config.php /var/www/html/config.php \
	&& ln -s /var/www/docker.d/conf.d/config_override.php /var/www/html/config_override.php \
# htpasswd
	&& touch /var/www/docker.d/conf.d/.htpasswd \
	&& ln -s /var/www/docker.d/conf.d/.htpasswd /var/www/.htpasswd \
# htaccess
	&& touch /var/www/docker.d/conf.d/.htaccess \
	&& ln -s /var/www/docker.d/conf.d/.htaccess /var/www/html/.htaccess \
# Sessions folder
	&& mkdir /var/www/docker.d/sessions \
# Set folder rights
	&& chown -hR www-data:www-data /var/www/ \
# Update composer
	&& gosu www-data composer update --no-dev -n \
# custom php configurations
	&& mv /php.custom.ini /usr/local/etc/php/conf.d/ \
# Set folder rights
	&& mkdir -p /var/www/html/cache \
	&& chmod -R 755 /var/www/html \
	&& chmod 775 /var/www/html/config_override.php 2>/dev/null \
	&& chmod -R 775 /var/www/html/cache /var/www/html/custom /var/www/html/modules /var/www/html/themes /var/www/html/data /var/www/html/upload \
	&& chown -hR www-data:www-data /var/www/html/cache \ 
	
	
# ############### STARTUP SETUP ##############
# entrypoint
	&& dos2unix /entrypoint.sh \
	&& chmod 777 /entrypoint.sh \
# Change access righs to conf, logs, bin from root to www-data
	&& chown -hR www-data:www-data /etc/apache2/ 
	
	
# Define SuiteCRM volumes
VOLUME /var/www/docker.d
VOLUME /var/www/html/upload
VOLUME /var/www/docker.d/conf.d
VOLUME /var/www/docker.d/logs
VOLUME /var/www/html/custom
# Entire SuiteCRM folder (if needed)
VOLUME /var/www/html/
# MariaDB volume
VOLUME /opt/mariadb

# Define ports
EXPOSE 8080

# Run healtcheck
HEALTHCHECK --interval=60s --timeout=30s --start-period=20s CMD curl --fail http://localhost:8080/ || exit 1

ENTRYPOINT ["gosu", "www-data", "/entrypoint.sh"]