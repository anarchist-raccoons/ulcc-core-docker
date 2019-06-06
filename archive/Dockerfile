# Use an multi-stage build to setup ssh
#   copy the key and config to enable git clone
#   @todo Docker 18.9 provides an improved mechanism: https://docs.docker.com/develop/develop-images/build_enhancements/#using-ssh-to-access-private-data-in-builds
FROM researchtech/ulcc-core:alpha as intermediate

ARG APP_WORKDIR=/opt/eprints3/archives
ARG APP_KEY
ARG APP_SOURCE
ARG SSH_PRIVATE_KEY_PATH
ARG EPUSER=eprints

USER root

RUN mkdir /root/.ssh/

ADD docker/ssh_config /root/.ssh/config
RUN chmod 400 /root/.ssh/config 

ADD ${SSH_PRIVATE_KEY_PATH} /root/.ssh/id_rsa
RUN chmod -R 600 /root/.ssh/

# RUN git clone git@$APP_SOURCE/$APP_KEY.git $APP_WORKDIR/archives/$APP_KEY
RUN echo "GEM_KEY is set, cloning $APP_SOURCE/$APP_KEY.git";
RUN git clone git@github.com:anarchist-raccoons/ulcc-core-docker.git $APP_WORKDIR/$APP_KEY

RUN chown -R $EPUSER:$EPUSER $APP_WORKDIR
USER $EPUSER

FROM researchtech/ulcc-core:alpha

ARG APP_WORKDIR=/opt/eprints3/archives
ARG APP_KEY
ARG EPUSER=eprints

WORKDIR $APP_WORKDIR
# Copy from intermdiate
COPY --from=intermediate $APP_WORKDIR $APP_WORKDIR


# Continue build ...

# Insert into httpd.conf
# RUN echo "Include /opt/eprints3/cfg/apache.conf" | tee -a /usr/local/apache2/conf/httpd.conf >/dev/null