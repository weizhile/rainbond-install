ip=$(ip ad|grep inet|egrep ' 10.|172.|192.168'|awk '{print $2}'|cut -d '/' -f 1|grep -v '172.30.42.1'|head -1)

if [ ! -f "/etc/salt/minion.d/minion.ex.conf" ];then

cat > /etc/salt/minion.d/minion.ex.conf <<EOF
grains:               
  mip:
    - $ip
EOF
fi