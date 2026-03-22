#!/usr/bin/env bash

set -e

SERVICE="shadowsocksr"
SSR_DIR="/usr/local/shadowsocks"
CONF="/etc/shadowsocks.json"

check_root(){
if [ "$EUID" -ne 0 ]; then
 echo "Please run as root"
 exit
fi
}

detect_os(){

if [ -f /etc/debian_version ]; then
    OS="debian"
    PKG_INSTALL="apt install -y"
    PKG_UPDATE="apt update -y"
elif [ -f /etc/redhat-release ]; then
    OS="centos"
    PKG_INSTALL="dnf install -y"
    PKG_UPDATE="dnf makecache"
else
    echo "Unsupported OS"
    exit
fi

}

install_dep(){

echo "Installing dependencies..."

$PKG_UPDATE
$PKG_INSTALL python3 python3-pip wget tar jq curl openssl libcap

}

enable_low_port(){

echo "Enable low port capability..."

setcap 'cap_net_bind_service=+ep' /usr/bin/python3 || true

}

install_ssr(){

echo "Installing ShadowsocksR..."

cd /usr/local

rm -rf shadowsocks shadowsocksr-3.2.2 ssr.tar.gz || true

wget -q -O ssr.tar.gz https://github.com/shadowsocksrr/shadowsocksr/archive/3.2.2.tar.gz

tar zxf ssr.tar.gz

mv shadowsocksr-3.2.2/shadowsocks ${SSR_DIR}

rm -rf shadowsocksr-3.2.2 ssr.tar.gz

sed -i 's/collections.MutableMapping/collections.abc.MutableMapping/g' \
${SSR_DIR}/lru_cache.py

}

create_user(){

id shadowsocks &>/dev/null || useradd -r -s /usr/sbin/nologin shadowsocks

}

gen_config(){

PORT=$(shuf -i20000-60000 -n1)
PASS=$(openssl rand -base64 12)

cat > ${CONF} <<EOF
{
 "server":"0.0.0.0",
 "server_ipv6":"::",
 "server_port":$PORT,
 "password":"$PASS",
 "timeout":120,
 "method":"aes-256-cfb",
 "protocol":"origin",
 "protocol_param":"",
 "obfs":"plain",
 "obfs_param":"",
 "fast_open":false,
 "workers":1
}
EOF

}

create_service(){

cat > /etc/systemd/system/${SERVICE}.service <<EOF
[Unit]
Description=ShadowsocksR Server
After=network.target

[Service]
Type=simple
User=shadowsocks
ExecStart=/usr/bin/python3 ${SSR_DIR}/server.py -c ${CONF}
Restart=always
LimitNOFILE=51200

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable ${SERVICE}

}

open_firewall(){

PORT=$(jq .server_port ${CONF})

if command -v ufw >/dev/null; then

 ufw allow ${PORT}/tcp || true
 ufw allow ${PORT}/udp || true

elif command -v firewall-cmd >/dev/null; then

 firewall-cmd --add-port=${PORT}/tcp --permanent
 firewall-cmd --add-port=${PORT}/udp --permanent
 firewall-cmd --reload

elif command -v iptables >/dev/null; then

 iptables -I INPUT -p tcp --dport ${PORT} -j ACCEPT
 iptables -I INPUT -p udp --dport ${PORT} -j ACCEPT

fi

}

show_info(){

IP=$(curl -s ifconfig.me)
PORT=$(jq .server_port ${CONF})
PASS=$(jq -r .password ${CONF})
METHOD=$(jq -r .method ${CONF})

echo
echo "========= SSR Installed ========="
echo "Server   : $IP"
echo "Port     : $PORT"
echo "Password : $PASS"
echo "Method   : $METHOD"
echo "Protocol : origin"
echo "Obfs     : plain"
echo "================================="
echo

}

install_all(){

detect_os
install_dep
install_ssr
enable_low_port
create_user
gen_config
create_service
open_firewall

systemctl start ${SERVICE}

show_info

}

menu(){

echo
echo "========= SSR Manager ========="
echo "1 Install SSR"
echo "2 Start"
echo "3 Stop"
echo "4 Restart"
echo "5 Status"
echo "6 View Log"
echo "7 Change Port"
echo "8 Change Password"
echo "9 Uninstall"
echo "0 Exit"
echo "================================"

read -p "Select: " num

case "$num" in

1) install_all ;;
2) systemctl start ${SERVICE} ;;
3) systemctl stop ${SERVICE} ;;
4) systemctl restart ${SERVICE} ;;
5) systemctl status ${SERVICE} ;;
6) journalctl -u ${SERVICE} -f ;;
7) read -p "New port: " PORT
   jq ".server_port=${PORT}" ${CONF} > /tmp/ssr.json
   mv /tmp/ssr.json ${CONF}
   open_firewall
   systemctl restart ${SERVICE}
   ;;
8) read -p "New password: " PASS
   jq ".password=\"${PASS}\"" ${CONF} > /tmp/ssr.json
   mv /tmp/ssr.json ${CONF}
   systemctl restart ${SERVICE}
   ;;
9) systemctl stop ${SERVICE}
   systemctl disable ${SERVICE}
   rm -f /etc/systemd/system/${SERVICE}.service
   rm -rf ${SSR_DIR}
   rm -f ${CONF}
   systemctl daemon-reload
   echo "SSR removed"
   ;;
0) exit ;;
*) echo "Invalid" ;;

esac

}

check_root
menu