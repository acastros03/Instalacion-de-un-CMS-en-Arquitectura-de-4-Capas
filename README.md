# Instalación de un CMS en Arquitectura de 4 Capas

## 📑 Índice

* [Introducción](#-introducción)
* [Arquitectura del sistema](#-arquitectura-del-sistema)
* [Estructura de red](#-estructura-de-red)
* [Estructura del proyecto](#-estructura-del-proyecto)
* [Vagrantfile](#-vagrantfile)
* [Aprovisionamiento con Vagrant](#-aprovisionamiento-con-vagrant)
* [Scripts de aprovisionamiento](#-scripts-de-aprovisionamiento)
* [Funcionamiento de la capa web](#-funcionamiento-de-la-capa-web)
* [Conclusión](#-conclusión)
* [Comprobación](#-comprobación)


---

## 🖥️ Introducción

Este proyecto consiste en el despliegue de una **arquitectura de 4 capas en alta disponibilidad** utilizando **Vagrant** con **Debian Bookworm**, orientada a la instalación de un **CMS WordPress**.

La arquitectura separa claramente las responsabilidades de cada capa:

* Balanceo de carga HTTP
* Servidores web sin ejecución de PHP
* Almacenamiento compartido y ejecución de PHP mediante NFS
* Base de datos MariaDB en alta disponibilidad con Galera y HAProxy

Todo el sistema se despliega automáticamente mediante **scripts Bash**.

---

## 🌐 Arquitectura del sistema

### Descripción general

* **Balanceador**: NGINX como proxy inverso y balanceador HTTP.
* **Servidores Web**: NGINX sirviendo contenido desde NFS, sin PHP local.
* **Servidor NFS**: Almacenamiento compartido, PHP-FPM y código del CMS.
* **Base de Datos**: MariaDB en clúster Galera con HAProxy como proxy TCP.

---

## 🖧 Estructura de red

### Tabla de direccionamiento IP

| Máquina              | Rol               | IP                        | Red      |
| -------------------- | ----------------- | ------------------------- | -------- |
| BalanceadorAlexandro | Balanceador NGINX | 192.168.2.1 / 192.168.1.1 | Frontend |
| ServerWEB1Alexandro  | Servidor Web      | 192.168.2.2               | Web      |
| ServerWEB2Alexandro  | Servidor Web      | 192.168.2.3               | Web      |
| ServerNFSAlexandro   | NFS + PHP-FPM     | 192.168.3.1 / 192.168.2.4 | Backend  |
| ProxyBDAlexandro     | HAProxy MariaDB   | 192.168.4.1 / 192.168.3.2 | BD       |
| BD1Alexandro         | MariaDB           | 192.168.4.2               | BD       |
| BD2Alexandro         | MariaDB           | 192.168.4.3               | BD       |

---

## 📂 Estructura del proyecto

```
.
├── Vagrantfile
└── Aprovisionamiento
    ├── BL.sh
    ├── Web.sh
    ├── NFS.sh
    ├── ProxyBD.sh
    ├── BD1.sh
    └── BD2.sh
```

---

## 📄 Vagrantfile

En este apartado se incluye el fichero `Vagrantfile`, encargado de definir todas las máquinas virtuales, sus interfaces de red y los scripts de aprovisionamiento asociados a cada una de ellas.

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "debian/bookworm64"

   config.vm.define "BD1Alexandro" do |bd1|
    bd1.vm.hostname = "BD1Alexandro"
    bd1.vm.network "private_network", ip: "192.168.4.2"
    bd1.vm.provision "shell", path: "Aprovisionamiento/BD1.sh"
  end

  config.vm.define "BD2Alexandro" do |bd2|
    bd2.vm.hostname = "BD2Alexandro"
    bd2.vm.network "private_network", ip: "192.168.4.3"
    bd2.vm.provision "shell", path: "Aprovisionamiento/BD2.sh"
  end

  config.vm.define "ProxyBDAlexandro" do |proxy|
    proxy.vm.hostname = "ProxyBDAlexandro"
    proxy.vm.network "private_network", ip: "192.168.4.1"
    proxy.vm.network "private_network", ip: "192.168.3.2"
    proxy.vm.provision "shell", path: "Aprovisionamiento/ProxyBD.sh"
  end

  config.vm.define "ServerNFSAlexandro" do |nfs|
    nfs.vm.hostname = "ServerNFSAlexandro"
    nfs.vm.network "private_network", ip: "192.168.3.1"
    nfs.vm.network "private_network", ip: "192.168.2.4"
    nfs.vm.provision "shell", path: "Aprovisionamiento/NFS.sh"
  end

  config.vm.define "ServerWEB1Alexandro" do |web1|
    web1.vm.hostname = "ServerWEB1Alexandro"
    web1.vm.network "private_network", ip: "192.168.2.2"
    web1.vm.provision "shell", path: "Aprovisionamiento/Web.sh"
  end

  config.vm.define "ServerWEB2Alexandro" do |web2|
    web2.vm.hostname = "ServerWEB2Alexandro"
    web2.vm.network "private_network", ip: "192.168.2.3"
    web2.vm.provision "shell", path: "Aprovisionamiento/Web.sh"
  end

  config.vm.define "BalanceadorAlexandro" do |bl|
    bl.vm.hostname = "BalanceadorAlexandro"
    bl.vm.network "private_network", ip: "192.168.2.1"
    bl.vm.network "private_network", ip: "192.168.1.1"
    bl.vm.network "forwarded_port", guest: 80, host: 8081
    bl.vm.provision "shell", path: "Aprovisionamiento/BL.sh"
  end
```

---

## ⚙️ Aprovisionamiento con Vagrant

El despliegue de las máquinas virtuales se realiza mediante **Vagrant**, utilizando un único `Vagrantfile` que define todas las máquinas y ejecuta los scripts de aprovisionamiento correspondientes.

Los **dos servidores web utilizan el mismo script** (`Web.sh`).

---

## 📝 Scripts de aprovisionamiento

### Balanceador (BL.sh)

```bash
#!/bin/bash
set -e

echo "=== Configurando balanceador Nginx ==="

apt-get update -y
apt-get install -y nginx curl

cat > /etc/nginx/sites-available/balanceador << 'EOF'
upstream web_backend {
    server 192.168.2.2:80;
    server 192.168.2.3:80;
}

server {
    listen 80;
    server_name _;

    access_log /var/log/nginx/balanceador_access.log;
    error_log /var/log/nginx/balanceador_error.log;

    location / {
        proxy_pass http://web_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    location /nginx-health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

ln -sf /etc/nginx/sites-available/balanceador /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

nginx -t
systemctl restart nginx
systemctl enable nginx

echo ""
echo "✓✓✓ Balanceador configurado ✓✓✓"
echo "Accede a: http://localhost:8081"
```

### Servidor Web (Web.sh)

```bash
#!/bin/bash

echo "=== Configurando Servidor Web ==="

# Instalar paquetes
apt-get update -y
apt-get install -y nginx nfs-common mariadb-client

# Crear punto de montaje
mkdir -p /var/www/html/webapp

# Esperar al NFS
echo "Esperando al servidor NFS..."
sleep 15

# Montar con NFSv4 usando la IP correcta
sudo systemctl daemon-reload
mount -t nfs4 192.168.2.4:/ /var/www/html/webapp

# Configurar montaje automático
echo "192.168.2.4:/ /var/www/html/webapp nfs4 defaults,_netdev 0 0" >> /etc/fstab

# Configurar Nginx
cat > /etc/nginx/sites-available/webapp << 'EOF'
server {
    listen 80;
    server_name _;
    root /var/www/html/webapp;
    index index.php index.html;

    location / {
        try_files $uri $uri/ =404;
    }

    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_pass 192.168.2.4:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME /srv/nfs/web$fastcgi_script_name;
    }
}
EOF

ln -sf /etc/nginx/sites-available/webapp /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

systemctl restart nginx
systemctl enable nginx

echo "✓ Servidor Web configurado"
```

### Servidor NFS (NFS.sh)

```bash
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
```

### Proxy MariaDB (ProxyBD.sh)

```bash
#!/bin/bash
set -e

echo "=== Configurando HAProxy ==="

apt-get update -y
apt-get install -y haproxy

cat > /etc/haproxy/haproxy.cfg << 'EOF'
global
    daemon
    maxconn 2048
    log /dev/log local0
    user haproxy
    group haproxy

defaults
    mode tcp
    log global
    option tcplog
    option dontlognull
    timeout connect 10s
    timeout client 1h
    timeout server 1h

frontend mysql_front
    bind *:3306
    default_backend mysql_back

backend mysql_back
    balance roundrobin
    option tcp-check
    tcp-check connect
    server BD1 192.168.4.2:3306 check inter 5s rise 2 fall 3
    server BD2 192.168.4.3:3306 check inter 5s rise 2 fall 3

listen stats
    bind *:8080
    mode http
    stats enable
    stats uri /stats
    stats refresh 10s
    stats auth admin:admin
EOF

systemctl restart haproxy
systemctl enable haproxy

echo ""
echo "✓✓✓ HAProxy configurado ✓✓✓"
echo "Estadísticas: http://192.168.4.1:8080/stats (admin/admin)"
echo "MySQL proxy: 192.168.4.1:3306 y 192.168.3.2:3306"
```

### BD1 (BD1.sh)

```bash
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
```

### BD2 (BD2.sh)

```bash
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
```

---

## 🌊 Funcionamiento de la capa web

Los servidores web:

* No ejecutan PHP localmente
* Sirven contenido desde NFS
* Reenvían las peticiones PHP al servidor NFS mediante FastCGI

Esto permite escalabilidad, centralización del código y menor carga en los servidores web.

---

## ✅ Conclusión

La arquitectura desplegada cumple los objetivos del proyecto:

* Alta disponibilidad
* Separación clara de capas
* Balanceo de carga funcional
* Centralización del código y PHP
* Despliegue automático y reproducible

El sistema es accesible desde la máquina anfitriona.

---

## 🎬 Comprobación

Video de comprobacion](https://labs-iberotech.ddns.net/)
