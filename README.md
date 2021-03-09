# SuiteCRM LTS 7.10 with MariaDB - Docker
A dockerized version of SuiteCRM LTS, complete with PHP, Apache and MariaDB.
Automaticly creates backups for MariaDB every night and removes old ones (max 5 days).


This image is not extensively tested nor secured and therefore not intended for production use.



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
All SuiteCRM volume folders in one: `/var/www/html/docker.d` <br>
SuiteCRM upload folder: `/var/www/html/upload` <br>
SuiteCRM configuration: `/var/www/html/docker.d/conf.d` <br>
SuiteCRM logfile: `/var/www/html/docker.d/log` <br>
SuiteCRM custom folder: `/var/www/html/custom` <br>
Entire SuiteCRM folder (if needed): `/var/www/html/` <br>

### MariaDB
MariaDB: `/opt/mariadb/backup`
