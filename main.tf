terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {

      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.region
}


resource "aws_vpc" "techcorp" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "techcorp-vpc"
  }
}

# Public subnets
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.techcorp.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags                    = { Name = "techcorp-public-subnet-1" }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.techcorp.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true
  tags                    = { Name = "techcorp-public-subnet-2" }
}

# Private subnets
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.techcorp.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags              = { Name = "techcorp-private-subnet-1" }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.techcorp.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
  tags              = { Name = "techcorp-private-subnet-2" }
}

# Internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.techcorp.id
  tags   = { Name = "techcorp-igw" }
}

# Public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.techcorp.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "techcorp-public-rt" }
}

resource "aws_route_table_association" "public_assoc_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_assoc_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat_eip_1" {
  domain = "vpc"

}
resource "aws_eip" "nat_eip_2" {
  domain = "vpc"

}

# NAT Gateways (one per public subnet)
resource "aws_nat_gateway" "nat_1" {
  allocation_id = aws_eip.nat_eip_1.id
  subnet_id     = aws_subnet.public_1.id
  depends_on    = [aws_internet_gateway.igw]
  tags          = { Name = "techcorp-nat-1" }
}

resource "aws_nat_gateway" "nat_2" {
  allocation_id = aws_eip.nat_eip_2.id
  subnet_id     = aws_subnet.public_2.id
  depends_on    = [aws_internet_gateway.igw]
  tags          = { Name = "techcorp-nat-2" }
}

# Private route tables - route to respective NATs for high availability
resource "aws_route_table" "private_rt_1" {
  vpc_id = aws_vpc.techcorp.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_1.id
  }
  tags = { Name = "techcorp-private-rt-1" }
}

resource "aws_route_table" "private_rt_2" {
  vpc_id = aws_vpc.techcorp.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_2.id
  }
  tags = { Name = "techcorp-private-rt-2" }
}

resource "aws_route_table_association" "private_assoc_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_rt_1.id
}

resource "aws_route_table_association" "private_assoc_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private_rt_2.id
}


# Bastion SG
resource "aws_security_group" "bastion_sg" {
  name        = "techcorp-bastion-sg"
  description = "Allow SSH from office IP"
  vpc_id      = aws_vpc.techcorp.id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "bastion-sg" }
}

# Web SG
resource "aws_security_group" "web_sg" {
  name        = "techcorp-web-sg"
  description = "Allow HTTP/HTTPS from internet and SSH from bastion"
  vpc_id      = aws_vpc.techcorp.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description     = "SSH from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "web-sg" }
}

# Database SG
resource "aws_security_group" "db_sg" {
  name        = "techcorp-db-sg"
  description = "Allow Postgres from web servers and SSH from bastion"
  vpc_id      = aws_vpc.techcorp.id

  ingress {
    description     = "Postgres from web"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  ingress {
    description     = "SSH from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "db-sg" }
}


# Data sources
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

data "aws_availability_zones" "available" {}

# Key pair (optional) - use existing key pair name if provided.
# The user can also choose password login configured in user data below.
# Security note: password auth is less secure; change password after first login.

# Bastion host
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = var.bastion_instance_type
  subnet_id                   = aws_subnet.public_1.id
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  key_name                    = var.key_name
  associate_public_ip_address = true
  tags                        = { Name = "techcorp-bastion" }

  user_data = <<-EOF
              #!/bin/bash
              # ensure updates and install basic tools
              yum update -y
              yum install -y git jq
              # create admin user with password (change in production)
              useradd techadmin
              echo "techadmin:ChangeMe123!" | chpasswd
              sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config || true
              systemctl restart sshd || true
              EOF
}

resource "aws_eip_association" "bastion_eip_assoc" {
  instance_id   = aws_instance.bastion.id
  allocation_id = aws_eip.bastion_eip.id
}

resource "aws_eip" "bastion_eip" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.igw]
}

# Web servers - two instances, each in a private subnet
resource "aws_instance" "web_1" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = var.web_instance_type
  subnet_id                   = aws_subnet.private_1.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  key_name                    = var.key_name
  associate_public_ip_address = false
  user_data                   = file("${path.module}/user_data/web_server_setup.sh")
  tags                        = { Name = "techcorp-web-1" }
}

resource "aws_instance" "web_2" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = var.web_instance_type
  subnet_id                   = aws_subnet.private_2.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  key_name                    = var.key_name
  associate_public_ip_address = false
  user_data                   = file("${path.module}/user_data/web_server_setup.sh")
  tags                        = { Name = "techcorp-web-2" }
}

# Database server
resource "aws_instance" "db" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = var.db_instance_type
  subnet_id                   = aws_subnet.private_1.id
  vpc_security_group_ids      = [aws_security_group.db_sg.id]
  key_name                    = var.key_name
  associate_public_ip_address = false
  user_data                   = file("${path.module}/user_data/db_server_setup.sh")
  tags                        = { Name = "techcorp-db" }
}

resource "aws_lb" "app_lb" {
  name               = "techcorp-alb"
  load_balancer_type = "application"
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]
  security_groups    = [aws_security_group.web_sg.id]
  tags               = { Name = "techcorp-alb" }
}

resource "aws_lb_target_group" "web_tg" {
  name     = "techcorp-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.techcorp.id

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
    matcher             = "200-399"
  }
}

resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}


# Register web instances as targets
resource "aws_lb_target_group_attachment" "web1" {
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.web_1.id
  port             = 80
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "web2" {
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.web_2.id
  port             = 80
}
