provider "aws" {
  region = "ap-southeast-1"
}

# Create security group
resource "aws_security_group" "mongodb_sg" {
  name        = "mongodb_sg"
  description = "Allow SSH and MongoDB traffic"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create key pair
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  content  = tls_private_key.ssh_key.private_key_pem
  filename = "./.ssh/terraform_rsa"
}

resource "local_file" "public_key" {
  content  = tls_private_key.ssh_key.public_key_openssh
  filename = "./.ssh/terraform_rsa.pub"
}

resource "aws_key_pair" "deployer" {
  key_name   = "terraform_rsa"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

# Coolify needs 30GB of storage and 2GB of RAM
resource "aws_instance" "mongodb_instance" {
  ami           = "ami-003dd55e96a1e1f57"
  instance_type = "t2.small"
  key_name      = "terraform_rsa"
  vpc_security_group_ids = [aws_security_group.mongodb_sg.id]
  root_block_device {
    volume_size = 30
    volume_type = "gp2"
  }
  
  tags = {
    Name = "mongodb_instance"
  }

  user_data = <<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo curl -fsSL https://cdn.coollabs.io/coolify/install.sh | sudo bash
  EOF
}

output "instance_ip" {
  value = aws_instance.mongodb_instance.public_ip
}

# Output IP is <ip_address>:8000