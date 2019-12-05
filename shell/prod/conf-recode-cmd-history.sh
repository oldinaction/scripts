#!/bin/bash
# centos7 记录用户执行命令历史到日志文件 /var/log/local1-info.log (cmd-hostory)

\cp /etc/rsyslog.conf /etc/rsyslog.conf.bak
cat >> /etc/rsyslog.conf << 'EOF'
local1.info /var/log/local1-info.log
EOF
systemctl restart rsyslog

\cp /etc/profile /etc/profile.bak
cat >> /etc/profile << 'EOF'

## 设置history格式，并记录到日志文件 /var/log/local1-info.log
USER_IP=`who -u am i 2>/dev/null| awk '{print $NF}'|sed -e 's/[()]//g'`
export HISTTIMEFORMAT="%F %T ${USER_IP} `whoami` " 
export PROMPT_COMMAND='\
if [ -z "$OLD_PWD" ];then
    export OLD_PWD=$PWD;
fi;
if [ ! -z "$LAST_CMD" ] && [ "$(history 1)" != "$LAST_CMD" ]; then
    logger -it cmd-hostory[`whoami`] -p local1.info "[$OLD_PWD] $(history 1)";
fi ;
export LAST_CMD="$(history 1)";
export OLD_PWD=$PWD;'

EOF
source /etc/profile
echo 'conf-recode-cmd-history done...'