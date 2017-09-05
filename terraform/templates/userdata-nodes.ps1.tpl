<powershell>
exit 0 

$Logfile = "C:\userdata.log"

Function LogWrite
{
   Param ([string]$logstring)

   Add-content $Logfile -value $logstring
}

Set-ExecutionPolicy -ExecutionPolicy bypass

LogWrite "install chocolatey"
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

LogWrite "install aws cli" 
choco install awscli -y 
choco install 7zip -y 

LogWrite "disable firewall"
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False

mkdir c:\ovs
cd c:\ovs

$start_time = Get-Date
Invoke-WebRequest -Uri "https://cloudbase.it/downloads/openvswitch-hyperv-2.7.0-certified.msi" -OutFile "c:\ovs\openvswitch-hyperv-2.7.0-certified.msi"
LogWrite  "openvswitch-hyperv-2.7.0-certified.msi Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"

$start_time = Get-Date
Invoke-WebRequest -Uri "https://cloudbase.it/downloads/k8s_ovn_service_prerelease.zip" -OutFile "c:\ovs\k8s_ovn_service_prerelease.zip"
LogWrite  "k8s_ovn_service_prerelease.zip Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"



Install-WindowsFeature -Name Containers

LogWrite "install open v switch"

cd c:\ovs
cmd /c 'msiexec /i openvswitch-hyperv-2.7.0-certified.msi ADDLOCAL="OpenvSwitchCLI,OpenvSwitchDriver,OVNHost" /qn' 
do {
	$service = Get-WmiObject -Class Win32_Service -Filter "Name='ovn-controller'"
	LogWrite "Service exitcode: $service.exitcode"
	start-sleep 2
}
until ($service.exitcode -eq 0)

$env:path = $env:path + ";c:\Program Files\Cloudbase Solutions\Open vSwitch\bin;c:\kubernetes"

[Environment]::SetEnvironmentVariable("Path",$env:Path,[System.EnvironmentVariableTarget]::Machine)

LogWrite "added to path $env:path"
LogWrite "installed open v switch"
LogWrite "getting master ip address"

$$S3_BUCKET="${bucket_name}"

LogWrite "Download the master api address from ${bucket_name} once the master is ready"
do {
	& "C:\Program Files\Amazon\AWSCLI\aws.exe" s3 cp "s3://${bucket_name}/masterip" c:\masterip	
	$ECODE = $LASTEXITCODE
	LogWrite "failed to download from ${bucket_name} $ECODE"
	start-sleep 5
}
until ($ECODE -eq 0)

$KUBERNETES_API_SERVER=[IO.File]::ReadAllText("c:\masterip").replace("`n","").replace("`r","")

LogWrite "Master API is $KUBERNETES_API_SERVER"

LogWrite "installing ovn" 

$INTERFACE_ALIAS="Ethernet" # Interface used for creating the overlay tunnels (must have connectivity with other hosts)
$PUBLIC_IP=(Get-NetIPConfiguration | Where-Object {$_.InterfaceAlias -eq "Ethernet"}).IPv4Address.IPAddress
$octets = "$PUBLIC_IP" -split "\."
$net=$octets[3]

LogWrite "network octet $net"

$SUBNET="10.244.$net.0/24" # The minion subnet used to spawn pods on
$GATEWAY_IP="10.244.$net.1" # first ip of the subnet
$CLUSTER_IP_SUBNET="10.244.0.0/16" # The big subnet which includes the minions subnets
$HOSTNAME=hostname
$K8S_ZIP=".\k8s_ovn_service_prerelease.zip" # Location of k8s OVN binaries (DO NOT CHANGE unless you know what you're doing)
$OVS_PATH="c:\Program Files\Cloudbase Solutions\Open vSwitch\bin" # Default installation directory for OVS (DO NOT CHANGE unless you know what you're doing)
$K8S_PATH="C:\kubernetes"
$K8S_VERSION="1.7.3"
$HOSTNAME = hostname
$K8S_MASTER_IP = $KUBERNETES_API_SERVER
$K8S_DNS_SERVICE_IP = "10.100.0.10"
$K8S_DNS_DOMAIN = "cluster.local"


mkdir $K8S_PATH
cd $K8S_PATH

# Download and extract Kubernetes binaries

$start_time = Get-Date
$uri = "https://dl.k8s.io/v" + $K8S_VERSION + "/kubernetes-node-windows-amd64.tar.gz"

Invoke-WebRequest -Uri $uri -OutFile "c:\kubernetes\kubernetes-node-windows-amd64.tar.gz"

LogWrite "kubernetes-node-windows-amd64.tar.gz Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"

cmd /c '"C:\Program Files\7-Zip\7z.exe" e kubernetes-node-windows-amd64.tar.gz'
cmd /c '"C:\Program Files\7-Zip\7z.exe" x kubernetes-node-windows-amd64.tar'
mv kubernetes\node\bin\*.exe .
#Remove-Item -Recurse -Force kubernetes
#Remove-Item -Recurse -Force kubernetes-node-windows-amd64*


