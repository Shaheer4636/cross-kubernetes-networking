provider "aws" {
  alias  = "east"
  region = "us-east-1"
}

provider "aws" {
  alias  = "west"
  region = "us-west-2"
}

# SSH Key (Replace with your real key)
resource "aws_key_pair" "default" {
  key_name   = "cross-region"
  public_key = file("~/.ssh/id_rsa.pub")
}

# VPC East
resource "aws_vpc" "vpc_east" {
  provider             = aws.east
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "vpc-east"
  }
}

resource "aws_internet_gateway" "igw_east" {
  provider = aws.east
  vpc_id   = aws_vpc.vpc_east.id
}

resource "aws_subnet" "subnet_east" {
  provider          = aws.east
  vpc_id            = aws_vpc.vpc_east.id
  cidr_block        = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"
}

resource "aws_route_table" "rt_east" {
  provider = aws.east
  vpc_id   = aws_vpc.vpc_east.id
}

resource "aws_route" "default_route_east" {
  provider               = aws.east
  route_table_id         = aws_route_table.rt_east.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw_east.id
}

resource "aws_route_table_association" "rta_east" {
  provider       = aws.east
  subnet_id      = aws_subnet.subnet_east.id
  route_table_id = aws_route_table.rt_east.id
}

# VPC West
resource "aws_vpc" "vpc_west" {
  provider             = aws.west
  cidr_block           = "10.1.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "vpc-west"
  }
}

resource "aws_internet_gateway" "igw_west" {
  provider = aws.west
  vpc_id   = aws_vpc.vpc_west.id
}

resource "aws_subnet" "subnet_west" {
  provider          = aws.west
  vpc_id            = aws_vpc.vpc_west.id
  cidr_block        = "10.1.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-west-2a"
}

resource "aws_route_table" "rt_west" {
  provider = aws.west
  vpc_id   = aws_vpc.vpc_west.id
}

resource "aws_route" "default_route_west" {
  provider               = aws.west
  route_table_id         = aws_route_table.rt_west.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw_west.id
}

resource "aws_route_table_association" "rta_west" {
  provider       = aws.west
  subnet_id      = aws_subnet.subnet_west.id
  route_table_id = aws_route_table.rt_west.id
}

# Security Group - East
resource "aws_security_group" "sg_common" {
  name        = "allow-bgp-ssh"
  description = "Allow SSH, BGP, OVN, and ICMP"
  vpc_id      = aws_vpc.vpc_east.id
  provider    = aws.east

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 179
    to_port     = 179
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 6641
    to_port     = 6642
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group - West
resource "aws_security_group" "sg_common_west" {
  name        = "allow-bgp-ssh"
  description = "Allow SSH, BGP, OVN, and ICMP"
  vpc_id      = aws_vpc.vpc_west.id
  provider    = aws.west

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 179
    to_port     = 179
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 6641
    to_port     = 6642
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ec2_east" {
  provider                  = aws.east
  ami                       = "ami-0a7d80731ae1b2435"  # Ubuntu 22.04 LTS
  instance_type             = "t3.medium"
  subnet_id                 = aws_subnet.subnet_east.id
  key_name                  = aws_key_pair.default.key_name
  vpc_security_group_ids    = [aws_security_group.sg_common.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  user_data = <<-EOF
    #!/bin/bash
    apt update -y
    apt install -y snapd
    snap install amazon-ssm-agent --classic
    systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
    systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service
  EOF

  tags = {
    Name = "k8s-east-node"
  }
}


resource "aws_instance" "ec2_west" {
  provider                  = aws.west
  ami                       = "ami-0ec1bf4a8f92e7bd1"
  instance_type             = "t3.medium"
  subnet_id                 = aws_subnet.subnet_west.id
  key_name                  = aws_key_pair.default.key_name
  vpc_security_group_ids    = [aws_security_group.sg_common_west.id]
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    apt update -y
    apt install -y snapd
    snap install amazon-ssm-agent --classic
    systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
    systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service
  EOF

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  ebs_block_device {
    device_name = "/dev/sdf"
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "k8s-west-node"
  }
}

