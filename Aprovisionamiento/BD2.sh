#!/bin/bash

echo "=== Configurando BD2 ==="

# DNS
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 1.1.1.1" >> /etc/resolv.conf

# Instalar MariaDB
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y mariadb-server mariadb-client galera-4 rsync

# Detener MariaDB
systemctl stop mariadb

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
wsrep_node_address="192.168.4.3"
wsrep_node_name="BD2"
EOF

# Esperar a BD1
echo "Esperando a BD1..."
sleep 40

# Unirse al cluster
systemctl start mariadb
systemctl enable mariadb

echo "✓ BD2 configurado"