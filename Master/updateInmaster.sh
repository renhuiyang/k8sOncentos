for APP in kube-apiserver kube-controller-manager kube-scheduler; do
    systemctl stop $APP
    cp -f $APP /usr/bin/$APP
    systemctl start $APP
    systemctl status $APP
done
