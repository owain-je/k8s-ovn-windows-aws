data "template_file" "userdata-linux-node" {
    template = "${file("templates/userdata-nodes.sh.tpl")}"
    vars {
        bucket_name = "${aws_s3_bucket.bucket.id}"
    }
}

resource "aws_autoscaling_group" "node-linux-asg" {
  availability_zones   = ["${var.core-availability-zone}"]
  name                 = "${var.cluster-name}-node-linux"
  max_size             = "1"
  min_size             = "1"
  desired_capacity     = "1"
  force_delete         = true
  vpc_zone_identifier  = ["${aws_subnet.Nodes.id}"]
  launch_configuration = "${aws_launch_configuration.node-linux-lc.name}"
  tag {
    key                 = "Name"
    value               = "${var.cluster-name}-node-linux"
    propagate_at_launch = "true"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_configuration" "node-linux-lc" {
  name_prefix          = "${var.cluster-name}-node-linux-"
  image_id             = "${lookup(var.AmiLinux, var.region)}"
  instance_type        = "${var.node-linux-instance-type}"
  security_groups      = ["${aws_security_group.Node.id}"]
  user_data            = "${data.template_file.userdata-linux-node.rendered}"
  key_name             = "${var.cluster-name}"
  iam_instance_profile = "${aws_iam_instance_profile.nodes-profile.name}"
  lifecycle {
    create_before_destroy = true
  }
}