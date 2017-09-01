
resource "aws_iam_instance_profile" "bastion-nodes-profile" {
  name  = "${var.cluster-name}-bastion-nodes-profile"
  role = "${aws_iam_role.bastion-nodes-iam.name}"
}

resource "aws_iam_role" "bastion-nodes-iam" {
  name = "${var.cluster-name}-bastion-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "master-nodes-profile" {
  name  = "${var.cluster-name}-master-nodes-profile"
  role = "${aws_iam_role.master-nodes-iam.name}"
}

resource "aws_iam_role" "master-nodes-iam" {
  name = "${var.cluster-name}-master-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "nodes-profile" {
  name  = "${var.cluster-name}-nodes-profile"
  role = "${aws_iam_role.nodes-iam.name}"
}

resource "aws_iam_role" "nodes-iam" {
  name = "${var.cluster-name}-nodes-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}