#!/bin/bash

echo "=== Configurando NFS Server ==="

# DNS
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 1.1.1.1" >> /etc/resolv.conf

# Instalar paquetes
apt-get update -y
apt-get install -y git nfs-kernel-server php-fpm php-mysql php-curl php-gd php-mbstring php-xml php-xmlrpc php-soap php-intl php-zip

# Crear directorio NFS
mkdir -p /srv/nfs/web
chmod 755 /srv/nfs/web

# Configurar NFS con NFSv4
cat > /etc/exports << 'EOF'
/srv/nfs/web 192.168.2.0/24(rw,sync,no_subtree_check,no_root_squash,fsid=0)
EOF

# Habilitar NFSv4
cat > /etc/default/nfs-kernel-server << 'EOF'
RPCNFSDCOUNT=8
RPCNFSDPRIORITY=0
RPCMOUNTDOPTS="--manage-gids"
NEED_SVCGSSD="no"
RPCSVCGSSDOPTS=""
EOF

exportfs -rav
systemctl restart nfs-kernel-server
systemctl enable nfs-kernel-server

# Descargar aplicación
rm -rf /tmp/lamp
git clone https://github.com/josejuansanchez/iaw-practica-lamp.git /tmp/lamp
cp /tmp/lamp/src/* /srv/nfs/web/
rm -rf /tmp/lamp

# Configurar base de datos
cat > /srv/nfs/web/config.php << 'EOF'
<?php
define('DB_HOST', '192.168.4.1');
define('DB_NAME', 'cmsdb');
define('DB_USER', 'cmsuser');
define('DB_PASSWORD', 'cmspass');
$mysqli = mysqli_connect(DB_HOST, DB_USER, DB_PASSWORD, DB_NAME);
if (!$mysqli) {
    die("Error de conexión: " . mysqli_connect_error());
}
?>
EOF

# Permisos
chown -R www-data:www-data /srv/nfs/web
chmod -R 755 /srv/nfs/web

# Configurar PHP-FPM
PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
sed -i 's|^listen = .*|listen = 0.0.0.0:9000|' /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf

systemctl restart php${PHP_VERSION}-fpm
systemctl enable php${PHP_VERSION}-fpm

echo "✓ NFS Server configurado"