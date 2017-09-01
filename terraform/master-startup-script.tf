resource "local_file" "master-startup-script" {
    content     = "#!/bin/bash    echo 'hello  ${var.cluster-name}-k8s-state'  "
    filename = "foo.bar"
}