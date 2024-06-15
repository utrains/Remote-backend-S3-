terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.67.0" 
    }
  }
}

# Configure the AWS provider

provider "aws" {
  region = var.region
}

# The below code is for creating a vpc

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = "true" #gives you an internal domain name
  enable_dns_hostnames = "true" #gives you an internal host name
  instance_tenancy     = "default"
}

# Create Public Subnet for the jenkins server

resource "aws_subnet" "subnet-public-1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.subnet1_cidr
  map_public_ip_on_launch = "true" //it makes this a public subnet
  availability_zone       = var.AZ1

}

# Create IGW for internet connection 
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

}

# Creating Route table 

resource "aws_route_table" "public-routetab" {
  vpc_id = aws_vpc.vpc.id

  route {
    //associated subnet can reach everywhere
    cidr_block = "0.0.0.0/0"
    //CRT uses this IGW to reach internet
    gateway_id = aws_internet_gateway.igw.id
  }

}

# Associating route tabe to public subnet

resource "aws_route_table_association" "public-routetab-subnet-1" {
  subnet_id      = aws_subnet.subnet-public-1.id
  route_table_id = aws_route_table.public-routetab.id

}

# Generate a secure key using a rsa algorithm

resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Creating the keypair in aws

resource "aws_key_pair" "ec2_key" {
  key_name   = var.keypair_name                 
  public_key = tls_private_key.ec2_key.public_key_openssh 
}

# Save the .pem file locally for remote connection

resource "local_file" "ssh_key" {
  filename        = var.keypair_location
  content         = tls_private_key.ec2_key.private_key_pem
  file_permission = "0400"
}

# Security group for the jenkins server

resource "aws_security_group" "ec2_allow_rule" {

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "allow ssh,http,https"
  }

}

# Create an ec2 instance for the Jenkins server
resource "aws_instance" "jenkins-ec2" {
  ami                    = var.aws_ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.subnet-public-1.id
  vpc_security_group_ids = ["${aws_security_group.ec2_allow_rule.id}"]
  user_data              = "${file("userdata.sh")}"
  key_name               = aws_key_pair.ec2_key.key_name
  tags = {
    Name = "jenkins-server"
  }

 }

# Here we configure the remote BACKEND to enable others to work on the same code
terraform {
  backend "s3" {
    bucket = "remote-backend-bucket-1"       // Paste the id of the bucket we priviously created 
    key    = "terraform.tfstate"           // Paste the key of the same bucket
    region = "us-east-2"
    dynamodb_table = "terraform-locking"   // From the DynamoDB table we previously created to prevent the state file from being corrupted when more than one collaborator executes the Terraform Apply command at the same time
    encrypt = true
  }
}

# Print the link to be redirected to the jenkins server

output "INFO" {
  value = "AWS Resources and Jenkins Server has been provisioned. Go to http://${aws_instance.jenkins-ec2.public_ip}:8080"
}

