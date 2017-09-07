variable "cluster-name" {
  default = "venus.je"
}

variable "region" {
  default = "eu-west-1"
}

variable "AmiLinux" {
  type = "map"
  default = {
    eu-west-2 = "ami-785db401"
    eu-central-1 = "ami-1e339e71"
    eu-west-1 = "ami-785db401"
  }
  description = ""
}
variable "AmiWindows" {
  type = "map"
  default = {
    eu-west-2 = "ami-70e5f414"
    eu-central-1 = "ami-331eb05c"
    eu-west-1 = "ami-4763923e"
  }
  description = ""
}

variable "aws_access_key" {
  default = ""
  description = "the user aws access key"
}
variable "aws_secret_key" {
  default = ""
  description = "the user aws secret key"
}
variable "vpc-fullcidr" {
  default = "10.111.0.0/16"
  description = "the vpc cdir"
}
variable "Subnet-Public-AzA-CIDR" {
  default = "10.111.1.0/24"
  description = "the cidr of the subnet"
}

variable "Subnet-Master-CIDR" {
  default = "10.111.2.0/24"
  description = "the cidr of the subnet"
}

variable "Subnet-Nodes-CIDR" {
  default = "10.111.3.0/24"
  description = "the cidr of the subnet"
}

variable "core-availability-zone" {
  default = "eu-west-1a"
  description = "main availability zone" 
}

variable "DnsZoneName" {
  default = "venus.internal"
  description = "the internal dns name"
}

variable "bastion-linux-instance-type" {
  default = "t2.micro"
  description = "linux bastion instance type"
}

variable "bastion-windows-instance-type" {
  default = "t2.medium"
  description = "windows bastion instance type"
}

variable "master-linux-instance-type" {
  default = "t2.medium"
  description = "linux master node instance type"
}

variable "gateway-linux-instance-type" {
  default = "t2.medium"
  description = "linux gateway node instance type"
}

variable "node-linux-instance-type" {
  default = "t2.medium"
  description = "linux master node instance type"
}

variable "node-windows-instance-type" {
  default = "m4.large"
  description = "linux master node instance type"
}

variable "dockerproxy-linux-instance-type" {
  default = "t2.medium"
  description = "linux dockerproxy instance type"
}

