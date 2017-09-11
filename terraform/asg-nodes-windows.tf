data "template_file" "userdata-windows-node" {
    template = "${file("templates/userdata-nodes.ps1.tpl")}"
    vars {
        bucket_name = "${aws_s3_bucket.bucket.id}"
    }
}

resource "aws_autoscaling_group" "node-windows-asg" {
  availability_zones   = ["${var.core-availability-zone}"]
  name                 = "${var.cluster-name}-node-windows"
  max_size             = "4"
  min_size             = "1"
  desired_capacity     = "3"
  force_delete         = true
  vpc_zone_identifier  = ["${aws_subnet.Nodes.id}"]
  launch_configuration = "${aws_launch_configuration.node-windows-lc.name}"
  tag {
    key                 = "Name"
    value               = "${var.cluster-name}-node-windows"
    propagate_at_launch = "true"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_configuration" "node-windows-lc" {
  name_prefix          = "${var.cluster-name}-node-windows-"
  image_id             = "${lookup(var.AmiWindows, var.region)}"
  instance_type        = "${var.node-windows-instance-type}"
  security_groups      = ["${aws_security_group.Node.id}"]
  user_data            = "${data.template_file.userdata-windows-node.rendered}"
  key_name             = "${var.cluster-name}"
  iam_instance_profile = "${aws_iam_instance_profile.nodes-profile.name}"
  lifecycle {
    create_before_destroy = true
  }
  root_block_device {
    volume_type = "gp2"
    volume_size = "150"
    delete_on_termination = "true"
  }
}

resource "aws_s3_bucket_object" "install_ovn" {
  bucket = "${var.cluster-name}-k8s-state"
  key    = "files/install_ovn.ps1"
  source = "files/install_ovn.ps1"
  etag   = "${md5(file("files/install_ovn.ps1"))}"
}

resource "aws_s3_bucket_object" "install_k8s" {
  bucket = "${var.cluster-name}-k8s-state"
  key    = "files/install_k8s.ps1"
  source = "files/install_k8s.ps1"
  etag   = "${md5(file("files/install_k8s.ps1"))}"
}

resource "aws_s3_bucket_object" "startup" {
  bucket = "${var.cluster-name}-k8s-state"
  key    = "files/startup.ps1"
  source = "files/startup.ps1"
  etag   = "${md5(file("files/startup.ps1"))}"
}

resource "aws_s3_bucket_object" "ovn-controller" {
  bucket = "${var.cluster-name}-k8s-state"
  key    = "bin/ovn-controller.exe"
  source = "bin/ovn-controller.exe"
  etag   = "${md5(file("bin/ovn-controller.exe"))}"
}

resource "aws_s3_bucket_object" "k8s-ovn-exe" {
  bucket = "${var.cluster-name}-k8s-state"
  key    = "bin/k8s_ovn.exe"
  source = "bin/k8s_ovn.exe"
  etag   = "${md5(file("bin/k8s_ovn.exe"))}"
}