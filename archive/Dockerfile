# Use a multi-stage build to setup ssh
#   copy the key and config to enable git clone
#   @todo Docker 18.9 provides an improved mechanism: https://docs.docker.com/develop/develop-images/build_enhancements/#using-ssh-to-access-private-data-in-builds

# Build the intermediate image
FROM researchtech/ulcc-core:alpha as intermediate

ARG APP_WORKDIR=/opt/eprints3
ARG EPUSER=eprints
ARG APP_KEY
ARG APP_SOURCE
ARG SSH_PRIVATE_KEY_PATH

RUN mkdir /root/.ssh/

ADD docker/ssh_config /root/.ssh/config
RUN chmod 400 /root/.ssh/config 

ADD ${SSH_PRIVATE_KEY_PATH} /root/.ssh/id_rsa
RUN chmod -R 600 /root/.ssh/

RUN git clone git@$APP_SOURCE/$APP_KEY.git $APP_WORKDIR/archives/$APP_KEY

# Build the image proper
FROM researchtech/ulcc-core:alpha

ARG APP_WORKDIR=/opt/eprints3
ARG EPUSER=eprints
ARG APP_KEY
ARG EXTERNAL_HOSTNAME

WORKDIR $APP_WORKDIR

COPY --from=intermediate $APP_WORKDIR/archives $APP_WORKDIR/archives

COPY docker/docker-entrypoint.sh /bin/
RUN chmod +x /bin/docker-entrypoint.sh

RUN chown -R $EPUSER:$EPUSER $APP_WORKDIR
USER $EPUSER
RUN tools/epm link_lib meprints
RUN tools/epm link_lib reports

RUN for epm in $(ls archives/$APP_KEY/cfg/epm); do tools/epm link_lib $epm; done

RUN sed -i 's/localhost/mariadb/' $APP_WORKDIR/archives/$APP_KEY/cfg/cfg.d/database.pl
RUN sed -i 's/MyISAM/InnoDB/' $APP_WORKDIR/archives/$APP_KEY/cfg/cfg.d/database.pl

COPY docker/10_core.pl $APP_WORKDIR/archives/$APP_KEY/cfg/cfg.d/10_core_$APP_KEY.pl

USER root