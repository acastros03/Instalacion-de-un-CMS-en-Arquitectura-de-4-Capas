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