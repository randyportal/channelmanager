FROM php:5.6-apache

# 1. TRUCO PARA REPOSITORIOS DEBIAN OBSOLETOS (Jessie)
# Como Debian 8 (Jessie) llegó al fin de su vida útil, los repositorios normales fallan.
# Apuntamos a los servidores de archivo histórico y saltamos la validación de fechas.
RUN echo "Acquire::Check-Valid-Until \"false\";" > /etc/apt/apt.conf.d/99no-check-valid-until \
    && echo "deb http://archive.debian.org/debian/ jessie main" > /etc/apt/sources.list \
    && echo "deb http://archive.debian.org/debian-security jessie/updates main" >> /etc/apt/sources.list

# 2. INSTALACIÓN DE EXTENSIONES OBLIGATORIAS
# Laravel 4.2 requiere estrictamente la extensión 'mcrypt' (la cual ya no existe en PHP moderno)
RUN apt-get update && apt-get install -y \
    libmcrypt-dev \
    libpng-dev \
    zip \
    unzip \
    git \
    && docker-php-ext-install mcrypt pdo_mysql gd

# 3. CONFIGURACIÓN DE APACHE
# Activamos mod_rewrite para que funcionen las rutas amigables de Laravel (.htaccess)
RUN a2enmod rewrite

# Cambiamos la raíz de Apache para que apunte directamente a la carpeta /public de Laravel
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# 4. INSTALACIÓN DE COMPOSER 1.X
# Agregamos el flag '--1' para asegurar que descargue Composer v1, indispensable para Laravel 4
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer --1

# 5. COPIAR CÓDIGO Y CONFIGURAR DIRECTORIO
WORKDIR /var/www/html
COPY . .

# 6. INSTALACIÓN DE DEPENDENCIAS PHP
# Ahora sí correrá sin problemas porque está en PHP 5.6 con Composer 1
RUN composer install --no-interaction --prefer-dist

# 7. PERMISOS DE ESCRITURA
# En Laravel 4, la carpeta de almacenamiento es 'app/storage' (en Laravel 5+ cambió a 'storage')
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 775 /var/www/html/app/storage

EXPOSE 80
