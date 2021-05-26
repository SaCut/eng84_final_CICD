# let's initialise terraform
# Providers?
# AWS

# This code will eventually launch an EC2 instance for us


# ----- VARIABLES -----
locals {
  region       = "eu-west-1"
  az_1         = "${local.region}a" # availability zone eu-west-1a
  az_2         = "${local.region}b" # availability zone eu-west-1b
  az_3         = "${local.region}c" # availability zone eu-west-1b
  app_template = "lt-0eb371797eb762caf" # launch template for app instances
  app_image    = "ami-0e2629010839f707e" # app instance image
  type         = "t2.micro" # defines the type of instance
  key          = "eng84devops" # defines the ssh key to be used
  key_path     = "~/.ssh/eng84devops.pem"
}


# ----- DEFINE PROVIDER -----
provider "aws" { # provider is a keyword to define the cloud provider
  region = local.region # define the availability region for the instance
}


# ----- CREATE RESOURCES -----


# ----- VPC RESOURCES -----

# block of code to create a VPC
resource "aws_vpc" "project_vpc" {
  cidr_block       = "80.90.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "eng84_final_project_vpc"
  }
}

# ----- ROUTE TABLE -----
# create internet gateway
resource "aws_internet_gateway" "project_gate" {
  vpc_id = aws_vpc.project_vpc.id

  tags = {
    Name = "eng84_final_project_gateway"
  }
}

# create route table
resource "aws_route_table" "project_route" {
  vpc_id = aws_vpc.project_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.project_gate.id
  }

  tags = {
    Name = "eng84_final_project_public_RT"
  }
}

# ----- CREATE SUBNETS -----
# block of code to create a public subnet in region eu-west-1a
resource "aws_subnet" "project_net_a" {
  vpc_id                  = aws_vpc.project_vpc.id
  cidr_block              = "80.90.101.0/24"
  map_public_ip_on_launch = "true" # makes it a public subnet
  availability_zone       = local.az_1
  # route_table = aws_route_table.project_route.id

  tags = {
    Name = "eng84_final_project_net_a"
  }
}

# block of code to create a public subnet in region eu-west-1b
resource "aws_subnet" "project_net_b" {
  vpc_id                  = aws_vpc.project_vpc.id
  cidr_block              = "80.90.102.0/24"
  map_public_ip_on_launch = "true" # makes it a public subnet
  availability_zone       = local.az_2
  # route_table = aws_route_table.project_route.id

  tags = {
    Name = "eng84_final_project_net_b"
  }
}

# block of code to create a public subnet in region eu-west-1c
resource "aws_subnet" "project_net_c" {
  vpc_id                  = aws_vpc.project_vpc.id
  cidr_block              = "80.90.103.0/24"
  map_public_ip_on_launch = "true" # makes it a public subnet
  availability_zone       = local.az_3
  # route_table = aws_route_table.project_route.id

  tags = {
    Name = "eng84_final_project_net_c"
  }
}

# ----- SUBNET RULES -----
# route table association to public subnet a
resource "aws_route_table_association" "project_route_a" {
  subnet_id      = aws_subnet.project_net_a.id
  route_table_id = aws_route_table.project_route.id
}

# route table association to public subnet b
resource "aws_route_table_association" "project_route_b" {
  subnet_id      = aws_subnet.project_net_b.id
  route_table_id = aws_route_table.project_route.id
}

# route table association to public subnet c
resource "aws_route_table_association" "project_route_c" {
  subnet_id      = aws_subnet.project_net_c.id
  route_table_id = aws_route_table.project_route.id
}

# ----- SECURITY GROUPS -----
# create a public security group
resource "aws_security_group" "project_SG_a" {
  name        = "project_SG_a"
  description = "allows inbound traffic"
  vpc_id      = aws_vpc.project_vpc.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["217.44.147.236/32"] 
  }
  ingress {
    from_port = 0 
    to_port = 0
    protocol = -1
    cidr_blocks = ["217.155.15.136/32"] 
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "eng84_final_project_SG_a"
  }
}

# # create security group rule "http"
# resource "aws_security_group_rule" "project_http" {
#   description       = "allows access from the internet"
#   type              = "ingress"
#   from_port         = 80
#   to_port           = 80
#   protocol          = "tcp"
#   cidr_blocks       = ["0.0.0.0/0"]
#   ipv6_cidr_blocks  = ["::/0"]
#   security_group_id = aws_security_group.project_SG_a.id
# }

# # create security group rule "ssh"
# resource "aws_security_group_rule" "public_shh_a" {
#   description       = "allows access from my IP"
#   type              = "ingress"
#   from_port         = 22
#   to_port           = 22
#   protocol          = "tcp"
#   cidr_blocks       = ["217.44.147.236/32"]
#   ipv6_cidr_blocks  = ["::/0"]
#   security_group_id = aws_security_group.project_SG_a.id
# }

# # create security group rule "ssh"
# resource "aws_security_group_rule" "public_shh_b" {
#   description       = "allows access from Jenkins (Ben) IP"
#   type              = "ingress"
#   from_port         = 22
#   to_port           = 22
#   protocol          = "tcp"
#   cidr_blocks       = ["217.155.15.136/32"]
#   ipv6_cidr_blocks  = ["::/0"]
#   security_group_id = aws_security_group.project_SG_a.id
# }



# ----- AUTO SCALER -----
# create launch configuration
resource "aws_launch_template" "project_launch_app" {
  name   = "eng84_final_project_tpl"
  image_id      = local.app_image
  ebs_optimized = false
  instance_type = local.type
  key_name      = local.key

  network_interfaces {
    associate_public_ip_address = true
    security_groups = [aws_security_group.project_SG_a.id]
  }

  tags = {
    Name = "eng84_final_project_launch_template"
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "project_auto_scale" {
  name                 = "eng84_final_project_auto_scale"
  vpc_zone_identifier  = [
    aws_subnet.project_net_a.id,
    aws_subnet.project_net_b.id,
    aws_subnet.project_net_c.id
  ]
  desired_capacity     = 2
  max_size             = 5
  min_size             = 1
  health_check_type    = "EC2"
  target_group_arns    = ["${aws_lb_target_group.project_target_a.arn}"]
  depends_on           = [aws_launch_template.project_launch_app, aws_lb_listener.project_listen_a]

  launch_template {
    id      = aws_launch_template.project_launch_app.id
    version = "$Latest"
  }

  lifecycle {
    ignore_changes = [target_group_arns]
  }

  tag {
    key                 = "Name"
    value               = "eng84_final_project_flask_app"
    propagate_at_launch = true
  }
}



# ----- LOAD BALANCER -----
# create target group 1
resource "aws_lb_target_group" "project_target_a" {
  name        = "eng84-final-project-TG-1"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.project_vpc.id

  tags = {
    Name = "eng84_final_project_TG_1"
  }
}

# create listener
resource "aws_lb_listener" "project_listen_a" {
  load_balancer_arn = aws_lb.project_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.project_target_a.arn
  }
}

# create load balancer
resource "aws_lb" "project_lb" {
  name               = "eng84-final-project-load"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.project_SG_a.id,]
  subnets            = [
    aws_subnet.project_net_a.id,
    aws_subnet.project_net_b.id,
    aws_subnet.project_net_c.id
  ]

  enable_deletion_protection = false

  tags = {
    Name = "eng84_final_project_load_balancer"
  }
}

