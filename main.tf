provider "aws" {
  region = "eu-central-1"
}

variable vpc_cidr_block {}
variable subnet_cidr_block {}
variable avail_zone {}
variable env_prefix {}
variable ssh_ips {}
variable public_key_location {}

resource "aws_vpc" "terraform-aws" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "${var.env_prefix}-vpc"
  }
}

resource "aws_subnet" "terraform-aws-subnet" {
  vpc_id = aws_vpc.terraform-aws.id
  cidr_block = var.subnet_cidr_block
  availability_zone = var.avail_zone
  tags = {
    Name = "${var.env_prefix}-subnet-1"
  }
}

resource "aws_default_route_table" "terraform-aws-route" {
  default_route_table_id = aws_vpc.terraform-aws.default_route_table_id
  route {
    cidr_block="0.0.0.0/0"
    gateway_id = aws_internet_gateway.terraform-aws-igw.id 
  }
  tags = {
    Name = "${var.env_prefix}-routes"
  }
}

resource "aws_internet_gateway" "terraform-aws-igw" {
  vpc_id = aws_vpc.terraform-aws.id
  tags = {
    Name = "${var.env_prefix}-igw"
  }
}

resource "aws_default_security_group" "terraform-aws-sg" {
  vpc_id = aws_vpc.terraform-aws.id
  // incoming traffic rule
  ingress {
  // range of open ports for incoming
    from_port = 22
    to_port = 22
  // usable protocol
    protocol = "tcp"
  // IP filtering, only IPs from this list allows to make a SSH connection
    cidr_blocks = var.ssh_ips
  }

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // outgoing traffic
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    prefix_list_ids = []
  }

  tags = {
    Name = "${var.env_prefix}-firewall"
  }

}

data "aws_ami" "latest-amazon-linux-image" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-*"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]

  }
}

resource "aws_key_pair" "ssh_key" {
  key_name = "ssh_key-ec2"
  public_key = file(var.public_key_location)
}


resource "aws_instance" "terraform-aws-ec" {
  ami = data.aws_ami.latest-amazon-linux-image.id
  instance_type = "t2.micro" // could be variable for stage/prod/dev difference
  tags = {
    Name = "${var.env_prefix}-ec2"
  }
  subnet_id = aws_subnet.terraform-aws-subnet.id
  vpc_security_group_ids = [aws_default_security_group.terraform-aws-sg.id]
  availability_zone = var.avail_zone
  associate_public_ip_address = true // access container from browser
  key_name = aws_key_pair.ssh_key.key_name
  user_data = file("entry_script.sh")
}
