provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "my-vpc" {

  cidr_block = "10.0.0.0/16"
  tags       = { Name = "My-VPC" }
}

resource "aws_subnet" "publicsubnet1" {
  vpc_id                  = aws_vpc.my-vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags = {
    Name = "Public Subnet 1"
  }
}

resource "aws_subnet" "publicsubnet2" {
  vpc_id                  = aws_vpc.my-vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"
  tags = {
    Name = "Public Subnet 2"
  }
}
resource "aws_internet_gateway" "jenkinsigw" {
  vpc_id = aws_vpc.my-vpc.id
  tags = {
    Name = "Main VPC IGW"
  }
}

resource "aws_route_table" "mainvpcroutetable" {
  vpc_id = aws_vpc.my-vpc.id
  route{
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.jenkinsigw.id
  }
}

resource "aws_route_table_association" "pubsub1assn" {
  subnet_id      = aws_subnet.publicsubnet1.id
  route_table_id = aws_route_table.mainvpcroutetable.id
}

resource "aws_route_table_association" "pubsub2assn" {
  subnet_id      = aws_subnet.publicsubnet2.id
  route_table_id = aws_route_table.mainvpcroutetable.id
}

resource "aws_security_group" "jenkinssg" {
vpc_id = aws_vpc.my-vpc.id
  name        = "Jenkins-SG"
  description = "Security Group for Jenkins Server"
  ingress {
    description = "Allows SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
}

resource "aws_instance" "JenkinsServer" {
  ami                    = "ami-063d43db0594b521b"
  instance_type          = "t2.micro"
  key_name               = "jenkins"
  subnet_id              = aws_subnet.publicsubnet1.id
  vpc_security_group_ids = [aws_security_group.jenkinssg.id]
  for_each = toset(["JenkinsServer","AnsibleServer","KubeServer"])
  tags={
    Name= "${each.key}"
  }
}