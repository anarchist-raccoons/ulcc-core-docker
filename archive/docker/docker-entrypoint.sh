#!/bin/bash

echo 'Running the docker-entrypoint'

# Check the db exists ...
while ! mysqlshow -h mariadb -u $APP_KEY -p$MYSQL_PASSWORD $APP_KEY >/dev/null 2>&1; do
  echo 'Waiting for db ... '
  sleep 1
done

cd /opt/eprints3

if [ ! -f /data/.initialized ]; then
  echo "Initializing repo"
  sed -i "s/changeme/$EXTERNAL_HOSTNAME/" /opt/eprints3/archives/$APP_KEY/cfg/cfg.d/10_core_$APP_KEY.pl
  su eprints -s ./bin/epadmin create_tables $APP_KEY
  su eprints -s ./bin/epadmin update $APP_KEY
  su eprints -s ./bin/import_subjects $APP_KEY archives/$APP_KEY/cfg/subjects
  
  touch /data/.initialized
else
  echo 'Repo already initialized.'
fi

# the extra -- stop su doesn't trying to parse additional arguments
su eprints -s ./bin/generate_apacheconf -- --system --replace
echo "Include /opt/eprints3/cfg/apache.conf" | tee -a /usr/local/apache2/conf/httpd.conf >/dev/null

su eprints -s ./bin/generate_static $APP_KEY
su eprints -s ./bin/generate_views $APP_KEY

# Restore files to cfg/lang/*
cp -r  /data/lang/* /opt/eprints3/archives/$APP_KEY/cfg/lang/
chown -R eprints:eprints /opt/eprints3/archives/$APP_KEY/cfg/lang/

# Backup the files from cfg/lang hourly
(crontab -l ; echo "*/60 * * * * cp -r /opt/eprints3/archives/$APP_KEY/cfg/lang /data/" ) | crontab -
service cron restart

echo "Starting apache"
/usr/local/bin/httpd-foreground
