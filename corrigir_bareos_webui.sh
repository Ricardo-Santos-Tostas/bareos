#!/bin/bash

set -e

echo "======================================"
echo "🚀 CORREÇÃO COMPLETA DO BAREOS"
echo "======================================"

echo ""
echo "======================================"
echo "🔧 Ajustando PostgreSQL"
echo "======================================"

PG_HBA="/etc/postgresql/15/main/pg_hba.conf"

cp $PG_HBA ${PG_HBA}.backup

sed -i 's/^local\s\+all\s\+all\s\+peer/local all all scram-sha-256/' $PG_HBA

if ! grep -q "host    bareos         bareos         127.0.0.1/32" $PG_HBA; then
    echo "host    bareos         bareos         127.0.0.1/32              scram-sha-256" >> $PG_HBA
fi

systemctl restart postgresql

echo ""
echo "======================================"
echo "🔐 Configurando senha PostgreSQL"
echo "======================================"

su - postgres -c "psql -c \"ALTER USER bareos WITH PASSWORD '583820sa';\""

echo ""
echo "======================================"
echo "🗄️ Configurando catálogo Bareos"
echo "======================================"

cat > /etc/bareos/bareos-dir.d/catalog/MyCatalog.conf <<EOF
Catalog {
  Name = MyCatalog
  dbname = "bareos"
  dbuser = "bareos"
  dbpassword = "583820sa"
  dbaddress = "127.0.0.1"
  dbport = 5432
}
EOF

echo ""
echo "======================================"
echo "🌐 Configurando WebUI"
echo "======================================"

cat > /etc/bareos-webui/directors.ini <<EOF
[localhost-dir]
enabled = "yes"
diraddress = "127.0.0.1"
dirport = 9101

console = "admin"
password = "583820sa"

tls_verify_peer = false
server_can_do_tls = false
client_can_do_tls = false
EOF

echo ""
echo "======================================"
echo "👤 Configurando console admin"
echo "======================================"

cat > /etc/bareos/bareos-dir.d/console/admin.conf <<EOF
Console {
  Name = admin
  Password = "583820sa"
  Profile = webui-admin
  TLS Enable = No
  TLS Require = No
}
EOF

echo ""
echo "======================================"
echo "🛡️ Configurando ACL WebUI"
echo "======================================"

cat > /etc/bareos/bareos-dir.d/profile/webui-admin.conf <<EOF
Profile {
  Name = webui-admin

  CommandACL = *all*
  Job ACL = *all*
  Client ACL = *all*
  Storage ACL = *all*
  Schedule ACL = *all*
  Catalog ACL = *all*
  Pool ACL = *all*
  FileSet ACL = *all*
  Where ACL = *all*
}
EOF

echo ""
echo "======================================"
echo "🖥️ Ajustando bconsole"
echo "======================================"

DIR_PASSWORD=$(grep Password /etc/bareos/bareos-dir.d/director/bareos-dir.conf | head -1 | awk -F '"' '{print $2}')

cat > /etc/bareos/bconsole.conf <<EOF
Director {
  Name = bareos-dir
  DIRport = 9101
  address = localhost
  Password = "$DIR_PASSWORD"
}
EOF

echo ""
echo "======================================"
echo "🧹 Limpando cache e sessões"
echo "======================================"

rm -rf /var/lib/php/sessions/*
rm -rf /var/cache/bareos-webui/*

echo ""
echo "======================================"
echo "🔄 Reiniciando serviços"
echo "======================================"

systemctl reset-failed bareos-director || true

systemctl restart postgresql
systemctl restart bareos-director
systemctl restart bareos-storage
systemctl restart bareos-filedaemon
systemctl restart apache2

echo ""
echo "======================================"
echo "✅ Validando configuração"
echo "======================================"

bareos-dir -t -c /etc/bareos/

echo ""
echo "======================================"
echo "📋 Status serviços"
echo "======================================"

systemctl --no-pager --type=service | grep bareos

IP=$(hostname -I | awk '{print $1}')

echo ""
echo "======================================"
echo "✅ BAREOS CORRIGIDO COM SUCESSO"
echo "======================================"

echo ""
echo "🌐 WebUI:"
echo "http://$IP/bareos-webui"

echo ""
echo "🔑 LOGIN:"
echo "Director: localhost-dir"
echo "Username: admin"
echo "Password: 583820sa"

echo ""
echo "======================================"
echo "🚀 PRONTO PARA USO"
echo "======================================"
