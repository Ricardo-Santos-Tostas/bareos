#!/bin/bash

set -e

echo "=============================="
echo "🔄 Atualizando sistema"
echo "=============================="

apt update && apt upgrade -y

echo "=============================="
echo "📦 Instalando dependências"
echo "=============================="

apt install -y \
    gnupg \
    wget \
    curl \
    lsb-release \
    ca-certificates \
    net-tools \
    apt-transport-https \
    software-properties-common \
    apache2-utils

echo "=============================="
echo "⬇️ Adicionando repositório Bareos"
echo "=============================="

wget -O add_bareos_repositories.sh https://raw.githubusercontent.com/Ricardo-Santos-Tostas/bareos/main/add_bareos_repositories.sh

chmod +x add_bareos_repositories.sh

./add_bareos_repositories.sh -y

apt update

echo "=============================="
echo "🐘 Instalando PostgreSQL"
echo "=============================="

apt install -y \
    postgresql \
    postgresql-contrib

systemctl enable postgresql
systemctl start postgresql

echo "=============================="
echo "🌐 Instalando Apache + PHP"
echo "=============================="

apt install -y \
    apache2 \
    php \
    php-cli \
    php-fpm \
    php-pgsql \
    php-xml \
    php-mbstring \
    php-json \
    php-curl \
    libapache2-mod-fcgid

echo "=============================="
echo "💾 Instalando Bareos"
echo "=============================="

DEBIAN_FRONTEND=noninteractive apt install -y \
    bareos \
    bareos-database-postgresql \
    bareos-webui \
    bareos-director \
    bareos-storage \
    bareos-filedaemon \
    bareos-bconsole

echo "=============================="
echo "⚙️ Configurando Apache + PHP-FPM"
echo "=============================="

PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")

a2enmod proxy_fcgi setenvif
a2enmod rewrite
a2enconf php${PHP_VERSION}-fpm

if [ -f /etc/apache2/conf-available/bareos-webui.conf ]; then
    a2enconf bareos-webui
fi

systemctl enable apache2
systemctl restart apache2

echo "=============================="
echo "🔐 Configurando WebUI Bareos"
echo "=============================="

cat > /etc/bareos-webui/directors.ini <<EOF
[localhost-dir]
enabled = "yes"
diraddress = "127.0.0.1"
dirport = 9101
tls_verify_peer = false
server_can_do_tls = true
client_can_do_tls = true
EOF

echo "=============================="
echo "👤 Configurando console admin"
echo "=============================="

cat > /etc/bareos/bareos-dir.d/console/admin.conf <<EOF
Console {
    Name = admin
    Password = 583820sa
    Profile = webui-admin
    TLS Enable = no
}
EOF

echo "=============================="
echo "🛡️ Configurando ACL WebUI"
echo "=============================="

cat > /etc/bareos/bareos-dir.d/profile/webui-admin.conf <<EOF
Profile {
    Name = webui-admin
    CommandACL = status, list, show, messages, .status
    JobACL = *all*
    ClientACL = *all*
    StorageACL = *all*
    CatalogACL = *all*
    ScheduleACL = *all*
    PoolACL = *all*
}
EOF

echo "=============================="
echo "🚀 Habilitando serviços Bareos"
echo "=============================="

systemctl daemon-reload

systemctl enable bareos-director
systemctl enable bareos-storage
systemctl enable bareos-filedaemon

systemctl restart bareos-director
systemctl restart bareos-storage
systemctl restart bareos-filedaemon

echo "=============================="
echo "📂 Criando diretório de backup"
echo "=============================="

mkdir -p /var/lib/bareos/storage

chown -R bareos:bareos /var/lib/bareos
chmod -R 755 /var/lib/bareos

echo "=============================="
echo "🔐 Configurando usuário WebUI"
echo "=============================="

htpasswd -bc /etc/bareos-webui/htpasswd admin 583820sa

echo "=============================="
echo "🔄 Reiniciando serviços"
echo "=============================="

systemctl restart postgresql
systemctl restart bareos-director
systemctl restart bareos-storage
systemctl restart bareos-filedaemon
systemctl restart apache2

echo "=============================="
echo "✅ Validando serviços"
echo "=============================="

systemctl is-active --quiet bareos-director || exit 1
systemctl is-active --quiet bareos-storage || exit 1
systemctl is-active --quiet bareos-filedaemon || exit 1
systemctl is-active --quiet apache2 || exit 1
systemctl is-active --quiet postgresql || exit 1

IP=$(hostname -I | awk '{print $1}')

echo ""
echo "=============================="
echo "✅ INSTALAÇÃO FINALIZADA"
echo "=============================="
echo ""
echo "🌐 WebUI:"
echo "http://$IP/bareos-webui"
echo ""
echo "👤 Usuário WebUI:"
echo "admin"
echo ""
echo "🔑 Senha WebUI:"
echo "583820sa"
echo ""
echo "📦 Serviços instalados:"
echo "bareos-director"
echo "bareos-storage"
echo "bareos-filedaemon"
echo ""
echo "📋 Status dos serviços:"

systemctl --no-pager --type=service | grep bareos

echo ""
echo "=============================="
echo "🚀 Bareos pronto para uso"
echo "=============================="
echo "=============================="

echo "🔧 Baixando e executando correção WebUI"
echo "=============================="

wget -O corrigir_bareos_webui.sh https://raw.githubusercontent.com/Ricardo-Santos-Tostas/bareos/main/corrigir_bareos_webui.sh

chmod +x corrigir_bareos_webui.sh

./corrigir_bareos_webui.sh
