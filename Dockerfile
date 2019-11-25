FROM php:5.6.26-fpm-alpine


COPY conf/php.ini /usr/local/etc/php/php.ini
COPY conf/www.conf /usr/local/etc/php/www.conf

RUN apk add --update git make gcc g++ imagemagick-dev \
 	libc-dev \
	autoconf \
	icu-dev \
	openldap-dev \
	freetype-dev \
	libjpeg-turbo-dev \
	libpng-dev \
	libxml2-dev \
	libmcrypt-dev \
	libpcre32 \
	bzip2 \
	libbz2 \
	bzip2-dev \
	libmemcached-dev \
	cyrus-sasl-dev \
	rabbitmq-c \
        rabbitmq-c-dev \
	binutils \
	imagemagick-dev \
	&& rm -rf /var/cache/apk/*

#RUN apk add --no-cache --repository http://dl-3.alpinelinux.org/alpine/edge/testing gnu-libiconv
ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php

RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
        && docker-php-ext-install gd \
        && docker-php-ext-install mysqli \
        && docker-php-ext-install bz2 \
        && docker-php-ext-install zip \
        && docker-php-ext-install pdo \
        && docker-php-ext-install pdo_mysql \
        && docker-php-ext-install opcache \
		&& docker-php-ext-install ldap \
		&& docker-php-ext-install sockets \
		&& docker-php-ext-install sysvmsg \
    	&& docker-php-ext-install sysvsem \
    	&& docker-php-ext-install sysvshm \
		&& docker-php-ext-install bcmath \
		&& docker-php-ext-install pcntl \
		&& docker-php-ext-install soap \
		&& docker-php-ext-install sockets \
		&& docker-php-ext-install shmop \
		&& docker-php-ext-install sysvmsg \
		&& docker-php-ext-install sysvsem \
		&& docker-php-ext-install sysvshm \
		&& echo "extension=memcached.so" > /usr/local/etc/php/conf.d/memcached.ini \
		&& echo "extension=redis.so" > /usr/local/etc/php/conf.d/phpredis.ini \
		&& echo "extension=phalcon.so" > /usr/local/etc/php/conf.d/phalcon.ini \
		&& echo "extension=igbinary.so" > /usr/local/etc/php/conf.d/igbinary.ini \
		&& echo "extension=zookeeper.so" > /usr/local/etc/php/conf.d/zookeeper.ini


WORKDIR /usr/src/php/ext/

RUN pecl install https://pecl.php.net/get/swoole-4.2.13.tgz \
	&& pecl install amqp 1.9.4 \
	&& pecl install imagick 3.4.3 \
	&& pecl install redis 4.2.0 \
	&& pecl install memcached 3.1.3 \
	&& pecl install mongodb  1.5.3 \
	&& pecl install igbinary 2.0.8 \
	&& pecl install yaf 3.0.7 \
	&& pecl install xdebug && docker-php-ext-enable xdebug \
	&& pecl install apcu 1.0.4 \
	&& pecl install inotify 2.0.0 \
	&& pecl install grpc

# Compile Phalcon
ENV PHALCON_VERSION=3.4.1
RUN set -xe && \
    curl -LO https://github.com/phalcon/cphalcon/archive/v${PHALCON_VERSION}.tar.gz && \
    tar xzf v${PHALCON_VERSION}.tar.gz && cd cphalcon-${PHALCON_VERSION}/build && sh install

ENV YAC_VERSION=2.0.2
RUN set -xe && \
	curl -LO https://github.com/laruence/yac/archive/yac-${YAC_VERSION}.tar.gz && \
	tar xzf yac-${YAC_VERSION}.tar.gz && cd yac-yac-${YAC_VERSION} && \
	phpize && ./configure --with-php-config=/usr/local/bin/php-config && make && make install

ENV ZOOKEEPER_VERSION=3.4.9
RUN wget https://archive.apache.org/dist/zookeeper/zookeeper-${ZOOKEEPER_VERSION}/zookeeper-${ZOOKEEPER_VERSION}.tar.gz && \
   tar -zxf zookeeper-${ZOOKEEPER_VERSION}.tar.gz && cd zookeeper-${ZOOKEEPER_VERSION}/src/c && \
   ./configure --prefix=/usr/local/zookeeper-${ZOOKEEPER_VERSION}/ && make && make install

ENV PHP_ZOOKEEPER_VERSION=0.2.2
RUN wget http://pecl.php.net/get/zookeeper-${PHP_ZOOKEEPER_VERSION}.tgz && \
   tar -zxvf zookeeper-${PHP_ZOOKEEPER_VERSION}.tgz && cd zookeeper-${PHP_ZOOKEEPER_VERSION} && phpize && ./configure --with-php-config=/usr/local/bin/php-config --with-libzookeeper-dir=/usr/local/zookeeper-${ZOOKEEPER_VERSION}/ && make && make install && \
    echo "extension=zookeeper.so" > /usr/local/etc/php/conf.d/zookeeper.ini


FROM php:5.6.26-fpm-alpine

LABEL maintainer="zhanlong.liu@icloud.com"

RUN apk add --update --no-cache \
    git \
	libc-dev \
	icu-dev \
	libxml2-dev \
	openldap-dev \
	freetype-dev \
	libjpeg-turbo-dev \
	libpng-dev \
	libmcrypt-dev \
	bzip2 \
	libbz2 \
	bzip2-dev \
	libmemcached-dev \
	cyrus-sasl-dev \
	rabbitmq-c \
    rabbitmq-c-dev \
	imagemagick-dev \
	nodejs \
	nodejs-npm \
	&& rm -rf /var/cache/apk/*
	
#RUN apk add --no-cache --repository http://dl-3.alpinelinux.org/alpine/edge/testing gnu-libiconv
ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php

COPY --from=0 /usr/local/lib/php/extensions/no-debug-non-zts-20170718/* /usr/local/lib/php/extensions/no-debug-non-zts-20170718/
COPY docker-entrypoint.sh /usr/local/bin/
ADD conf/php.ini /usr/local/etc/php/php.ini
ADD conf/www.conf /usr/local/etc/php-fpm.d/www.conf
ADD conf/yaf.ini /usr/local/etc/php/conf.d/yaf.ini
ADD conf/xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini


RUN chmod +x /usr/local/bin/docker-entrypoint.sh

RUN echo "extension=ldap.so" > /usr/local/etc/php/conf.d/ldap.ini \
		&& echo "extension=swoole.so" > /usr/local/etc/php/conf.d/swoole.ini \
		&& echo "extension=apcu.so" > /usr/local/etc/php/conf.d/apcu.ini \
		&& echo "extension=gd.so" > /usr/local/etc/php/conf.d/gd.ini \
		&& echo "extension=mysqli.so" > /usr/local/etc/php/conf.d/mysqli.ini \
		&& echo "extension=bz2.so" > /usr/local/etc/php/conf.d/bz2.ini \
		&& echo "extension=zip.so" > /usr/local/etc/php/conf.d/zip.ini \
		&& echo "extension=memcached.so" > /usr/local/etc/php/conf.d/memcached.ini \
		&& echo "extension=redis.so" > /usr/local/etc/php/conf.d/phpredis.ini \
		&& echo "extension=phalcon.so" > /usr/local/etc/php/conf.d/phalcon.ini \
		&& echo "extension=igbinary.so" > /usr/local/etc/php/conf.d/igbinary.ini \
		&& echo "extension=mongodb.so" > /usr/local/etc/php/conf.d/mongodb.ini \
		&& echo "extension=bcmath.so" > /usr/local/etc/php/conf.d/bcmath.ini \
		&& echo "extension=pdo_mysql.so" > /usr/local/etc/php/conf.d/pdo_mysql.ini \
		&& echo "extension=amqp.so" > /usr/local/etc/php/conf.d/amqp.ini \
		&& echo "extension=imagick.so" > /usr/local/etc/php/conf.d/imagick.ini \
		&& echo "extension=sockets.so" > /usr/local/etc/php/conf.d/sockets.ini \
		&& echo "extension=sysvmsg.so" > /usr/local/etc/php/conf.d/sysvmsg.ini \
		&& echo "extension=sysvshm.so" > /usr/local/etc/php/conf.d/sysvshm.ini \
		&& echo "extension=zookeeper.so" > /usr/local/etc/php/conf.d/zookeeper.ini \
		&& echo "extension=grpc.so" > /usr/local/etc/php/conf.d/grpc.ini 
ADD conf/yac.ini /usr/local/etc/php/conf.d/yac.ini

RUN cd /tmp \
    && curl -sS https://getcomposer.org/installer | /usr/local/bin/php \
    && chmod +x composer.phar \
    && mv composer.phar /usr/local/bin/composer

RUN npm install -g nodemon

WORKDIR /mnt/hgfs/

EXPOSE 9501

CMD ["/usr/local/bin/docker-entrypoint.sh"]
