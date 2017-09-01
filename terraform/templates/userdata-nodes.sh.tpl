#!/bin/bash

cat >/startup.sh <<EOL
#!/bin/bash

export TUNNEL_MODE=geneve
export LOCAL_IP=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk -F'[/ ]+' '{print $3}')
export MASTER_IP=$(< /masterip)
export LAST_OCTET=`echo $LOCAL_IP | cut -d . -f 4`

ovs-vsctl set Open_vSwitch . external_ids:ovn-remote="tcp:$MASTER_IP:6642" \
  external_ids:ovn-nb="tcp:\$MASTER_IP:6641" \
  external_ids:ovn-encap-ip="\$LOCAL_IP" \
  external_ids:ovn-encap-type="\$TUNNEL_MODE"

ovs-vsctl get Open_vSwitch . external_ids

cd ~/kubernetes-ovn-heterogeneous-cluster/worker/linux

rm -rf tmp
mkdir tmp
cp -R ../make-certs ../openssl.cnf ../kubeconfig.yaml systemd tmp/
# so a bit of a hacky way to get a unique subnet address , works for only 254 nodes right....

export HOSTNAME=`hostname`
export K8S_VERSION=1.7.3
export K8S_POD_SUBNET=10.244.0.0/16
export K8S_NODE_POD_SUBNET=10.244.$LAST_OCTET.0/24
export K8S_DNS_SERVICE_IP=10.100.0.10
export K8S_DNS_DOMAIN=cluster.local

sed -i"*" "s|__K8S_VERSION__|\$K8S_VERSION|g" tmp/systemd/kubelet.service

sed -i"*" "s|__MASTER_IP__|\$MASTER_IP|g" tmp/systemd/kubelet.service
sed -i"*" "s|__MASTER_IP__|\$MASTER_IP|g" tmp/openssl.cnf
sed -i"*" "s|__MASTER_IP__|\$MASTER_IP|g" tmp/kubeconfig.yaml

sed -i"*" "s|__LOCAL_IP__|\$LOCAL_IP|g" tmp/systemd/kubelet.service
sed -i"*" "s|__LOCAL_IP__|\$LOCAL_IP|g" tmp/openssl.cnf

sed -i"*" "s|__HOSTNAME__|\$HOSTNAME|g" tmp/systemd/kubelet.service
sed -i"*" "s|__HOSTNAME__|\$HOSTNAME|g" tmp/make-certs

sed -i"*" "s|__K8S_DNS_SERVICE_IP__|\$K8S_DNS_SERVICE_IP|g" tmp/systemd/kubelet.service
sed -i"*" "s|__K8S_DNS_DOMAIN__|\$K8S_DNS_DOMAIN|g" tmp/systemd/kubelet.service

cd tmp
chmod +x make-certs
./make-certs
cd ..

mkdir -p /etc/kubernetes/

cp tmp/kubeconfig.yaml /etc/kubernetes/

cp -R tmp/systemd/*.service /etc/systemd/system/
systemctl daemon-reload

curl -Lskj -o /usr/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/v\$K8S_VERSION/bin/linux/amd64/kubectl
chmod +x /usr/bin/kubectl

kubectl config set-cluster default-cluster --server=https://\$MASTER_IP --certificate-authority=/etc/kubernetes/tls/ca.pem
kubectl config set-credentials default-admin --certificate-authority=/etc/kubernetes/tls/ca.pem --client-key=/etc/kubernetes/tls/node-key.pem --client-certificate=/etc/kubernetes/tls/node.pem
kubectl config set-context local --cluster=default-cluster --user=default-admin
kubectl config use-context local

export TOKEN=$(kubectl describe secret $(kubectl get secrets | grep default | cut -f1 -d ' ') | grep -E '^token' | cut -f2 -d':' | tr -d '\t')
ovs-vsctl set Open_vSwitch . external_ids:k8s-api-server="https://\$MASTER_IP" external_ids:k8s-api-token="\$TOKEN"
ln -fs /etc/kubernetes/tls/ca.pem /etc/openvswitch/k8s-ca.crt

mkdir -p /opt/cni/bin && cd /opt/cni/bin
curl -Lskj -o cni.tar.gz https://github.com/containernetworking/cni/releases/download/v0.4.0/cni-v0.4.0.tgz
tar zxf cni.tar.gz
rm -f cni.tar.gz

#apt install -y python-pip
#pip install --upgrade pip

cd ~
git clone https://github.com/openvswitch/ovn-kubernetes
cd ovn-kubernetes
pip install --upgrade --prefix=/usr/local --ignore-installed .

ovn-k8s-overlay minion-init --cluster-ip-subnet="\$K8S_POD_SUBNET" --minion-switch-subnet="\$K8S_NODE_POD_SUBNET" --node-name="\$HOSTNAME"

cat > /etc/rc.local <<AOL
#!/bin/sh -e
#
exit 0
AOL

chmod 755 /etc/rc.local

EOL

chmod 755 /startup.sh

export K8S_VERSION=1.7.3
export S3_BUCKET=${bucket_name}

apt update -y
apt-get -y install  python-minimal python-six

curl -fsSL https://yum.dockerproject.org/gpg | apt-key add -
echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" > sudo tee /etc/apt/sources.list.d/docker.list

apt update -y
echo "install docker"
apt install -y docker.io dkms

cd ~
git clone https://github.com/apprenda/kubernetes-ovn-heterogeneous-cluster
cd kubernetes-ovn-heterogeneous-cluster/deb

dpkg -i openvswitch-common_2.7.2-1_amd64.deb \
openvswitch-datapath-dkms_2.7.2-1_all.deb \
openvswitch-switch_2.7.2-1_amd64.deb \
ovn-common_2.7.2-1_amd64.deb \
ovn-central_2.7.2-1_amd64.deb \
ovn-docker_2.7.2-1_amd64.deb \
ovn-host_2.7.2-1_amd64.deb \
python-openvswitch_2.7.2-1_all.deb

echo vport_geneve >> /etc/modules-load.d/modules.conf

curl -Lskj -o /usr/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/v$K8S_VERSION/bin/linux/amd64/kubectl
chmod +x /usr/bin/kubectl

apt install -y python-pip
pip install --upgrade pip
apt install awscli -y 

cat >/etc/rc.local <<EOL
#!/bin/sh -e
#
sudo /startup.sh > /var/log/startup.log
exit 0
EOL

chmod 755 /etc/rc.local

mkdir -p /etc/kubernetes/tls

aws s3 cp s3://\$S3_BUCKET/masterip /masterip
aws s3 cp s3://\$S3_BUCKET/tls/ca-key.pem /etc/kubernetes/tls/ca-key.pem 
aws s3 cp s3://\$S3_BUCKET/tls/ca.pem /etc/kubernetes/tls/ca.pem 


echo "rebooting"
reboot

