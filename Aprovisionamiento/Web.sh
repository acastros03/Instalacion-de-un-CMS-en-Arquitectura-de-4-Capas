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