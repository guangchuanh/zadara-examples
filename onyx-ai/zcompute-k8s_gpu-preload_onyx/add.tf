variable "nlb_source_cidr" {
  description = "Allowed source CIDR for NLB security group"
  type        = string
}

# security group
resource "aws_security_group" "my_home" {
  name        = "myhome"
  description = "For my home ipaddress"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow HTTP"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.nlb_source_cidr]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # all
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# target group
resource "aws_lb_target_group" "targetgroup" {
  name        = "onyx-nodeport-31080"
  protocol    = "TCP"
  port        = 31080
  target_type = "ip"
  vpc_id      = module.vpc.vpc_id
}

# NLB need は手動作成する必要がある！
#resource "aws_lb" "nlb" {
#  name               = "onyx-nlb"
#  internal           = false
#  load_balancer_type = "network"
#  subnets            = module.vpc.public_subnets
#}



