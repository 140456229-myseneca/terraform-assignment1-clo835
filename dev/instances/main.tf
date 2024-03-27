#----------------------------------------------------------
# CLO835 - Assignment1 - p2
#----------------------------------------------------------


# Define the provider

provider "aws" {
  region = "us-east-1"
}


# Data source for AMI id

data "aws_ami" "latest_amazon_linux" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}


# Data source for availability zones in us-east-1

data "aws_availability_zones" "available" {
  state = "available"
}


# Data block to retrieve the default VPC id

data "aws_vpc" "default" {
  default = true
}


# Define tags locally

locals {
  default_tags = merge(module.globalvars.default_tags, { "env" = var.env })
  prefix       = module.globalvars.prefix
  name_prefix  = "${local.prefix}-${var.env}"
}


# Retrieve global variables from the Terraform module
module "globalvars" {
  source = "../../modules/globalvars"
}


# Reference subnet provisioned by 01-Networking 

resource "aws_instance" "my_amazon" {
  ami                         = data.aws_ami.latest_amazon_linux.id
  instance_type               = lookup(var.instance_type, var.env)
  key_name                    = aws_key_pair.my_key.key_name
  vpc_security_group_ids      = [aws_security_group.my_sg.id]
  iam_instance_profile   = "LabInstanceProfile"
  associate_public_ip_address = false

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.default_tags,
    {
      "Name" = "${local.name_prefix}-Amazon-Linux"
    }
  )
}


# Adding SSH key to Amazon EC2

resource "aws_key_pair" "my_key" {
  key_name   = local.name_prefix
  public_key = file("${local.name_prefix}.pub")
}


# Security Group

resource "aws_security_group" "my_sg" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description      = "SSH from everywhere"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  
  ingress {
    description      = "HTTP from everywhere"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    }
    
  ingress {
    description      = "port 8081 custom TCP"
    from_port        = 8081
    to_port          = 8081
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  
  ingress {
    description      = "port 8082 custom TCP"
    from_port        = 8082
    to_port          = 8082
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  
  ingress {
    description      = "port 8083 custom TCP"
    from_port        = 8083
    to_port          = 8083
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    }
    
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = merge(local.default_tags,
    {
      "Name" = "${local.name_prefix}-sg"
    }
  )
}


# Define ECR repo to store database images

resource "aws_ecr_repository" "database" {
  name         = "db-repo-docker"
  force_delete = true
  tags = {
    Name = "docker-${var.env}-db-ecrr"
  }
}


# Define ECR repo to store application images

resource "aws_ecr_repository" "application" {
  name         = "app-repo-docker"
  force_delete = true
  tags = {
    Name = "docker-${var.env}-app-ecrr"
  }
}


# Elastic IP of EC2

resource "aws_eip" "static_eip" {
  instance = aws_instance.my_amazon.id
  tags = merge(local.default_tags,
    {
      "Name" = "${local.name_prefix}-eip"
    }
  )
}