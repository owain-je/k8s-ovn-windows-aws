resource "aws_security_group" "Master-Linux" {
  name = "${var.cluster-name}-master-linux"
  tags {
        Name = "${var.cluster-name}-master-linux"
  }
  description = "master linux connections"
  vpc_id = "${aws_vpc.terraformmain.id}"

  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "Node" {
  name = "${var.cluster-name}-node"
  tags {
        Name = "${var.cluster-name}-node"
  }
  description = "master node connections"
  vpc_id = "${aws_vpc.terraformmain.id}"

  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "Bastion-Linux" {
  name = "${var.cluster-name}-bastion-linux"
  tags {
        Name = "${var.cluster-name}-bastion-linux"
  }
  description = "bastion linux connections"
  vpc_id = "${aws_vpc.terraformmain.id}"

  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "Bastion-Win" {
  name = "${var.cluster-name}-bastion-win"
  tags {
        Name = "${var.cluster-name}-bastion-win"
  }
  description = "bastion win connections"
  vpc_id = "${aws_vpc.terraformmain.id}"

  ingress {
    from_port   = "3389"
    to_port     = "3389"
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

