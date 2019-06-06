#!/bin/bash

cd /opt/eprints3
./bin/epadmin create_tables $APP_KEY
./bin/epadmin update $APP_KEY
./bin/generate_apacheconf --replace --system
./bin/generate_static $APP_KEY
./bin/generate_views $APP_KEY
./bin/import_subjects $APP_KEY archives/$APP_KEY/cfg/subjects

# Insert into httpd.conf
echo "Include /opt/eprints3/cfg/apache.conf" | tee -a /usr/local/apache2/conf/httpd.conf >/dev/null

