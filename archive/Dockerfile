# Use a multi-stage build to setup ssh
#   copy the key and config to enable git clone
#   @todo Docker 18.9 provides an improved mechanism: https://docs.docker.com/develop/develop-images/build_enhancements/#using-ssh-to-access-private-data-in-builds

# Build the intermediate image
FROM researchtech/ulcc-core:alpha as intermediate
# Switch this in for the line above to test a local core build
#FROM core_ulcccore:latest as intermediate

ARG APP_WORKDIR=/opt/eprints3
ARG EPUSER=eprints
ARG APP_KEY
ARG APP_SOURCE
ARG SSH_PRIVATE_KEY_PATH
ARG EXTERNAL_HOSTNAME

RUN mkdir /root/.ssh/

ADD docker/ssh_config /root/.ssh/config
RUN chmod 400 /root/.ssh/config 

ADD ${SSH_PRIVATE_KEY_PATH} /root/.ssh/id_rsa
RUN chmod -R 600 /root/.ssh/

RUN git clone git@$APP_SOURCE/$APP_KEY.git $APP_WORKDIR/archives/$APP_KEY

# Build the image proper
FROM researchtech/ulcc-core:alpha
# Switch this in for the line above to test a local core build
#FROM core_ulcccore:latest

ARG APP_WORKDIR=/opt/eprints3
ARG EPUSER=eprints
ARG APP_KEY
ARG ADMIN_EMAIL
ARG ADMIN_USER
ARG ADMIN_PASSWORD
ARG EXTERNAL_HOSTNAME
ARG ENVIRONMENT

WORKDIR $APP_WORKDIR

COPY --from=intermediate $APP_WORKDIR/archives $APP_WORKDIR/archives

# Turn on cron logging
RUN sed -i "s/^#cron/cron/" /etc/rsyslog.conf

# Copy ssl conf into place
COPY docker/eprints-ssl.conf /usr/local/apache2/conf/

# Change the apache User and Group to eprints
RUN sed -i "s/User daemon/User $EPUSER/" /usr/local/apache2/conf/httpd.conf
RUN sed -i "s/Group daemon/Group $EPUSER/" /usr/local/apache2/conf/httpd.conf
# Change to ServerName in main http.donf (this is mainly just to make the apache moan go away)
RUN sed -i "s/#ServerName .*/ServerName $EXTERNAL_HOSTNAME/" /usr/local/apache2/conf/httpd.conf

# Change to all instances of #EXTERNAL_HOSTNAME# in eprints-ssl.conf to whatever the $EXTERNAL_HOSTNAME is... etc etc
RUN sed -i "s/#EXTERNAL_HOSTNAME#/$EXTERNAL_HOSTNAME/" /usr/local/apache2/conf/eprints-ssl.conf
RUN sed -i "s/#ADMIN_EMAIL#/$ADMIN_EMAIL/" /usr/local/apache2/conf/eprints-ssl.conf
RUN sed -i "s/#APP_KEY#/$APP_KEY/g" /usr/local/apache2/conf/eprints-ssl.conf
RUN sed -i "s/#APP_KEY_ENV#/$APP_KEY-$ENVIRONMENT/g" /usr/local/apache2/conf/eprints-ssl.conf


# We will control the apachevhost.conf for all EPrints as this is the only way to get things sensibly into the :80 vhost
# It will include an Include for site-specific apache config too
COPY docker/apachevhost.conf archives/$APP_KEY/cfg/apachevhost.conf
RUN sed -i "s/#APP_KEY#/$APP_KEY/g" archives/$APP_KEY/cfg/apachevhost.conf
RUN sed -i "s/#APP_KEY_ENV#/$APP_KEY-$ENVIRONMENT/g" archives/$APP_KEY/cfg/apachevhost.conf

# This is used if we are not in production to show which environment we are in
COPY docker/environment_phrases /var/tmp/
COPY docker/999_env_ribbon.js /var/tmp/
COPY docker/zzz_env_ribbon.css /var/tmp/

# Copy helper scripts in to place
COPY docker/docker-entrypoint.sh /bin/
RUN chmod +x /bin/docker-entrypoint.sh

COPY docker/gen_cert.sh /bin/
RUN chmod +x /bin/gen_cert.sh

COPY docker/report_on_requirements /bin/
RUN chmod +x /bin/report_on_requirements

COPY docker/a2enmod /bin/
RUN chmod +x /bin/a2enmod

# For later use by certbot/cron
COPY docker/renew_cert /var/tmp/
RUN chmod +x /var/tmp/renew_cert

# Enable apache modules (with homemade a2enmod)
RUN /bin/a2enmod ssl_module
RUN /bin/a2enmod socache_shmcb_module
RUN /bin/a2enmod rewrite_module

# Report on whether the current set of ulcc-core eprints requirements are met (should be by this stage)
RUN /bin/report_on_requirements

RUN chown -R $EPUSER:$EPUSER $APP_WORKDIR

USER $EPUSER
RUN tools/epm link_lib meprints --quiet
RUN tools/epm link_lib reports --quiet

RUN for epm in $(ls archives/$APP_KEY/cfg/epm); do tools/epm link_lib --quiet $epm; done

RUN sed -i 's/localhost/mariadb/' $APP_WORKDIR/archives/$APP_KEY/cfg/cfg.d/database.pl
RUN sed -i 's/MyISAM/InnoDB/' $APP_WORKDIR/archives/$APP_KEY/cfg/cfg.d/database.pl

# Copy in the 10_core.pl template so we can override config for non-production environments
COPY docker/10_core.pl $APP_WORKDIR/archives/$APP_KEY/cfg/cfg.d/10_core_$ENVIRONMENT.pl
# If the environment is production we will prefer the original 10_core.pl from the customer git repository
RUN if [ "$ENVIRONMENT" = "prod" ]; then rm $APP_WORKDIR/archives/$APP_KEY/cfg/cfg.d/10_core_$ENVIRONMENT.pl ; fi


USER root
