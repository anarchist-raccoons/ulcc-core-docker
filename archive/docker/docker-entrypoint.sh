#!/bin/bash

echo 'Running the docker-entrypoint'

# Check the db exists ...
while ! mysqlshow -h mariadb -u $APP_KEY -p$MYSQL_PASSWORD $APP_KEY >/dev/null 2>&1; do
  echo 'Waiting for db ... '
  sleep 1
done

cd /opt/eprints3

sed -i "s/changeme/$EXTERNAL_HOSTNAME/" /opt/eprints3/archives/$APP_KEY/cfg/cfg.d/10_core_$APP_KEY.pl

if [ ! -f /data/.initialized ]; then
  echo "Initializing repo"
  su eprints -s ./bin/epadmin create_tables $APP_KEY
  su eprints -s ./bin/epadmin update $APP_KEY
  echo "Creating user account for $ADMIN_USER..."
  su eprints -s ./bin/epadmin create_user $APP_KEY $ADMIN_USER admin $ADMIN_PASSWORD $ADMIN_EMAIL
  # copy the default subjects if none in archives/$APP_KEY
  if [ ! -f ./archives/$APP_KEY/cfg/subjects ]; then
    su eprints -s /bin/cp ./lib/defaultcfg/subjects ./archives/$APP_KEY/cfg/subjects
  fi
  # And import subjects
  su eprints -s ./bin/import_subjects $APP_KEY ./archives/$APP_KEY/cfg/subjects
  touch /data/.initialized
else
  echo 'Repo already initialized.'
fi

# the extra -- stop su doesn't trying to parse additional arguments
su eprints -s ./bin/generate_apacheconf -- --system --replace
echo "ErrorLog /usr/local/apache2/logs/error.log" | tee -a /usr/local/apache2/conf/httpd.conf >/dev/null
echo "Include /opt/eprints3/cfg/apache.conf" | tee -a /usr/local/apache2/conf/httpd.conf >/dev/null

su eprints -s ./bin/generate_static $APP_KEY
su eprints -s ./bin/generate_views $APP_KEY
su eprints -s ./bin/indexer start

# Restore files to cfg/lang/*
cp -r  /data/lang/* /opt/eprints3/archives/$APP_KEY/cfg/lang/
chown -R eprints:eprints /opt/eprints3/archives/$APP_KEY/cfg/lang/

# Backup the files from cfg/lang hourly
(crontab -l ; echo "*/60 * * * * cp -r /opt/eprints3/archives/$APP_KEY/cfg/lang /data/" ) | crontab -
service cron restart

echo "Starting apache"
/usr/local/bin/httpd-foreground
