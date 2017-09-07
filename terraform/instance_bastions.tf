resource "aws_instance" "bastion-linux" {
  ami           = "${lookup(var.AmiLinux, var.region)}"
  instance_type = "${var.bastion-linux-instance-type}"
  associate_public_ip_address = "true"
  subnet_id = "${aws_subnet.PublicAZA.id}"
  vpc_security_group_ids = ["${aws_security_group.Bastion-Linux.id}"]
  key_name = "${var.cluster-name}"
  tags {
        Name = "${var.cluster-name}-bastion-linux"
  }
  user_data = <<HEREDOC
  #!/bin/bash
HEREDOC
}

resource "aws_instance" "bastion-win" {
  ami           = "${lookup(var.AmiWindows, var.region)}"
  instance_type = "${var.bastion-windows-instance-type}"
  associate_public_ip_address = "true"
  subnet_id = "${aws_subnet.PublicAZA.id}"
  vpc_security_group_ids = ["${aws_security_group.Bastion-Win.id}"]
  key_name = "${var.cluster-name}"
  tags {
        Name = "${var.cluster-name}-bastion-windows"
  }
  user_data = <<HEREDOC
  #!/bin/bash
HEREDOC
}

data "template_file" "userdata-ecrproxy" {
    template = "${file("templates/userdata-ecrproxy.sh.tpl")}"
}



resource "aws_instance" "dockerproxy-linux" {
  ami           = "${lookup(var.AmiLinux, var.region)}"
  instance_type = "${var.dockerproxy-linux-instance-type}"
  associate_public_ip_address = "true"
  subnet_id = "${aws_subnet.PublicAZA.id}"
  iam_instance_profile = "${aws_iam_instance_profile.ecrproxy-profile.name}"
  vpc_security_group_ids = ["${aws_security_group.dockerproxy-Linux.id}"]
  key_name = "${var.cluster-name}"  
  tags {
        Name = "${var.cluster-name}-dockerproxy-linux"
  }
  user_data = "${data.template_file.userdata-ecrproxy.rendered}"

}