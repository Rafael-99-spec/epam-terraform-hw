provider "aws" {
  region = "us-east-2"
  access_key = "AKIAXU6QPVUUHD4HKPQS"
  secret_key = "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"
}

resource "aws_instance" "web-app" {
  ami                    = "ami-0443305dabd4be2bc"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow_http.id]
  user_data              =  <<EOF
#!/bin/bash
yum -y update
yum -y install httpd
webipaddress=`curl http://169.254.169.254/latest/meta-data/local-ipv4`  
echo "WebServer1 : $webipaddress" > /var/www/html/index.html
sudo systemctl restart httpd
sudo systemctl enable httpd
EOF
  tags = {
    Name  = "web_app"
    Owner = "armkenigsberg"
  }

}

resource "aws_instance" "web-app-2" {
  ami                    = "ami-0443305dabd4be2bc"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow_http.id]
  user_data              =  <<EOF
#!/bin/bash
yum -y update
yum -y install httpd
webipaddress=`curl http://169.254.169.254/latest/meta-data/local-ipv4`  
echo "WebServer2 : $webipaddress" > /var/www/html/index.html
sudo systemctl restart httpd
sudo systemctl enable httpd
EOF

  tags = {
    Name  = "web_app_2"
    Owner = "armkenigsberg"
  }

}

resource "aws_instance" "web-app-3" {
  ami                    = "ami-0443305dabd4be2bc"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow_http.id]
  user_data              =  <<EOF
#!/bin/bash
yum -y update
yum -y install httpd
webipaddress=`curl http://169.254.169.254/latest/meta-data/local-ipv4`  
echo "WebServer3 : $webipaddress" > /var/www/html/index.html
sudo systemctl restart httpd
sudo systemctl enable httpd
EOF

  tags = {
    Name = "web_app_3"
    Owner = "armkenigsberg"
  }

}




resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allow http inbound traffic"

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

# Create a new load balancer
resource "aws_elb" "bar" {
  name               = "foobar-terraform-elb"
  availability_zones = ["us-east-2a", "us-east-2b", "us-east-2c"]
  security_groups    = [aws_security_group.allow_http.id]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 10
    unhealthy_threshold = 2
    timeout             = 5
    target              = "HTTP:80/"
    interval            = 30
  }

  instances                   = [aws_instance..id]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "foobar-terraform-elb"
  }
}
