#!/usr/bin/env bash
set -e

SSR_DIR="/usr/local/shadowsocks"
CONF="/etc/shadowsocks.json"
SERVICE="shadowsocks"

install_ssr() {
    echo "Installing SSR..."

    dnf install -y python3 wget tar >/dev/null

    cd /usr/local/
    rm -rf shadowsocks shadowsocksr-3.2.2 ssr.tar.gz || true
    wget -q -O ssr.tar.gz https://github.com/shadowsocksrr/shadowsocksr/archive/3.2.2.tar.gz
    tar zxf ssr.tar.gz
    mv shadowsocksr-3.2.2/shadowsocks ${SSR_DIR}
    rm -rf shadowsocksr-3.2.2 ssr.tar.gz

    echo "Patching python..."
    sed -i 's/collections.MutableMapping/collections.abc.MutableMapping/g' \
    ${SSR_DIR}/lru_cache.py

    echo "Fix pid & log..."
    sed -i 's#/var/run/shadowsocksr.pid#/run/shadowsocksr/shadowsocksr.pid#g' \
    ${SSR_DIR}/shell.py
    sed -i 's#/var/log/shadowsocksr.log#/run/shadowsocksr/shadowsocksr.log#g' \
    ${SSR_DIR}/shell.py

    id shadowsocks &>/dev/null || useradd -r -s /sbin/nologin shadowsocks

    if [ ! -f ${CONF} ]; then
cat > ${CONF} <<EOF
{
    "server":"0.0.0.0",
    "server_ipv6":"[::]",
    "server_port":8388,
    "local_address":"127.0.0.1",
    "local_port":1080,
    "password":"password",
    "timeout":120,
    "method":"aes-256-cfb",
    "protocol":"origin",
    "protocol_param":"",
    "obfs":"plain",
    "obfs_param":"",
    "redirect":"",
    "dns_ipv6":false,
    "fast_open":false,
    "workers":1
}
EOF
    fi

cat > /etc/systemd/system/${SERVICE}.service <<EOF
[Unit]
Description=ShadowsocksR Service
After=network.target

[Service]
Type=forking
User=shadowsocks
Group=shadowsocks

RuntimeDirectory=shadowsocksr
RuntimeDirectoryMode=0755

ExecStart=/usr/bin/python3 ${SSR_DIR}/server.py -c ${CONF} -d start
ExecStop=/usr/bin/python3 ${SSR_DIR}/server.py -c ${CONF} -d stop
ExecReload=/usr/bin/python3 ${SSR_DIR}/server.py -c ${CONF} -d restart

LimitNOFILE=51200
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable ${SERVICE}
    systemctl restart ${SERVICE}

    echo "Install complete."
}

start_ssr()   { systemctl start ${SERVICE}; }
stop_ssr()    { systemctl stop ${SERVICE}; }
restart_ssr() { systemctl restart ${SERVICE}; }
status_ssr()  { systemctl status ${SERVICE}; }
log_ssr()     { journalctl -u ${SERVICE} -f; }

change_port() {
    read -p "New port: " port
    sed -i "s/\"server_port\":.*/\"server_port\":${port},/" ${CONF}
    restart_ssr
}

change_pass() {
    read -p "New password: " pass
    sed -i "s/\"password\":.*/\"password\":\"${pass}\",/" ${CONF}
    restart_ssr
}

change_method() {
    read -p "New method: " m
    sed -i "s/\"method\":.*/\"method\":\"${m}\",/" ${CONF}
    restart_ssr
}

uninstall_ssr() {
    systemctl stop ${SERVICE} || true
    systemctl disable ${SERVICE} || true
    rm -f /etc/systemd/system/${SERVICE}.service
    systemctl daemon-reload
    rm -rf ${SSR_DIR}
    echo "Uninstalled."
}

menu() {
echo
echo "========= SSR Manager ========="
echo "1. Install"
echo "2. Start"
echo "3. Stop"
echo "4. Restart"
echo "5. Status"
echo "6. Log"
echo "7. Change Port"
echo "8. Change Password"
echo "9. Change Method"
echo "10. Uninstall"
echo "0. Exit"
echo "================================"
read -p "Select: " num

case "$num" in
1) install_ssr ;;
2) start_ssr ;;
3) stop_ssr ;;
4) restart_ssr ;;
5) status_ssr ;;
6) log_ssr ;;
7) change_port ;;
8) change_pass ;;
9) change_method ;;
0) exit ;;
*) echo "Invalid" ;;
esac
}

menu