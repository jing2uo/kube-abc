export VIP="192.168.137.248"
export VIP1="192.168.137.246"
export VIP2="192.168.137.247"
export MASTER1="192.168.137.221"
export MASTER2="192.168.137.220"
export MASTER3="192.168.137.219"

export IFACE="eth0"

export OWNIP=$(ip a s ${IFACE} | egrep -o 'inet [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | cut -d' ' -f2)

if [[ ${OWNIP} == ${VIP1} ]]; then
    export PARTNERIP=${VIP2}
elif [[ ${OWNIP} == ${VIP2} ]]; then
    export PARTNERIP=${VIP1}
fi

install_haproxy() {
  yum install haproxy -y -q
  mkdir -p /etc/haproxy/
  cat <<EOF >/etc/haproxy/haproxy.cfg
global
    log     127.0.0.1 local0
    nbproc 1           # 1 is recommended
    maxconn  51200     # maximum per-process number of concurrent connections
    pidfile /etc/haproxy/haproxy.pid
    tune.ssl.default-dh-param 2048

defaults
        mode http      # { tcp|http|health }
        #retries 2
        #option httplog
        #option tcplog
        maxconn  51200
        option redispatch
        option abortonclose
        timeout connect 5000ms
        timeout client 2m
        timeout server 2m
        log global
        balance roundrobin

listen stats
        bind 0.0.0.0:2936
        mode http
        stats enable
        stats refresh 10s
        stats hide-version
        stats uri  /admin
        stats realm LB2\ Statistics
        stats auth admin:admin@123

listen web-service
    bind 127.0.0.1:9

frontend frontend_80
  bind *:80
  mode http
  default_backend backend_80

frontend frontend_443
  bind *:443
  mode tcp
  default_backend backend_443

frontend frontend_6443
  bind *:6443
  mode tcp
  default_backend backend_6443

frontend frontend_2379
  bind *:2379
  mode tcp
  default_backend backend_2379

backend backend_2379
  mode tcp
  balance roundrobin
  default-server on-marked-down shutdown-sessions
server s0 ${MASTER1}:2379 check port 2379 inter 1000 maxconn 51200
server s1 ${MASTER2}:2379 check port 2379 inter 1000 maxconn 51200
server s2 ${MASTER3}:2379 check port 2379 inter 1000 maxconn 51200

backend backend_60080
  mode tcp
  balance roundrobin
  default-server on-marked-down shutdown-sessions
server s0 ${MASTER1}:60080 check port 60080 inter 1000 maxconn 51200
server s1 ${MASTER2}:60080 check port 60080 inter 1000 maxconn 51200
server s2 ${MASTER3}:60080 check port 60080 inter 1000 maxconn 51200

backend backend_80
  mode http
  balance roundrobin
  default-server on-marked-down shutdown-sessions
server s0 ${MASTER1}:80 check port 80 inter 1000 maxconn 51200
server s1 ${MASTER2}:80 check port 80 inter 1000 maxconn 51200
server s2 ${MASTER3}:80 check port 80 inter 1000 maxconn 51200

backend backend_443
  mode tcp
  balance roundrobin
  default-server on-marked-down shutdown-sessions
server s0 ${MASTER1}:443 check port 443 inter 1000 maxconn 51200
server s1 ${MASTER2}:443 check port 443 inter 1000 maxconn 51200
server s2 ${MASTER3}:443 check port 443 inter 1000 maxconn 51200

backend backend_6443
  mode tcp
  balance roundrobin
  default-server on-marked-down shutdown-sessions
server s0 ${MASTER1}:6443 check port 6443 inter 1000 maxconn 51200
server s1 ${MASTER2}:6443 check port 6443 inter 1000 maxconn 51200
server s2 ${MASTER3}:6443 check port 6443 inter 1000 maxconn 51200
EOF
  systemctl enable haproxy && systemctl restart haproxy
}

install_keepalived() {
  yum install keepalived -y -q
  mkdir -p /etc/keepalived/
  cat <<EOF >/etc/keepalived/keepalived.conf
global_defs {
    notification_email {
    }
    router_id LVS_DEVEL
    vrrp_skip_check_adv_addr
    vrrp_garp_interval 0
    vrrp_gna_interval 0
}

vrrp_script chk_haproxy {
    script "killall -0 haproxy"
    interval 2
    weight 2
}

vrrp_instance haproxy-vip {
    state BACKUP
    priority 100
    interface ${IFACE}
    virtual_router_id 60
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    unicast_src_ip ${OWNIP}
    unicast_peer {
        ${PARTNERIP}
    }

    virtual_ipaddress {
        ${VIP}
    }

    track_script {
        chk_haproxy
    }
}
EOF
systemctl enable keepalived && systemctl restart keepalived
}
