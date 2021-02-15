FROM ubuntu:20.04

ENV APPLICATION_DIRECTORY="work-directory"

RUN apt update && \
    apt install nginx nano -y

RUN mkdir /var/www/$APPLICATION_DIRECTORY

# ADD PPA FOR PHP8
RUN apt install software-properties-common -y && \
    add-apt-repository ppa:ondrej/php && \
    apt update

ENV TZ=Europe/Madrid
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# PHP INSTALLATION
ENV PHP_VERSION=8.0
RUN apt install php8.0 -y
RUN apt install php8.0-fpm -y
RUN apt install php8.0-common php8.0-mysql php8.0-xml php8.0-curl php8.0-gd php8.0-imagick php8.0-cli php8.0-dev php8.0-imap php8.0-mbstring php8.0-opcache php8.0-soap php8.0-zip php8.0-pgsql php8.0-xdebug php8.0-redis -y

# PHP CONFIGURATION
RUN sed -i '/^;date.timezone/c\date.timezone = "Europe/Madrid"' /etc/php/8.0/cli/php.ini && \
    sed -i '/^;date.timezone/c\date.timezone = "Europe/Madrid"' /etc/php/8.0/fpm/php.ini && \
    sed -i '/^max_file_uploads = 20/c\max_file_uploads = 50' /etc/php/8.0/fpm/php.ini && \
    sed -i '/^display_errors = Off/c\display_errors = On' /etc/php/8.0/fpm/php.ini && \
    sed -i '/^default_socket_timeout = 60/c\default_socket_timeout = -1' /etc/php/8.0/cli/php.ini && \
    sed -i '/^post_max_size = 8M/c\post_max_size = 150M' /etc/php/8.0/fpm/php.ini && \
    sed -i '/^upload_max_filesize = 2M/c\upload_max_filesize = 150M' /etc/php/8.0/fpm/php.ini

# XDEBUG CONFIGURATION
RUN echo "xdebug.remote_autostart = 1" >> /etc/php/8.0/mods-available/xdebug.ini && \
    echo "xdebug.remote_enable = 1" >> /etc/php/8.0/mods-available/xdebug.ini && \
    echo "xdebug.remote_host = 127.0.0.1" >> /etc/php/8.0/mods-available/xdebug.ini && \
    echo "xdebug.remote_log = /tmp/xdebug_remote.log" >> /etc/php/8.0/mods-available/xdebug.ini && \
    echo "xdebug.remote_port = 9001" >> /etc/php/8.0/mods-available/xdebug.ini

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
