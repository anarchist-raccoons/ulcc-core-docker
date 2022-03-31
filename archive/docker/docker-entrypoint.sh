#!/bin/bash

#bold=$(tput bold)
#normal=$(tput sgr0)
#red=$(tput setaf 1)
#green=$(tput setaf 2)

red="\033[0;31m"
green="\033[0;32m"
normal="\033[0m"
bold="\033[1m"

print_ok="[${green}OK${normal}]"
print_fail="[${red}FAIL${normal}]"

echo -e "---- ${bold}Running the docker-entrypoint${normal} ----"

# Start syslog
service rsyslog start

# Check the db exists ...
while ! mysqlshow -h mariadb -u root -p$MYSQL_ROOT_PASSWORD >/dev/null 2>&1; do
  echo 'Waiting for db ... '
  sleep 1
done

# When creating databases and those databsaes are on a mounted volume and that volume is cifs based... 
# the mariadb image, presented with a non-empty data dir will create databases based on what it finds...
# The most obvious one is the lost+found dir, but also the secondary and possibly tertiary mounts that are 
# unused by the mariadb deployment.. they are called unused... Ideally we'd just start mysqld with --ignore-db-dirs... 
# but we don't want to circumvent all the good stuff that the mariadb image does.
# https://github.com/vmware/vic/issues/5777 tried some of this stuff, I suspect that the addition of terraform and 
# azurefile make it even more complex a fix than those suggested there, so we just remove them after the event
mysql -h mariadb -u root -p$MYSQL_ROOT_PASSWORD -e 'drop database `#mysql50#lost+found`;' >/dev/null 2>&1;


###################################################
# Finish configuration of eprints and initialise
###################################################

cd /opt/eprints3

if [ -f /opt/eprints3/archives/$APP_KEY/cfg/cfg.d/10_core_$ENVIRONMENT.pl ]; then
  echo -e "Update the ${bold}$ENVIRONMENT${normal} 10_core to add ${bold}$EXTERNAL_HOSTNAME${normal}"
  sed -i "s/changeme/$EXTERNAL_HOSTNAME/" /opt/eprints3/archives/$APP_KEY/cfg/cfg.d/10_core_$ENVIRONMENT.pl
fi


# TODO rather than leaving an init stub thinging, we could check mariadb:mysql for an $APP_KEY database that has an eprints table
# if there is one... we are initialized. This will mean we can re-init the database and the eprints container won't get confuddled by no DB
# or maybe the .initialized stub is the best way ?
if [[ ! $(mysqlshow -h mariadb -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE eprint) ]]; then 
  echo -e "-- ${bold}Initialising repo${normal} --"

  # We have some sql to import...
  if [ -f /var/tmp/migrate_$APP_KEY.sql ]; then
     echo "Importing database from /var/tmp/migrate_$APP_KEY.sql"
     #TODO see if we can run 'source /var/tmp/migrate_$APP_KEY.sql' to import the database
     mysql -h mariadb -u $MYSQL_USER -p$MYSQL_PASSWORD --default-character-set=utf8mb4 $MYSQL_DATABASE < /var/tmp/migrate_$APP_KEY.sql
     su eprints -s ./bin/epadmin update $APP_KEY
  else
     su eprints -s ./bin/epadmin create_tables $APP_KEY
     su eprints -s ./bin/epadmin update $APP_KEY
     echo -e "Creating user account for $ADMIN_USER..."
     su eprints -s ./bin/epadmin create_user $APP_KEY $ADMIN_USER admin $ADMIN_PASSWORD $ADMIN_EMAIL
  fi
  # We have some docs to import
  if [ -f /var/tmp/migrate_docs_$APP_KEY.tar.gz ]; then
     echo "Importing docs from /var/tmp/migrate_docs_$APP_KEY.tar.gz"
     tar xzf /var/tmp/migrate_docs_$APP_KEY.tar.gz -C /opt/eprints3/archives/$APP_KEY/documents/disk0
  fi