LogWrite "Public IP $PUBLIC_IP"
LogWrite "Subnet $SUBNET"
LogWrite "Gateway $GATEWAY_IP"
LogWrite "Cluster IP $CLUSTER_IP_SUBNET"
LogWrite "Hostname $HOSTNAME"

Stop-Service docker
Get-ContainerNetwork | Remove-ContainerNetwork -Force
cmd /c 'echo { "bridge" : "none" } > C:\ProgramData\docker\config\daemon.json'
Start-Service docker

docker network create -d transparent --gateway $GATEWAY_IP --subnet $SUBNET -o com.docker.network.windowsshim.interface=$INTERFACE_ALIAS external

$a = Get-NetAdapter | where Name -Match HNSTransparent
rename-netadapter $a[0].name -newname HNSTransparent

LogWrite "setting up ovs"
LogWrite "PATH $env:Path"

stop-service ovs-vswitchd -force; disable-vmswitchextension "cloudbase open vswitch extension";
ovs-vsctl --no-wait del-br br-ex
ovs-vsctl --no-wait --may-exist add-br br-ex
ovs-vsctl --no-wait add-port br-ex HNSTransparent -- set interface HNSTransparent type=internal
ovs-vsctl --no-wait add-port br-ex $INTERFACE_ALIAS

enable-vmswitchextension "cloudbase open vswitch extension"; sleep 4; restart-service ovs-vswitchd


$k8s_api = "$KUBERNETES_API_SERVER" + ":8080"
$remote = "$KUBERNETES_API_SERVER" + ":6642"
$nb="$KUBERNETES_API_SERVER" + ":6641"
$pi="$PUBLIC_IP"
LogWrite $k8s_api
LogWrite $remote
LogWrite $nb
LogWrite $pi
LogWrite "ovs-vsctl set Open_vSwitch . external_ids:k8s-api-server=`"$k8s_api`""
LogWrite "ovs-vsctl set Open_vSwitch . external_ids:ovn-remote=`"tcp:$remote`" external_ids:ovn-nb=`"tcp:$nb`" external_ids:ovn-encap-ip=`"$pi`" external_ids:ovn-encap-type=`"geneve`""

ovs-vsctl set Open_vSwitch . external_ids:k8s-api-server="$k8s_api"
ovs-vsctl set Open_vSwitch . external_ids:ovn-remote="tcp:$remote" external_ids:ovn-nb="tcp:$nb" external_ids:ovn-encap-ip="$pi" external_ids:ovn-encap-type="geneve"

$GUID = (New-Guid).Guid
LogWrite "ovs-vsctl set Open_vSwitch . external_ids:system-id=`"$GUID`""
ovs-vsctl set Open_vSwitch . external_ids:system-id="$GUID"

LogWrite "guid is $GUID"

#Needed for AWS 
LogWrite "ovs-ofctl.exe add-flow br-ex priority=1,action=strip_vlan,NORMAL"
ovs-ofctl.exe add-flow br-ex priority=1,action=strip_vlan,NORMAL


# On some cloud-providers this is needed, otherwise RDP connection may bork
netsh interface ipv4 set subinterface "HNSTransparent" mtu=1430 store=persistent

start-sleep 5

cd c:\ovs

#expand k8s PoC binaries and create service
$unzipCmd = '"C:\Program Files\7-Zip\7z.exe" e -aos "{0}" -o"{1}" -x!*libeay32.dll -x!*ssleay32.dll'  -f $K8S_ZIP, $OVS_PATH
cmd /c $unzipCmd

cmd /c 'sc create ovn-k8s binPath= "\"c:\Program Files\Cloudbase Solutions\Open vSwitch\bin\servicewrapper.exe\" ovn-k8s \"c:\Program Files\Cloudbase Solutions\Open vSwitch\bin\k8s_ovn.exe\"" type= own start= auto error= ignore depend= ovsdb-server/ovn-controller displayname= "OVN Watcher" obj= LocalSystem'

LogWrite "windows-init.exe windows-init --node-name $HOSTNAME --minion-switch-subnet $SUBNET --cluster-ip-subnet $CLUSTER_IP_SUBNET"

windows-init.exe windows-init --node-name $HOSTNAME --minion-switch-subnet $SUBNET --cluster-ip-subnet $CLUSTER_IP_SUBNET


start-service ovn-k8s

start-sleep 5

LogWrite "post windows init"

# TODO
# Register kubelet as a service and start it
setx -m CONTAINER_NETWORK "external"
#cmd /c 'sc create kubelet binPath= "\"C:\Program Files (x86)\Open vSwitch\bin\servicewrapper.exe\" kubelet \"C:\kubernetes\kubelet.exe\" -v=3 --hostname-override=$HOSTNAME --cluster-dns=$K8S_MASTER_IP  --cluster-domain=cluster.local --pod-infra-container-image=\"apprenda/pause\" --resolv-conf=\"\" --api_servers=\"http://$KUBERNETES_API_SERVER:8080\" --log-dir=\"C:\kubernetes\"" type= own start= auto error= ignore displayname= "Kubernetes Kubelet" obj= LocalSystem'

#>

</powershell>




