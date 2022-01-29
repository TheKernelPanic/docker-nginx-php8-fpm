FROM ubuntu:20.04

ENV APPLICATION_DIRECTORY="work-directory"
ENV TIMEZONE="UTC"

RUN apt update && \
    apt install nginx nano -y

RUN mkdir /var/www/$APPLICATION_DIRECTORY

# ADD PPA FOR PHP8
RUN apt install software-properties-common -y && \
    add-apt-repository ppa:ondrej/php && \
    apt update

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TIMEZONE > /etc/timezone

# PHP INSTALLATION
ENV PHP_VERSION=8.0
RUN apt install php$PHP_VERSION -y
RUN apt install php$PHP_VERSION-fpm -y
RUN apt install php$PHP_VERSION-common php$PHP_VERSION-mysql php$PHP_VERSION-xml php$PHP_VERSION-curl php$PHP_VERSION-gd php$PHP_VERSION-imagick php$PHP_VERSION-cli php$PHP_VERSION-dev php$PHP_VERSION-imap php$PHP_VERSION-mbstring php$PHP_VERSION-opcache php$PHP_VERSION-soap php$PHP_VERSION-zip php$PHP_VERSION-pgsql php$PHP_VERSION-xdebug php$PHP_VERSION-redis -y

# PHP CONFIGURATION
RUN sed -i "/^;date.timezone/c\date.timezone = \"$TIMEZONE\"" /etc/php/$PHP_VERSION/cli/php.ini && \
    sed -i "/^;date.timezone/c\date.timezone = \"$TIMEZONE\"" /etc/php/$PHP_VERSION/fpm/php.ini && \
    sed -i '/^max_file_uploads = 20/c\max_file_uploads = 50' /etc/php/$PHP_VERSION/fpm/php.ini && \
    sed -i '/^display_errors = Off/c\display_errors = On' /etc/php/$PHP_VERSION/fpm/php.ini && \
    sed -i '/^default_socket_timeout = 60/c\default_socket_timeout = -1' /etc/php/$PHP_VERSION/cli/php.ini && \
    sed -i '/^post_max_size = 8M/c\post_max_size = 150M' /etc/php/$PHP_VERSION/fpm/php.ini && \
    sed -i '/^upload_max_filesize = 2M/c\upload_max_filesize = 150M' /etc/php/$PHP_VERSION/fpm/php.ini

# XDEBUG CONFIGURATION
RUN echo "xdebug.remote_autostart = 1" >> /etc/php/$PHP_VERSION/mods-available/xdebug.ini && \
    echo "xdebug.remote_enable = 1" >> /etc/php/$PHP_VERSION/mods-available/xdebug.ini && \
    echo "xdebug.remote_host = 127.0.0.1" >> /etc/php/$PHP_VERSION/mods-available/xdebug.ini && \
    echo "xdebug.remote_log = /tmp/xdebug_remote.log" >> /etc/php/$PHP_VERSION/mods-available/xdebug.ini && \
    echo "xdebug.remote_port = 9001" >> /etc/php/$PHP_VERSION/mods-available/xdebug.ini

# INSTALL COMPOSER
RUN cd ~ && \
    curl -sS https://getcomposer.org/installer -o composer-setup.php && \
    HASH=`curl -sS https://composer.github.io/installer.sig` && \
    php -r "if (hash_file('SHA384', 'composer-setup.php') === '$HASH') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" && \
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer

# NGINX CONFIGURATION
RUN rm /etc/nginx/sites-available/default
COPY nginx_config /etc/nginx/sites-available/default

# INSTALL FFMPEG
RUN apt-get install ffmpeg -y

WORKDIR /var/www/$APPLICATION_DIRECTORY

VOLUME /var/www/$APPLICATION_DIRECTORY

EXPOSE 80 9001 9000

CMD service nginx start && service php8.0-fpm start && /bin/bash
