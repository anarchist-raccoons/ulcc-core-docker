FROM httpd:2.4

RUN apt-get update

# Install all the things
RUN apt-get update -qq \
  && apt-get install -y git vim \
  perl libncurses5 libselinux1 libsepol1 apache2 libapache2-mod-perl2 libxml-libxml-perl libunicode-string-perl \
  libterm-readkey-perl libmime-lite-perl libmime-types-perl libdigest-sha-perl libdbd-mysql-perl libxml-parser-perl libxml2-dev \
  libxml-twig-perl libarchive-any-perl libjson-perl lynx wget ghostscript xpdf antiword elinks texlive-base texlive-base-bin \
  psutils imagemagick adduser tar gzip unzip libsearch-xapian-perl libtex-encode-perl libcgi-pm-perl liburi-perl
  # mysql-server mysql-client

# Add the entrypoint file - @todo, remove if we don't need this
COPY docker/docker-entrypoint.sh /bin/
RUN chmod +x /bin/docker-entrypoint.sh

# Setup build variables
ARG APP_WORKDIR
ARG BRANCH
ARG APACHE_RUN_USER
ARG APACHE_RUN_GROUP

# Create the $APACHE_RUN_USER
RUN adduser --disabled-password --gecos "" $APACHE_RUN_USER

# Set the envvars
RUN echo "export APACHE_RUN_USER=$APACHE_RUN_USER" | tee -a /usr/local/apache2/bin/envvars >/dev/null
RUN echo "export APACHE_RUN_GROUP=$APACHE_RUN_GROUP" | tee -a /usr/local/apache2/bin/envvars >/dev/null

# Configure
# Run on port 8080 - TEMP, we'll probably replace this file with a custom one and run on https
RUN sed -i -E 's/Listen 80+$/Listen 8080/g' /usr/local/apache2/conf/httpd.conf
COPY ./docker/eprints.conf /usr/local/apache2/conf/

# Clone the application
RUN git clone https://github.com/eprintsug/ulcc-core.git $APP_WORKDIR
COPY ./docker/SystemSettings.pm $APP_WORKDIR/perl_lib/EPrints/SystemSettings.pm

# Change ownership of application and apache2 directories
RUN chown -R $APACHE_RUN_USER:$APACHE_RUN_GROUP $APP_WORKDIR
RUN chown -R $APACHE_RUN_USER:$APACHE_RUN_GROUP /usr/local/apache2

USER $APACHE_RUN_USER
WORKDIR $APP_WORKDIR

RUN git checkout $BRANCH
RUN git submodule update --init