#  su eprints -s ./bin/epadmin update $APP_KEY
  # copy the default subjects if none in archives/$APP_KEY
  if [ ! -f ./archives/$APP_KEY/cfg/subjects ]; then
    su eprints -s /bin/cp ./lib/defaultcfg/subjects ./archives/$APP_KEY/cfg/subjects -- --force
  fi
  # And import subjects
  su eprints -s ./bin/import_subjects $APP_KEY ./archives/$APP_KEY/cfg/subjects -- --force
#  touch /data/.initialized
  printf "%-50s $print_ok \n" "Repo initialised";
else
  printf "%-50s $print_ok\n" "Repo already initialised" ;
fi

########################################
# Set up for non-production environments
########################################

if [ $ENVIRONMENT != "prod" ]; then

  ########################################
  # Set up environment labelling
  ########################################
  # Create js and css dirs here in case they are not already there 
  [ -d  ./archives/$APP_KEY/cfg/static/style/auto ] || mkdir -p ./archives/$APP_KEY/cfg/static/style/auto
  [ -d  ./archives/$APP_KEY/cfg/static/javascript/auto ] || mkdir -p ./archives/$APP_KEY/cfg/static/javascript/auto

  mv /var/tmp/zzz_env_ribbon.css ./archives/$APP_KEY/cfg/static/style/auto/
  mv /var/tmp/999_env_ribbon.js ./archives/$APP_KEY/cfg/static/javascript/auto/
  
  # READ environment labels from a file
  export $(egrep -v '^#' /var/tmp/environment_phrases | xargs)
  # Evaluate for the current environment
  eval $( echo environment_text=\$$ENVIRONMENT )
  # Insert into the environment ribbon js file
  sed -i "s/#ENVIRONMENT#/$ENVIRONMENT/g" ./archives/$APP_KEY/cfg/static/javascript/auto/999_env_ribbon.js
  sed -i "s/#ENVIRONMENT_TEXT#/$environment_text/g" ./archives/$APP_KEY/cfg/static/javascript/auto/999_env_ribbon.js

  ########################################
  # Turn off shibboleth authentication
  ########################################
  mv /var/tmp/z_no_shibb.pl ./archives/$APP_KEY/cfg/cfg.d/

fi

# Final test to make sure that all epm dependencies are present and all packages have been linked
for epm in $(ls archives/$APP_KEY/cfg/epm); do sudo -u eprints perl bin/epm_test.pl $APP_KEY $epm; done

####################################
# Generate static files and views
###################################

su eprints -s ./bin/generate_static $APP_KEY -- --quiet
su eprints -s ./bin/generate_views $APP_KEY -- --quiet

############################################################
# Conditionally start the indexer if not already running
###########################################################

if ! sudo -u eprints /opt/eprints3/bin/indexer status | grep PID; then sudo -u eprints /opt/eprints3/bin/indexer start; fi

#########################################
# Check/retore/auto-copy web-lang-files
########################################
for d in /opt/eprints3/archives/$APP_KEY/cfg/lang/* ; do
  [[ $d =~ ([a-z]+)$ ]]
  lang=${BASH_REMATCH[0]}
#  if [ -f /data/lang/$lang/zz_webcfg.xml ]; then
  if [ -f /opt/eprints3/archives/$APP_KEY/documents/disk0/lang/$lang/zz_webcfg.xml ]; then

    # Restore web editable phrase file to cfg/lang/*
#    cp /data/lang/$lang/zz_webcfg.xml /opt/eprints3/archives/$APP_KEY/cfg/lang/$lang/phrases/
    cp /opt/eprints3/archives/$APP_KEY/documents/disk0/lang/$lang/zz_webcfg.xml /opt/eprints3/archives/$APP_KEY/cfg/lang/$lang/phrases/
  else
    # Make a lang dir on the data volume
    mkdir -p /opt/eprints3/archives/$APP_KEY/documents/disk0/lang/$lang
  fi
  # Backup the web editable files from cfg/lang hourly (for each language)
  sudo -u eprints echo "*/60 * * * * cp -r /opt/eprints3/archives/$APP_KEY/cfg/lang/$lang/phrases/zz_webcfg.xml /opt/eprints3/archives/$APP_KEY/documents/disk0/lang/$lang/"  | sudo -u eprints crontab -
