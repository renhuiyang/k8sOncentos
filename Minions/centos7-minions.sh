#!/bin/sh
if [ ! $1 ]; then
    echo "Master IP IS NULL"
    exit 1
fi

yum -y update

systemctl disable iptables-services firewalld
systemctl stop iptables-services firewalld

yum -y remove docker-selinux-1.8.2-10.el7.centos.x86_64
yum -y remove docker-1.8.2-10.el7.centos.x86_64

yum install -y flannel kubernetes-node

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

#sed -i "s/OPTIONS=.*/OPTIONS='--selinux-enabled=false'/g" /etc/sysconfig/docker
#sed -i "s/DOCKER_STORAGE_OPTIONS=.*/DOCKER_STORAGE_OPTIONS=-s overlay/g" /etc/sysconfig/docker

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

for SERVICES in docker kubelet kube-proxy; do 
    systemctl restart $SERVICES
    systemctl enable $SERVICES
    systemctl status $SERVICES 
done



