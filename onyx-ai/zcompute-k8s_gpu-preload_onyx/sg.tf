# my-home
resource "aws_security_group" "my_home" {
  name        = "${var.cluster_name}_myhome"
  description = "NLB for my home ipaddress"
  vpc_id      = data.aws_vpc.this.id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.bastion_ssh_source_cidr]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # all
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}
