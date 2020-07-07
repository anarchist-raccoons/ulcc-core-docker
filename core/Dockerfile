FROM httpd:2.4

RUN apt-get update

#    libxml-libxslt-perl \ Makes apache seg fault!!!

# Install all the things
RUN apt-get update -qq \
  && apt-get install -y \
   adduser \
   antiword \
   certbot \ 
   cron \
   elinks \
   ghostscript \
   git \
   gzip \
   imagemagick \
   less \
   libapache2-mod-perl2 \
   libarchive-any-perl \
   libcgi-pm-perl \
   libdate-calc-perl \
   libdbd-mysql-perl \
   libdevel-cycle-perl \
   libdevel-size-perl \
   libdigest-sha-perl \
   libjson-perl \
   libmediawiki-api-perl \
   libmime-lite-perl \
   libmime-types-perl \
   libncurses5 \
   libnet-ldap-perl \
   libpod-coverage-perl \
   libsearch-xapian-perl \
   libselinux1 \
   libsepol1 \
   libterm-readkey-perl \
   libtex-encode-perl \
   libtext-markdown-perl \
   libtext-unidecode-perl \
   libunicode-string-perl \
   liburi-perl \
   libxml-libxml-perl \
   libxml-parser-perl \
   libxml-twig-perl \
   libxml2-dev \
   lynx \
   mariadb-client \
   net-tools \
   perl \
   psutils \
   python-certbot-apache \
   rsyslog \
   sudo \
   tar \
   texlive-base \
   texlive-base-bin \
   tree \
   unzip \
   vim \
   wget \
   xpdf

# Setup build variables
ARG APP_WORKDIR=/opt/eprints3
ARG BRANCH
ARG EPUSER=eprints

# Create the $APACHE_RUN_USER
RUN adduser --disabled-password --gecos "" $EPUSER

# Clone the application
RUN git clone https://github.com/eprintsug/ulcc-core.git $APP_WORKDIR
COPY ./docker/SystemSettings.pm $APP_WORKDIR/perl_lib/EPrints/SystemSettings.pm

# Load required modules
RUN echo "LoadModule perl_module /usr/lib/apache2/modules/mod_perl.so" | tee -a /usr/local/apache2/conf/httpd.conf >/dev/null

# Change ownership of application and apache2 directories
RUN chown -R $EPUSER:$EPUSER $APP_WORKDIR

WORKDIR $APP_WORKDIR

RUN git checkout $BRANCH
RUN git submodule update --init