done

# Ensure correct ownership of phrase files
chown -R eprints:eprints /opt/eprints3/archives/$APP_KEY/cfg/lang/
# restart cron
service cron restart

#Include the apache:80 config (used only for letsencryp and redirecting to 433
if [[ ! $(grep "Include /usr/local/apache2/conf/apache_80.conf" /usr/local/apache2/conf/httpd.conf) ]]; then echo "Include /usr/local/apache2/conf/apache_80.conf" | tee -a /usr/local/apache2/conf/httpd.conf >/dev/null; fi

# For now $USE_SS_CERT will control whether or not to use a self-signed certificate or get one from letsencrypt
# letsenrypt won't work with IPs, or with domainnames without dots in then (eg localhost) or from behind a firewall even if we give the NSG the acme :@ (!!)
if [ $USE_SS_CERT ]; then
  echo -e "-- ${bold}Making self-signed certificates for local container ($EXTERNAL_HOSTNAME)${normal} --"
  /bin/gen_cert.sh $EXTERNAL_HOSTNAME
  if [ -f /etc/ssl/certs/$EXTERNAL_HOSTNAME.crt ]; then
    printf "%-50s $print_ok\n" "Certificates generated"
  else
    printf "%-50s $print_fail\n" "Certificates Could not be generated ($?)"
  fi
else
  echo -e "-- ${bold}Obtaining certificates from letsencrypt using certbot ($EXTERNAL_HOSTNAME)${normal} --"
  staging=""
  ## Maybe we want staging certs for dev instances? but they will use a FAKE CA and not really allow us to test stuff properly
  ## Perhaps when letsencrypt start issuing certs for IPs we should modify the above so that --staging is used with certbot when HOSTNAME_IS_IP?
  #[ $ENVIRONMENT == "dev" ] && staging="--staging"
 
  mkdir -p /var/www/acme-docroot

  # Correct cert on data volume in /data/pki/certs? We should be able to just bring apache up with ssl
  # If not...
  if [ ! -f /etc/ssl/certs/$EXTERNAL_HOSTNAME.crt ]; then
    # Lets encrypt has a cert but for some reason this has not been copied to where apache wants them
    if [ -f /etc/letsencrypt/live/base/fullchain.pem ]; then
      echo -e "Linking existing cert/key to /etc/ssl" 
      ln -s /etc/letsencrypt/live/base/fullchain.pem /etc/ssl/certs/$EXTERNAL_HOSTNAME.crt
      ln -s /etc/letsencrypt/live/base/privkey.pem /etc/ssl/private/$EXTERNAL_HOSTNAME.key
    else
      # No cert here, We'll register and get one and store all the gubbins on the letsecnrypt volume (n.b. this needs to be an azuredisk for symlink reasons)
