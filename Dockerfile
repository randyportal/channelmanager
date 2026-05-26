FROM php:5.6-apache

# 1. TRUCO PARA REPOSITORIOS DEBIAN OBSOLETOS (Jessie)
RUN echo "Acquire::Check-Valid-Until \"false\";" > /etc/apt/apt.conf.d/99no-check-valid-until \
    && echo "deb http://archive.debian.org/debian/ jessie main" > /etc/apt/sources.list \
    && echo "deb http://archive.debian.org/debian-security jessie/updates main" >> /etc/apt/sources.list

# 2. INSTALACIÓN DE EXTENSIONES OBLIGATORIAS
# Añadimos zlib1g-dev explícitamente para solucionar el error de dependencias de libpng-dev
RUN apt-get update && apt-get install -y \
    zlib1g-dev \
    libmcrypt-dev \
    libpng-dev \
    zip \
    unzip \
    git \
    && docker-php-ext-install mcrypt pdo_mysql gd

# 3. CONFIGURACIÓN DE APACHE
RUN a2enmod rewrite

# Solucionado el warning de Docker usando el formato key=value moderno
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# 4. INSTALACIÓN DE COMPOSER 1.X
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer --1

# 5. COPIAR CÓDIGO Y CONFIGURAR DIRECTORIO
WORKDIR /var/www/html
COPY . .

# 6. INSTALACIÓN DE DEPENDENCIAS PHP
RUN composer install --no-interaction --prefer-dist

# 7. PERMISOS DE ESCRITURA
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 775 /var/www/html/app/storage

EXPOSE 80
