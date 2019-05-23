FROM httpd:2.4

RUN apt-get update

# mysql-server mysql-client

# Install all the things
RUN apt-get update -qq \
  && apt-get install -y git vim \
  perl libncurses5 libselinux1 libsepol1 apache2 libapache2-mod-perl2 libxml-libxml-perl libunicode-string-perl \
  libterm-readkey-perl libmime-lite-perl libmime-types-perl libdigest-sha-perl libdbd-mysql-perl libxml-parser-perl libxml2-dev \
  libxml-twig-perl libarchive-any-perl libjson-perl lynx wget ghostscript xpdf antiword elinks texlive-base texlive-base-bin \
  psutils imagemagick adduser tar gzip unzip libsearch-xapian-perl libtex-encode-perl

# Setup build variables
ARG APP_WORKDIR
ARG BRANCH
ARG EPRINTS_USER

# should we provide a password
RUN adduser --disabled-password --gecos "" $EPRINTS_USER
RUN usermod -aG sudo eprints
RUN echo -e "\nexport APACHE_RUN_USER=eprints\nexport APACHE_RUN_GROUP=eprints" >> /etc/apache2/envvars

RUN git clone https://github.com/eprintsug/ulcc-core.git $APP_WORKDIR

RUN chown -R eprints $APP_WORKDIR
USER $EPRINTS_USER
WORKDIR $APP_WORKDIR

RUN git checkout $BRANCH
RUN git submodule update --init

# SystemSettings.pm
# apache setup stuff

# Add the entrypoint file
COPY docker/docker-entrypoint.sh /bin/
RUN chmod +x /bin/docker-entrypoint.sh