#      /usr/local/bin/httpd-foreground
      echo -e "Starting apache on :80 and getting new cert and linking cert/key to /etc/ssl"
      /usr/local/apache2/bin/httpd -k start
      mkdir -p /var/www/acme-docroot/
      certbot certonly -n $staging --expand --webroot -w /var/www/acme-docroot/ --agree-tos --email $ADMIN_EMAIL --cert-name base -d $EXTERNAL_HOSTNAME
      # In case these are somehow hanging around to wreck the symlinking
      [ -f  /etc/ssl/certs/$EXTERNAL_HOSTNAME.crt ] && rm /etc/ssl/certs/$EXTERNAL_HOSTNAME.crt
      [ -f  /etc/ssl/private/$EXTERNAL_HOSTNAME.key ] && rm /etc/ssl/private/$EXTERNAL_HOSTNAME.key

      # Link cert and key to a location that our general apache config will know about
      if [ -f /etc/letsencrypt/live/base/fullchain.pem ]; then
        ln -s /etc/letsencrypt/live/base/fullchain.pem /etc/ssl/certs/$EXTERNAL_HOSTNAME.crt
        ln -s /etc/letsencrypt/live/base/privkey.pem /etc/ssl/private/$EXTERNAL_HOSTNAME.key
      else
        echo -e "${red}${bold}Certificate could not be obtained from letsencrypt using certbot!${normal}"
      fi

      #we have no need for this once the certificate is generated so let's stop it
      /usr/local/apache2/bin/httpd -k stop
    fi
    printf "%-50s $print_ok\n" "Certificate obtained"; # hmmm... catch an error maybe?
  else
     printf "%-50s $print_ok\n" "Certificate already in place";
  fi
  echo -e "-- ${bold}Setting up auto renewal${normal} --"
  # Remove this one as it is no good to us in this context
  rm /etc/cron.d/certbot
  # Add some evaluated variables 
  sed -i "s/#EXTERNAL_HOSTNAME#/$EXTERNAL_HOSTNAME/" /var/tmp/renew_cert
  sed -i "s/#ADMIN_EMAIL#/$ADMIN_EMAIL/" /var/tmp/renew_cert
  # copy renew_script into cron.monthly (whould be frequent enough)
  mv /var/tmp/renew_cert /etc/cron.monthly/renew_cert
  printf "%-50s $print_ok\n" "renew_cert script moved to /etc/cron.monthly";
fi

########################
# Update apache config
########################
echo -e "---- ${bold}Adjusting apache configuration${normal} ----"

# Generate the eprints apache conf
su eprints -s ./bin/generate_apacheconf -- --system --replace --quiet

# Only adjust apache conf if not done so already. Avoid this being done twice if container is downed then upped but not built.
if [[ ! $(grep "Include /opt/eprints3/cfg/apache.conf" /usr/local/apache2/conf/httpd.conf) ]]; then echo "Include /opt/eprints3/cfg/apache.conf" | tee -a /usr/local/apache2/conf/httpd.conf >/dev/null; fi
if [[ ! $(grep "Include /usr/local/apache2/conf/eprints-ssl.conf" /usr/local/apache2/conf/httpd.conf) ]]; then echo "Include /usr/local/apache2/conf/eprints-ssl.conf" | tee -a /usr/local/apache2/conf/httpd.conf >/dev/null; fi
if [[ ! $(grep "ErrorLog /usr/local/apache2/logs/error.log" /usr/local/apache2/conf/httpd.conf) ]]; then echo "ErrorLog /usr/local/apache2/logs/error.log" | tee -a /usr/local/apache2/conf/httpd.conf >/dev/null; fi

# Check that EPrints apache.conf is in the httpd.conf (this is pretty important for EPrints
if [[ $(grep "Include /opt/eprints3/cfg/apache.conf" /usr/local/apache2/conf/httpd.conf) ]]; then 
  printf "%-50s $print_ok\n" "EPrints apahe.conf included in httpd.conf"
else
  printf "%-50s $print_fail\n" "EPrints apahe.conf NOT included in httpd.conf"
fi

# Start apache as recomended by the httpd image README
echo -e "---- ${bold}Starting apache${normal} ----"
APACHE_RESTART=`/usr/local/bin/httpd-foreground`
if [ "$?" -ne "0" ]; then
  printf "%-50s $print_fail\n" "Apache not started";
  echo -e "### ${bold}There was an issue starting apache. We have kept this container alive for you to go and see what's up...${normal} ###"
  tail -f /dev/null
else
  printf "%-50s $print_ok\n" "Apache started";
fi
