# ----- VARIABLES -----
locals {
  region       = "eu-west-1"
  az_1         = "${local.region}a" # availability zone eu-west-1c
  az_2         = "${local.region}c" # availability zone eu-west-1c
  app_template = "lt-0eb371797eb762caf" # launch template for app instances
  app_image    = "ami-0eace738484749e4b" # app instance image
  type         = "t2.micro" # defines the type of instance
  key          = "eng84devops" # defines the ssh key to be used
  key_path     = "C:\User\Ben\.ssh\eng84devops.pem"
}


# ----- DEFINE PROVIDER -----
provider "aws" { # provider is a keyword to define the cloud provider
  region = local.region # define the availability region for the instance
}


# ----- CREATE RESOURCES -----


# ----- VPC RESOURCES -----
# block of code to create a VPC
resource "aws_vpc" "final_vpc" {
  cidr_block       = "100.100.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "eng84_final_project_vpc"
  }
}

# ----- ROUTE TABLE -----
# create internet gateway
resource "aws_internet_gateway" "sav_tf_gate" {
  vpc_id = aws_vpc.sav_tf_vpc.id

  tags = {
    Name = "eng84_sav_tf_gateway"
  }
}

# create route table
resource "aws_route_table" "sav_tf_route" {
  vpc_id = aws_vpc.sav_tf_vpc.id
  # subnet_id = aws_subnet.sav_public_net_a.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sav_tf_gate.id
  }

  tags = {
    Name = "eng84_sav_tf_public_RT"
  }
}

# ----- CREATE SUBNETS -----
# block of code to create a public subnet in region eu-west-1a
resource "aws_subnet" "sav_public_net_a" {
  vpc_id                  = aws_vpc.sav_tf_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = "true" # makes it a public subnet
  availability_zone       = local.az_1
  # route_table = aws_route_table.sav_tf_route.id

  tags = {
    Name = "eng84_sav_tf_public_net_a"
  }
}

# block of code to create a public subnet in region eu-west-1c
resource "aws_subnet" "sav_public_net_b" {
  vpc_id                  = aws_vpc.sav_tf_vpc.id
  cidr_block              = "10.0.4.0/24"
  map_public_ip_on_launch = "true" # makes it a public subnet
  availability_zone       = local.az_2

  tags = {
    Name = "eng84_sav_tf_public_net_b"
  }
}

# block of code to create a private subnet
resource "aws_subnet" "sav_private_net" {
  vpc_id                  = aws_vpc.sav_tf_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = "false" # makes it a private subnet

  tags = {
    Name = "eng84_sav_tf_private_net"
  }
}

# ----- SUBNET RULES -----
# route table association to public subnet a
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.sav_public_net_a.id
  route_table_id = aws_route_table.sav_tf_route.id
}

# route table association to public subnet b
resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.sav_public_net_b.id
  route_table_id = aws_route_table.sav_tf_route.id
}

# route table association to public subnet ---- TEMP ----
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.sav_private_net.id
  route_table_id = aws_route_table.sav_tf_route.id # associated with public route table for debug
}

# ----- SECURITY GROUPS -----
# create a public security group
resource "aws_security_group" "sav_public_SG_1" {
  name        = "sav_public_SG_1"
  description = "allows inbound traffic"
  vpc_id      = aws_vpc.sav_tf_vpc.id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "eng84_sav_tf_public_SG_1"
  }
}

# create security group rule "http"
resource "aws_security_group_rule" "public_http_1" {
  description       = "allows access from the internet"
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.sav_public_SG_1.id
}

# create security group rule "ssh"
resource "aws_security_group_rule" "public_shh_1" {
  description       = "allows access from my IP"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["165.120.9.26/32"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.sav_public_SG_1.id
}

# create security group rule "self"
resource "aws_security_group_rule" "public_self_1" {
  description       = "allows access from itself"
  type              = "ingress"
  from_port         = "-1"
  to_port           = "-1"
  protocol          = "-1"
  cidr_blocks       = ["10.0.1.0/24"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.sav_public_SG_1.id
}

# create a public security group 2
resource "aws_security_group" "sav_public_SG_2" {
  name        = "sav_public_SG_2"
  description = "allows inbound traffic"
  vpc_id      = aws_vpc.sav_tf_vpc.id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "eng84_sav_tf_public_SG_2"
  }
}

# create security group rule "http"
resource "aws_security_group_rule" "public_http_2" {
  description       = "allows access from the internet"
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.sav_public_SG_2.id
}

# create security group rule "ssh"
resource "aws_security_group_rule" "public_shh_2" {
  description       = "allows access from my IP"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["165.120.9.26/32"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.sav_public_SG_2.id
}

# create security group rule "self"
resource "aws_security_group_rule" "public_self_2" {
  description       = "allows access from itself"
  type              = "ingress"
  from_port         = "-1"
  to_port           = "-1"
  protocol          = "-1"
  cidr_blocks       = ["10.0.1.0/24"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.sav_public_SG_2.id
}


# launching db EC2 instance from AMI
resource "aws_instance" "sav_tf_db" {
  ami = local.db_image # define the source image

  instance_type = local.type

  key_name = local.key

  private_ip = "10.0.2.100" # set the private ip

  associate_public_ip_address = true # for ssh

  subnet_id = aws_subnet.sav_private_net.id

  vpc_security_group_ids = [aws_security_group.sav_private_SG.id]

  tags = {
      Name = "eng84_sav_tf_db"
  }
}
