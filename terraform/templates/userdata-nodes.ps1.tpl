<powershell>

$Logfile = "C:\userdata.log"

Function LogWrite
{
   Param ([string]$logstring)

   Add-content $Logfile -value $logstring
}

$K8S_VERSION="1.7.3"
$K8S_DNS_SERVICE_IP  = "10.100.0.10"
$K8S_DNS_DOMAIN = "cluster.local"
$SUBNET_PREFIX="10.244"
$CLUSTER_IP_SUBNET="$SUBNET_PREFIX.0.0/16"
$PUBLIC_IP=(Get-NetIPConfiguration | Where-Object {$_.InterfaceAlias -eq "Ethernet"}).IPv4Address.IPAddress
$octets = "$PUBLIC_IP" -split "\."
$net=$octets[3]
$SUBNET="$SUBNET_PREFIX.$net.0/24" 
$GATEWAY_IP="$SUBNET_PREFIX.$net.1"

LogWrite "PUBLIC_IP: $PUBLIC_IP"
LogWrite "CLUSTER_IP_SUBNET: $CLUSTER_IP_SUBNET"
LogWrite "SUBNET: $SUBNET"
LogWrite "GATEWAY_IP: $GATEWAY_IP"

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
cmd /c 'msiexec /i openvswitch-hyperv-2.7.0-certified.msi ADDLOCAL="OpenvSwitchCLI,OpenvSwitchDriver,OVNHost" APPDATADIR="c:\ProgramData\openvswitch\run\openvswitch" /qn' 
do {
	$service = Get-WmiObject -Class Win32_Service -Filter "Name='ovn-controller'"
	LogWrite "Service exitcode: $service.exitcode"
	start-sleep 2
}
until ($service.exitcode -eq 0)

$env:path = $env:path + ";c:\Program Files\Cloudbase Solutions\Open vSwitch\bin;c:\kubernetes;C:\Program Files\Amazon\AWSCLI"
[Environment]::SetEnvironmentVariable("Path",$env:Path,[System.EnvironmentVariableTarget]::Machine)

LogWrite "added to path $env:path"
LogWrite "installed open v switch"
LogWrite "getting master ip address"

$$S3_BUCKET="${bucket_name}"

LogWrite "Download the master api address from ${bucket_name} once the master is ready"
do {
	& "C:\Program Files\Amazon\AWSCLI\aws.exe" s3 cp "s3://$S3_BUCKET/masterip" c:\masterip	
	$ECODE = $LASTEXITCODE
	LogWrite "failed to download from ${bucket_name} $ECODE"
	start-sleep 5
}
until ($ECODE -eq 0)

& "C:\Program Files\Amazon\AWSCLI\aws.exe" s3 cp "s3://$S3_BUCKET/files/install_ovn.ps1" c:\ovs\install_ovn.ps1
& "C:\Program Files\Amazon\AWSCLI\aws.exe" s3 cp "s3://$S3_BUCKET/files/install_k8s.ps1" c:\ovs\install_k8s.ps1

$KUBERNETES_API_SERVER=[IO.File]::ReadAllText("c:\masterip").replace("`n","").replace("`r","")

LogWrite "Master API is $KUBERNETES_API_SERVER"

powershell -c  .\install_ovn.ps1 -KUBERNETES_API_SERVER "'$KUBERNETES_API_SERVER'" -GATEWAY_IP "'$GATEWAY_IP'" -SUBNET "'$SUBNET'"  > c:\ovs\install_ovn.log 2>&1 

powershell -c  .\install_k8s.ps1 -KUBERNETES_API_SERVER "'$KUBERNETES_API_SERVER'" -K8S_VERSION "'$K8S_VERSION" -K8S_DNS_SERVICE_IP "'$K8S_DNS_SERVICE_IP'" -K8S_DNS_DOMAIN "'$K8S_DNS_DOMAIN'"  > c:\ovs\install_k8s.log 2>&1


</powershell>





