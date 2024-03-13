resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    name = "web-vpc"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.0.0/24"
  map_public_ip_on_launch = true
  tags = {
    name = "web-public-subnet"
  }
}

resource "aws_security_group" "my-security-group" {
  vpc_id = aws_vpc.my_vpc.id
  name = "web-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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

resource "aws_instance" "web-ec2-instance" {
  ami             = "ami-0440d3b780d96b29d"
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.public_subnet.id
  key_name = "web-key"
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install httpd -y
              systemctl start httpd
              systemctl enable httpd
              firewall-cmd --add-service=http --permanent
              systemctl reload firewalld
              echo "Hello From Abdelsalam Website :)" >> var/www/html/index.html
              EOF

  tags = {
    Name = "Web-Instance"
  }

  security_groups = [aws_security_group.my-security-group.id]  

}

resource "aws_eip" "myeip" {
  instance = aws_instance.web-ec2-instance.id
}

resource "aws_eip_association" "myeip-association" {
  instance_id = aws_instance.web-ec2-instance.id
  allocation_id = aws_eip.myeip.id  
}

resource "aws_internet_gateway" "myinternet-gw" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    name = "web-igw"
  }
}

resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.my_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myinternet-gw.id
  }
  tags = {
    name = "web-rt"
  }
}

resource "aws_route_table_association" "public-route-table" {
  route_table_id = aws_route_table.public-route-table.id
  subnet_id = aws_subnet.public_subnet.id
}