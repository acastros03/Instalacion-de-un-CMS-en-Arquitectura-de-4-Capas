#!/bin/bash
set -e

echo "=== Configurando BD1 ==="

# DNS
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 1.1.1.1" >> /etc/resolv.conf

# Instalar MariaDB
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y mariadb-server mariadb-client galera-4 rsync

# Detener MariaDB completamente
systemctl stop mariadb 2>/dev/null || true
pkill -9 mysqld 2>/dev/null || true
sleep 3

# Limpiar archivos de estado
rm -f /var/lib/mysql/grastate.dat
rm -f /var/lib/mysql/gvwstate.dat

# Configurar Galera
cat > /etc/mysql/mariadb.conf.d/60-galera.cnf << 'EOF'
[mysqld]
binlog_format=ROW
default-storage-engine=InnoDB
innodb_autoinc_lock_mode=2
bind-address=0.0.0.0

wsrep_on=ON
wsrep_provider=/usr/lib/galera/libgalera_smm.so
wsrep_cluster_name="galera_cluster"
wsrep_cluster_address="gcomm://192.168.4.2,192.168.4.3"
wsrep_sst_method=rsync
wsrep_node_address="192.168.4.2"
wsrep_node_name="BD1"
wsrep_slave_threads=4
innodb_flush_log_at_trx_commit=0
EOF

# Asegurar permisos
chown -R mysql:mysql /var/lib/mysql /var/log/mysql
chmod 750 /var/lib/mysql

# Inicializar cluster
echo "Inicializando cluster Galera..."
galera_new_cluster

# Esperar a que arranque
sleep 10

# Crear base de datos con estructura correcta
echo "Creando base de datos..."
mysql << 'SQLEOF'
CREATE DATABASE IF NOT EXISTS cmsdb CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'cmsuser'@'%' IDENTIFIED BY 'cmspass';
GRANT ALL PRIVILEGES ON cmsdb.* TO 'cmsuser'@'%';
FLUSH PRIVILEGES;

USE cmsdb;

-- Tabla con estructura correcta para la aplicación
CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  age INT NOT NULL,
  email VARCHAR(100) NOT NULL,
  user VARCHAR(50),
  pass VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Datos de ejemplo
INSERT INTO users (name, age, email, user, pass) VALUES 
('Admin User', 30, 'admin@example.com', 'admin', MD5('admin123')),
('Test User', 25, 'test@example.com', 'test', MD5('test123'));
SQLEOF

systemctl enable mariadb

echo ""
echo "✓✓✓ BD1 configurado correctamente ✓✓✓"
echo ""
mysql -e "SHOW STATUS LIKE 'wsrep_cluster_%';" | grep -E '(size|status)'
mysql -e "USE cmsdb; DESCRIBE users;"
mysql -e "USE cmsdb; SELECT * FROM users;"