#!/bin/sh
yum -y update

systemctl disable iptables-services firewalld
systemctl stop iptables-services firewalld


tee /etc/yum.repos.d/k8s.repo <<-'EOF'
[virt7-docker-common-release]
name=virt7-docker-common-release
baseurl=http://cbs.centos.org/repos/virt7-docker-common-release/x86_64/os/
gpgcheck=0
EOF

yum install -y etcd flannel
yum -y install --enablerepo=virt7-docker-common-release kubernetes

sed -i 's/ETCD_LISTEN_CLIENT_URLS=.*/ETCD_LISTEN_CLIENT_URLS="http:\/\/0.0.0.0:2379"/g' /etc/etcd/etcd.conf
sed -i 's/#ETCD_LISTEN_PEER_URLS=.*/ETCD_LISTEN_PEER_URLS="http://localhost:2380"/g' /etc/etcd/etcd.conf
sed -i 's/ETCD_ADVERTISE_CLIENT_URLS=.*/ETCD_ADVERTISE_CLIENT_URLS="http://0.0.0.0:2379"/g' /etc/etcd/etcd.conf

sed -i 's/KUBE_MASTER=.*/KUBE_MASTER="--master=http:\/\/0.0.0.0:8080"/g' /etc/kubernetes/config

sed -i 's/KUBE_API_ADDRESS=.*/KUBE_API_ADDRESS="--address=0.0.0.0"/g' /etc/kubernetes/apiserver
sed -i 's/KUBE_ETCD_SERVERS=.*/KUBE_ETCD_SERVERS="--etcd_servers=http:\/\/localhost:2379"/g' /etc/kubernetes/apiserver
sed -i 's/ServiceAccount,//g' /etc/kubernetes/apiserver

sed -i "s/OPTIONS=.*/OPTIONS='--selinux-enabled=false'/g" /etc/sysconfig/docker
sed -i "s/DOCKER_STORAGE_OPTIONS=.*/DOCKER_STORAGE_OPTIONS=-s overlay/g" /etc/sysconfig/docker

sed -i 's/FLANNEL_ETCD=.*/FLANNEL_ETCD="http:\/\/localhost:2379"/g' /etc/sysconfig/flanneld
sed -i 's/FLANNEL_ETCD_KEY=.*/FLANNEL_ETCD_KEY="\/k8s.io\/network"/g' /etc/sysconfig/flanneld

systemctl restart etcd
systemctl enable etcd
systemctl status etcd

sleep 10s

etcdctl mk /k8s.io/network/config '{"Network":"172.17.0.0/16"}'

sleep 10s

systemctl restart flanneld
systemctl enable flanneld
systemctl status flanneld

for SERVICES in docker kube-apiserver kube-controller-manager kube-scheduler; do
    systemctl restart $SERVICES
    systemctl enable $SERVICES
    systemctl status $SERVICES
done

