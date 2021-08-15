provider "aws" {
  region = "us-east-2"
  access_key = "AKIAXU6QPVUUG5WXCGUM"
  secret_key = "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"
}

resource "aws_instance" "web-app" {
  ami           = "ami-0443305dabd4be2bc"
  instance_type = "t2.micro"
  server_role = "web"
  key_name      = "Ohio-key"
  subnet_id = "${module.vpc_subnets.public_subnets_id}"
  security_group_id = ""

  tags = {
    Name = "web_app"
    Owner = "armkenigsberg"
  }

}

resource "aws_instance" "web-app-2" {
  ami           = "ami-0443305dabd4be2bc"
  instance_type = "t2.micro"
  key_name      = "Ohio-key"

  tags = {
    Name = "web_app_2"
    Owner = "armkenigsberg"
  }

}

resource "aws_instance" "web-app-3" {
  ami           = "ami-0443305dabd4be2bc"
  instance_type = "t2.micro"
  key_name      = "Ohio-key"

  tags = {
    Name = "web_app_3"
    Owner = "armkenigsberg"
  }

}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "wep-app-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-2a", "us-east-2b", "us-east-2c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = true

  #tags = {
  #  Terraform = ""
  #  Environment = ""
  #}
}

module "elb" {
	source = "./modules/elb"
	name = "web-app-elb"
	environment = "dev"
	security_groups = "${module.elb_sg.elb_sg_id}"
	availability_zones = "us-east-2a, us-east-2b, us-east-2c"
	subnets = "${module.vpc_subnets.public_subnets_id}"
	instance_id = "${module.ec2.ec2_id}"
}

resource "aws_launch_configuration" "as_conf" {
  name          = "web-app-launch-conf"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
}

resource "aws_placement_group" "web-app-autoscale" {
  name     = "web-app-autoscale"
  strategy = "cluster"
}

resource "aws_autoscaling_group" "web-app-autoscal-group" {
  name                      = "web-app-autoscal-group"
  max_size                  = 6
  min_size                  = 3
  health_check_grace_period = 100
  health_check_type         = "ELB"
  desired_capacity          = 3
  force_delete              = true
  #placement_group          = aws_placement_group.test.id
  #launch_configuration     = aws_launch_configuration.foobar.name
  vpc_zone_identifier       = [aws_subnet.wep-app-vpc.id]

}
