#!/bin/sh
if [ ! $1 ]; then
    echo "Master IP IS NULL"
    exit 1
fi

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

sed -i 's/KUBE_MASTER=.*/KUBE_MASTER="--master=http:\/\/'$1':8080"/g' /etc/kubernetes/config

sed -i 's/KUBELET_ADDRESS=.*/KUBELET_ADDRESS="--address=0.0.0.0"/g' /etc/kubernetes/kubelet

localIP4=`ifconfig eth0|grep "inet "|awk '{print $2}'`
sed -i 's/KUBELET_HOSTNAME=.*/KUBELET_HOSTNAME="--hostname_override='$localIP4'"/g' /etc/kubernetes/kubelet
sed -i 's/KUBELET_API_SERVER=.*/KUBELET_API_SERVER="--api_servers=http:\/\/'$1':8080"/g' /etc/kubernetes/kubelet

sed -i 's/FLANNEL_ETCD=.*/FLANNEL_ETCD="http:\/\/'$1':2379"/g' /etc/sysconfig/flanneld
sed -i 's/FLANNEL_ETCD_KEY=.*/FLANNEL_ETCD_KEY="\/k8s.io\/network"/g' /etc/sysconfig/flanneld

systemctl restart flanneld
systemctl enable flanneld
systemctl status flanneld

sleep 10s

for SERVICES in docker kubelet kube-proxy; do 
    systemctl restart $SERVICES
    systemctl enable $SERVICES
    systemctl status $SERVICES 
done



