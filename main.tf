terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

resource "aws_security_group" "allow_access" {
 name        = "allow_access"
 description = "Allow traffic"

  ingress {
    from_port = 80
    protocol = "tcp"
    to_port = 80
    security_groups = [aws_security_group.alb.id]
  }  

 egress {
   from_port        = 0
   to_port          = 0
   protocol         = "-1"
   cidr_blocks      = ["0.0.0.0/0"]
 }
}

data "aws_subnet" "az_a"{
  availability_zone = "us-east-1a"
}

data "aws_subnet" "az_b"{
  availability_zone = "us-east-1b"
}

data "aws_subnet" "az_c"{
  availability_zone = "us-east-1c"
}

resource "aws_instance" "servidor1" {
  ami = "ami-052efd3df9dad4825"
  instance_type = "t2.micro"
  #us-east-1a
  subnet_id = data.aws_subnet.az_a.id
  vpc_security_group_ids = [ aws_security_group.allow_access.id ]
  user_data = <<-EOF
  #!/bin/bash
  sudo apt update -y
  sudo apt install apache2 -y
  echo "Instancia 1" > /var/www/html/index.html
  sudo service apache2 restart
  exit
  EOF
  tags = {
    Name = "servidor1"
  }
}

resource "aws_instance" "servidor2" {
  ami = "ami-052efd3df9dad4825"
  instance_type = "t2.micro"
  #us-east-1b
  subnet_id = data.aws_subnet.az_b.id
  vpc_security_group_ids = [ aws_security_group.allow_access.id ]
  user_data = <<-EOF
  #!/bin/bash
  sudo apt update -y
  sudo apt install apache2 -y
  echo "Instancia 2" > /var/www/html/index.html
  sudo service apache2 restart
  exit
  EOF
  tags = {
    Name = "servidor2"
  }
}

resource "aws_instance" "servidor3" {
  ami = "ami-052efd3df9dad4825"
  instance_type = "t2.micro"
  #us-east-1c
  subnet_id = data.aws_subnet.az_c.id
  vpc_security_group_ids = [ aws_security_group.allow_access.id ]
  user_data = <<-EOF
  #!/bin/bash
  sudo apt update -y
  sudo apt install apache2 -y
  echo "Instancia 3" > /var/www/html/index.html
  sudo service apache2 restart
  exit
  EOF
  tags = {
    Name = "servidor3"
  }
}

resource "aws_lb" "alb" {
  load_balancer_type = "application"
  name = "terraform-alb"
  security_groups = [aws_security_group.alb.id]
  subnets = [data.aws_subnet.az_a.id, data.aws_subnet.az_b.id, data.aws_subnet.az_c.id]
}

resource "aws_security_group" "alb" {
  name = "alb-sg"  
    ingress {
      from_port = 80
      protocol = "tcp"
      to_port = 80
      cidr_blocks = ["0.0.0.0/0"]
  }

    egress {
      from_port = 80
      protocol = "tcp"
      to_port = 80
      cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_lb_target_group" "this" {
  name = "terraform-alb-target-group"
  port = 80
  vpc_id = data.aws_vpc.default.id
  protocol = "HTTP"

  health_check {
    enabled = true
    matcher =  "200"
    path = "/"
    port = "80"
    protocol = "HTTP"
  }
}

resource "aws_lb_target_group_attachment" "servidor_1" {
  target_group_arn = aws_lb_target_group.this.arn
  target_id = aws_instance.servidor1.id
  port = 80
}

resource "aws_lb_target_group_attachment" "servidor_2" {
  target_group_arn = aws_lb_target_group.this.arn
  target_id = aws_instance.servidor2.id
  port = 80
}

resource "aws_lb_target_group_attachment" "servidor_3" {
  target_group_arn = aws_lb_target_group.this.arn
  target_id = aws_instance.servidor3.id
  port = 80
}

resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.alb.arn
  port = 80
  protocol = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.this.arn
    type = "forward"
  }
}