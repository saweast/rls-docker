# Docker LAMP Developer
FROM ubuntu:latest

MAINTAINER Rob Loach <robloach@gmail.com>

# Environment Variables
ENV DEBIAN_FRONTEND=noninteractive

# Base Packages
RUN apt-get update -y
#RUN apt-get upgrade -y
RUN apt-get install -y supervisor git debconf-utils
RUN mkdir -p /var/log/supervisor


# SSH
RUN apt-get install -y openssh-server
ADD configs/ssh/supervisor.conf /etc/supervisor/conf.d/ssh.conf
RUN mkdir -p /var/run/sshd

# Apache
RUN apt-get install -y apache2
ADD configs/apache2/apache2-service.sh /apache2-service.sh
ADD configs/apache2/apache2-setup.sh /apache2-setup.sh
RUN chmod +x /*.sh
ADD configs/apache2/apache_default /etc/apache2/sites-available/000-default.conf
ADD configs/apache2/supervisor.conf /etc/supervisor/conf.d/apache2.conf
RUN /apache2-setup.sh


# PHP
RUN apt-get update
RUN apt-get install -y php7.0 libapache2-mod-php7.0 php7.0-json php7.0-cli php7.0-curl curl php7.0-mcrypt php-xdebug mcrypt libmcrypt-dev php-xdebug
RUN php -v

ADD configs/php/php.ini /etc/php/7.0/apache2/conf.d/30-docker.ini
ADD configs/php/php.ini /etc/php/7.0/apache2/php.ini
ADD configs/php/php-setup.sh /php-setup.sh
RUN chmod +x /php-setup.sh
RUN /php-setup.sh

# Configure DB (add dump to mysql)
ADD ./dump.sql /dump.sql
#RUN mysql -u root -proot sugarcrm < dump.sql

# MySQL
RUN apt-get install -y mysql-server mysql-client php-mysql
ADD configs/mysql/mysql-setup.sh /mysql-setup.sh
RUN chmod +x /*.sh
ADD configs/mysql/my.cnf /etc/mysql/conf.d/my.cnf
ADD configs/mysql/supervisor.conf /etc/supervisor/conf.d/mysql.conf
RUN /mysql-setup.sh

# PHPMyAdmin
RUN (echo 'phpmyadmin phpmyadmin/dbconfig-install boolean true' | debconf-set-selections)
RUN (echo 'phpmyadmin phpmyadmin/app-password password root' | debconf-set-selections)
RUN (echo 'phpmyadmin phpmyadmin/app-password-confirm password root' | debconf-set-selections)
RUN (echo 'phpmyadmin phpmyadmin/mysql/admin-pass password root' | debconf-set-selections)
RUN (echo 'phpmyadmin phpmyadmin/mysql/app-pass password root' | debconf-set-selections)
RUN (echo 'phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2' | debconf-set-selections)
RUN apt-get install phpmyadmin -y
ADD configs/phpmyadmin/config.inc.php /etc/phpmyadmin/conf.d/config.inc.php
RUN chmod 755 /etc/phpmyadmin/conf.d/config.inc.php
ADD configs/phpmyadmin/phpmyadmin-setup.sh /phpmyadmin-setup.sh
RUN chmod +x /phpmyadmin-setup.sh
RUN /phpmyadmin-setup.sh



# Start
VOLUME ["/var/www/html/"]
EXPOSE 22 80 3306
CMD ["supervisord", "-n"]