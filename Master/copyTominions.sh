for node in 10.182.92.153 10.99.161.111 10.169.240.212; do 
    for app in kubelet kube-proxy; do
        scp -o "StrictHostKeyChecking no" $app root@$node:~/.
    done
done
