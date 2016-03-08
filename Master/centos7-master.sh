#!/bin/sh
yum -y update

systemctl disable iptables-services firewalld
systemctl stop iptables-services firewalld

yum -y remove docker-selinux-1.8.2-10.el7.centos.x86_64
yum -y remove docker-1.8.2-10.el7.centos.x86_64

yum install -y etcd flannel kubernetes-master 

#tee /etc/yum.repos.d/docker.repo <<-'EOF'
#[dockerrepo]
#name=Docker Repository
#baseurl=https://yum.dockerproject.org/repo/main/centos/$releasever/
#enabled=1
#gpgcheck=1
#gpgkey=https://yum.dockerproject.org/gpg
#EOF
#yum -y install docker-engine

#systemctl stop docker
#rm -rf /var/lib/docker

sed -i 's/ETCD_LISTEN_CLIENT_URLS=.*/ETCD_LISTEN_CLIENT_URLS="http:\/\/0.0.0.0:2379"/g' /etc/etcd/etcd.conf
sed -i 's/ETCD_LISTEN_PEER_URLS=.*/ETCD_LISTEN_PEER_URLS="http://localhost:2380"/g' /etc/etcd/etcd.conf
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

etcdctl mk /k8s.io/network/config '{"Network":"172.17.0.0/16"}'

systemctl restart flanneld
systemctl enable flanneld
systemctl status flanneld

for SERVICES in docker kube-apiserver kube-controller-manager kube-scheduler; do 
    systemctl restart $SERVICES
    systemctl enable $SERVICES
    systemctl status $SERVICES 
done

 

#sed -i 's/FLANNEL_ETCD=.*/FLANNEL_ETCD="http:\/\/localhost:2379"/g' /etc/sysconfig/flanneld
#sed -i 's/FLANNEL_ETCD_KEY=.*/FLANNEL_ETCD_KEY="\/k8s.io\/network"/g' /etc/sysconfig/flanneld

