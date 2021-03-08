# SuiteCRM LTS 7.10 with MariaDB - Docker

A dockerized version of SuiteCRM LTS, complete with PHP, Apache and MariaDB.

This image is not extensively tested and therefore not intended for production use.

# Enviroment variables
| Variable  | Default value  | Description  |
| ------------ | ------------ | ------------ |
| SUITECRM_DB  | suitecrmdb  | SuiteCRM database name  |
| SUITECRM_USER  | suitecrmusr   | MariaDB user for the SuiteCRM database  |
| SUITECRM_PASS  | suitecrmusrpass  | Password for the MariaDB user > SUITECRM_USER |
| SUITECRM_ROOT_PASS  | too long to post here  | Password for the MariaDB root user  |


# Ports
8080 - SuiteCRM

# Volumes

### SuiteCRM
All SuiteCRM volume folders in one: `/var/www/html/docker.d`
SuiteCRM upload folder: `/var/www/html/upload`
SuiteCRM configuration: `/var/www/html/docker.d/conf.d`
SuiteCRM logfile: `/var/www/html/docker.d/log`
SuiteCRM custom folder: `/var/www/html/custom`
Entire SuiteCRM folder (if needed): `/var/www/html/`

### MariaDB
MariaDB: `/opt/mariadb`