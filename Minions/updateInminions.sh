for APP in kubelet kube-proxy; do
    systemctl stop $APP
    cp -f $APP /usr/bin/$APP
    systemctl start $APP
    systemctl status $APP
done

