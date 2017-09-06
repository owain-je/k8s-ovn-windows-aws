$services = "ovn-controller"
$maxRepeat = 60
$status = "Running" # change to Stopped if you want to wait for services to start
do 
{
    $count = (Get-Service $services | ? {$_.status -ne $status}).count
    $maxRepeat--
    sleep 1
} until ($count -eq 0 -or $maxRepeat -eq 0)

& ovs-ofctl  add-flow br-ex priority=1,action=strip_vlan,NORMAL