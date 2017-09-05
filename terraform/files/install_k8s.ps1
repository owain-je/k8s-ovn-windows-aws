param(
[string] $K8S_PATH="C:\kubernetes",
[string] $K8S_VERSION="1.7.3",
[string] $KUBERNETES_API_SERVER = "10.142.0.2",
[string] $K8S_DNS_SERVICE_IP  = "10.100.0.10",
[string] $K8S_DNS_DOMAIN = "cluster.local"
)

$HOSTNAME = hostname

write-host "install_k8s.ps1 -K8S_PATH '$K8S_PATH' -K8S_VERSION '$K8S_VERSION' -KUBERNETES_API_SERVER '$KUBERNETES_API_SERVER' -K8S_DNS_SERVICE_IP  '$K8S_DNS_SERVICE_IP' -K8S_DNS_DOMAIN '$K8S_DNS_DOMAIN' "

mkdir $K8S_PATH
cd $K8S_PATH

# Download and extract Kubernetes binaries
Start-BitsTransfer https://dl.k8s.io/v$K8S_VERSION/kubernetes-node-windows-amd64.tar.gz
cmd /c '"C:\Program Files\7-Zip\7z.exe" e kubernetes-node-windows-amd64.tar.gz'
cmd /c '"C:\Program Files\7-Zip\7z.exe" x kubernetes-node-windows-amd64.tar'
mv kubernetes\node\bin\*.exe .
Remove-Item -Recurse -Force kubernetes
Remove-Item -Recurse -Force kubernetes-node-windows-amd64*

$cmd = 'sc create kubelet binPath= "\"c:\Program Files\Cloudbase Solutions\Open vSwitch\bin\servicewrapper.exe\" kubelet \"C:\kubernetes\kubelet.exe\" -v=3 --hostname-override={0} --cluster-dns={1} --cluster-domain={2} --pod-infra-container-image=\"apprenda/pause\" --resolv-conf=\"\" --api_servers=\"http://{3}:8080\" --log-dir=\"C:\kubernetes\"" type= own start= auto error= ignore displayname= "Kubernetes Kubelet" obj= LocalSystem' -f $HOSTNAME, $K8S_DNS_SERVICE_IP, $K8S_DNS_DOMAIN, $env:KUBERNETES_API_SERVER
cmd /c $cmd

Start-Service kubelet