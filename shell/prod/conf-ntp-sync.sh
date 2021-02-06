#!/bin/bash
# centos7 设置ntpd服务自动同步时间

date

# ntpd是步进式的逐渐调整时间(慢慢调整到正确时间)，而ntpdate是断点更新(直接重写时间为正确时间)
sudo yum install -y ntp ntpdate ntp-doc

cat > /etc/ntp.conf << 'EOF'
# restrict default ignore # 设置默认策略为允许任何主机进行时间同步
restrict default kod nomodify notrap nopeer noquery
restrict -6 default kod nomodify notrap nopeer noquery  # `restrict -6` 表示针对ipv6设置

# 允许本地所有操作
restrict 127.0.0.1
restrict -6 ::1

# 允许的局域网络段或单独ip
# restrict 192.168.6.0 mask 255.255.255.0 nomodify motrap # 此时表示限制向从192.168.0.1-192.168.0.254这些IP段的服务器提供NTP服务

# 设定NTP主机来源(上层的internet ntp服务器). 其中prefer表示优先主机(如局域网NTP服务器)
# server 192.168.6.131 prefer
server cn.pool.ntp.org prefer
server 0.asia.pool.ntp.org
server 3.asia.pool.ntp.org
server 0.centos.pool.ntp.org iburst

# 如果无法与上层ntp server通信以本地时间为标准时间
server   127.127.1.0    # local clock
fudge    127.127.1.0 stratum 10

# 计算本ntp server与上层ntpserver的频率误差
driftfile /var/lib/ntp/drift

# Key file containing the keys and key identifiers used when operating with symmetric key cryptography.
keys /etc/ntp/keys

# 日志文件
logfile /var/log/ntp.log
EOF

# ntp只能同步系统时间，此配置可将系统时间同步到硬件
cat > /etc/sysconfig/ntpd << EOF
# Drop root to id 'ntp:ntp' by default.
OPTIONS="-u ntp:ntp -p /var/run/ntpd.pid"
# Set to 'yes' to sync hw clock after successful ntpdate
SYNC_HWCLOCK=yes # BIOS的时间也会跟着修改
# Additional options for ntpdate
NTPDATE_OPTIONS=""
EOF

# 设置开机重启并此时立即启动
systemctl enable ntpd --now

date
