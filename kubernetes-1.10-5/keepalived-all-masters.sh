#!/bin/bash
yum -y install keepalived
systemctl enable keepalived
mv /etc/keepalived/keepalived.conf /etc/keepalived/keepalived.conf.original

if [[ "$PEER_NAME" == "kub-master-01.syone.com" ]]; then
cat >/etc/keepalived/keepalived.conf <<EOF
! Configuration File for keepalived
global_defs {
 router_id LVS_DEVEL
}

vrrp_script check_apiserver {
 script "/etc/keepalived/check_apiserver.sh"
 interval 3
 weight -2
 fall 10
 rise 2
}

vrrp_instance VI_1 {
   state MASTER
   interface eth0
   virtual_router_id 51
   priority 101
   authentication {
       auth_type PASS
       auth_pass 4be37dc3b4c90194d1600c483e10ad1d
   }
   virtual_ipaddress {
       192.168.122.19
   }
   track_script {
       check_apiserver
   }
}
EOF

else
cat >/etc/keepalived/keepalived.conf <<EOF
! Configuration File for keepalived
global_defs {
 router_id LVS_DEVEL
}

vrrp_script check_apiserver {
 script "/etc/keepalived/check_apiserver.sh"
 interval 3
 weight -2
 fall 10
 rise 2
}

vrrp_instance VI_1 {
   state BACKUP
   interface eth0
   virtual_router_id 51
   priority 100
   authentication {
       auth_type PASS
       auth_pass 4be37dc3b4c90194d1600c483e10ad1d
   }
   virtual_ipaddress {
       192.168.122.19
   }
   track_script {
       check_apiserver
   }
}
EOF

fi

cat >/etc/keepalived/check_apiserver.sh <<EOF
errorExit() {
   echo "*** $*" 1>&2
   exit 1
}

curl --silent --max-time 2 --insecure https://localhost:6443/ -o /dev/null || errorExit "Error GET https://localhost:6443/"
if ip addr | grep -q 192.168.122.19; then
   curl --silent --max-time 2 --insecure https://192.168.122.19:6443/ -o /dev/null || errorExit "Error GET https://192.168.122.19:6443/"
fi
EOF

systemctl restart keepalived
systemctl status keepalived
