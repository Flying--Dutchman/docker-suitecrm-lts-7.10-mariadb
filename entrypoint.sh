#!/bin/bash
#set -e

# logfile=/dev/stdout
# printf '%s\n' "Set permissions" > "$logfile"

mariadb_ready() {
	mysqladmin ping -S /tmp/mysql.sock > /dev/null 2>&1
}
	
setupMariaDB () {
	# Create SuiteCRM DB
	mysql -S /tmp/mysql.sock -e "CREATE DATABASE IF NOT EXISTS ${SUITECRM_DB};" 
	mysql -S /tmp/mysql.sock -e "grant all privileges on ${SUITECRM_DB}.* TO '${SUITECRM_USER}'@'localhost' identified by '${SUITECRM_PASS}';" 
	mysql -S /tmp/mysql.sock -e "flush privileges;" 

	# Make sure that NOBODY can access the server without a password
	mysql -S /tmp/mysql.sock -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${SUITECRM_ROOT_PASS}'; FLUSH PRIVILEGES;"
	mysql -S /tmp/mysql.sock -e "ALTER USER 'www-data'@'localhost' IDENTIFIED BY '${SUITECRM_ROOT_PASS}'; FLUSH PRIVILEGES;"
}


CONTAINER_ALREADY_STARTED=/opt/mariadb/first_start_flag

exec /opt/mariadb/mysql/bin/mysqld_safe --datadir='/opt/mariadb/data' &

while !(mariadb_ready)
    do
       echo "Waiting for MariaDB to start..."
	   sleep 3
    done

echo "Check if first start of container..."

if [[ ! -f "$CONTAINER_ALREADY_STARTED" ]]; then
	touch "$CONTAINER_ALREADY_STARTED"
	echo "Container started for the first time"
	setupMariaDB
else
	echo "Container restarted"
fi



exec apache2-foreground