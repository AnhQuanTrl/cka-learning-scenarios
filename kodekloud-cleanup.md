# node01
<add node01 to /etc/hosts>
kubeadm reset
iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X && iptables -t nat -X && iptables -t mangle -X
ip link delete flannel.1
rm /etc/cni/net.d/10-canal.conflist /etc/cni/net.d/calico-kubeconfig /etc/cni/net.d/87-podman-bridge.conflist
rm /opt/cni/bin/calico /opt/cni/bin/calico-ipam /opt/cni/bin/install
rm -rf /var/lib/calico/
rm -rf /run/calico/

# controlplane
kubectl drain node01 --delete-emptydir-data --force --ignore-daemonsets
kubectl delete node node01
kubeadm reset
iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X && iptables -t nat -X && iptables -t mangle -X
ip link delete flannel.1
rm /etc/cni/net.d/10-canal.conflist /etc/cni/net.d/calico-kubeconfig /etc/cni/net.d/87-podman-bridge.conflist
rm /opt/cni/bin/calico /opt/cni/bin/calico-ipam /opt/cni/bin/install
rm -rf /var/lib/calico/
rm -rf /run/calico/
<delete veth pair as well>

```
cat <<EOF > /etc/resolv.conf 
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF
```

sudo systemctl stop containerd
while mountpoint -q /var/lib/kubelet; do
  sudo umount -l /var/lib/kubelet
done
sudo mount --bind /var/lib/kubelet /var/lib/kubelet
sudo mount --make-shared /var/lib/kubelet
sudo systemctl restart containerd

findmnt -o TARGET,PROPAGATION,SOURCE /var/lib/kubelet

[plugins."io.containerd.grpc.v1.cri"]
    sandbox_image = "registry.k8s.io/pause:3.9"
    enable_unprivileged_ports = true
    enable_unprivileged_icmp = true
sudo systemctl restart containerd

