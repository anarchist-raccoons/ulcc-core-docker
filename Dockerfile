FROM httpd:2.4

RUN apt-get update

# Install all the things
RUN apt-get install -y git vim build-essential autoconf automake libtool gdb
RUN cpan App::cpanminus
# MM LIST:
#   perl-URI perl-libwww-perl perl-CGI-Session perl-XML-Parser perl-Crypt-SSLeay perl-Unicode-String perl-Date-Calc perl-XML-LibXML perl-Time-Piece perl-BSD-Resource perl-Business-ISBN perl-Business-ISBN-Data perl-CGI perl-CPAN perl-Carp perl-Class-Load perl-Class-MethodMaker perl-Class-Singleton perl-Compress-Raw-Bzip2 perl-Compress-Raw-Zlib perl-Crypt-SSLeay perl-DBD-MySQL perl-DBI perl-Data-Dumper perl-Data-OptList perl-DateTime perl-DateTime-Locale perl-DateTime-TimeZone perl-Digest perl-Digest-MD5 perl-Digest-SHA perl-Encode perl-Encode-Locale perl-Error perl-Exporter perl-ExtUtils-Install perl-ExtUtils-MakeMaker perl-ExtUtils-Manifest perl-ExtUtils-ParseXS perl-FCGI perl-File-Listing perl-File-Path perl-File-Temp perl-Filter perl-Getopt-Long perl-Git perl-HTML-Parser perl-HTML-Tagset perl-HTTP-Cookies perl-HTTP-Daemon perl-HTTP-Date perl-HTTP-Message perl-HTTP-Negotiate perl-HTTP-Tiny perl-IO-Compress perl-IO-HTML perl-IO-Socket-IP perl-IO-Socket-SSL perl-LWP-MediaTypes perl-Linux-Pid perl-List-MoreUtils perl-Module-Implementation perl-Module-Runtime perl-Net-Daemon perl-Net-HTTP perl-Net-LibIDN perl-Net-SSLeay perl-Package-DeprecationManager perl-Package-Stash perl-Package-Stash-XS perl-Params-Util perl-Params-Validate perl-PathTools perl-PlRPC perl-Pod-Escapes perl-Pod-Perldoc perl-Pod-Simple perl-Pod-Usage perl-Scalar-List-Utils perl-Socket perl-Storable perl-Sub-Install perl-TermReadKey perl-Test-Harness perl-Text-CSV_XS perl-Text-ParseWords perl-Text-Template perl-Thread-Queue perl-Time-HiRes perl-Time-Local perl-Time-Piece perl-TimeDate perl-Try-Tiny perl-URI perl-Unicode-String perl-WWW-RobotRules perl-XML-Parser perl-constant perl-devel perl-libs perl-libwww-perl perl-local-lib perl-macros perl-parent perl-podlators perl-srpm-macros perl-threads perl-threads-shared
RUN cpanm URI LWP 

# Setup build variables
ARG APP_WORKDIR
ARG BRANCH

RUN git clone https://github.com/eprintsug/ulcc-core.git $APP_WORKDIR

WORKDIR $APP_WORKDIR

RUN git checkout $BRANCH
RUN git submodule init
RUN git submodule update

# SystemSettings.pm
# apache setup stuff

# Add the entrypoint file
COPY docker/docker-entrypoint.sh /bin/
RUN chmod +x /bin/docker-entrypoint.sh