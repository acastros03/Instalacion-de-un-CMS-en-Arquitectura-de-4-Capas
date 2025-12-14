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