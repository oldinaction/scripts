# 安装 node_exporter
node_exporter_version=0.18.1
wget https://github.com/prometheus/node_exporter/releases/download/v$node_exporter_version/node_exporter-$node_exporter_version.linux-amd64.tar.gz
tar -xvzf node_exporter-$node_exporter_version.linux-amd64.tar.gz
sudo mv node_exporter-$node_exporter_version.linux-amd64/node_exporter /usr/sbin/node_exporter
rm -rf node_exporter-$node_exporter_version.linux-amd64 && rm node_exporter-$node_exporter_version.linux-amd64.tar.gz
# 安装 supervisor
sudo yum install -y supervisor
sudo systemctl enable supervisord --now
sudo cat > /etc/supervisord.d/node_exporter.ini << EOF
[program:node_exporter]
command=/usr/sbin/node_exporter
autostart=true
autorestart=true
stdout_logfile=/var/log/supervisor/node_exporter.log
log_stderr=true
user=root
EOF
supervisorctl update
supervisorctl status
