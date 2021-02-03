# -- root/networking/main.tf


module "networking" {
  source            = "./networking"
  vpc_cidr          = local.vpc_cidr
  access_ip         = var.access_ip
  security_groups   =  ""
  pub_subnet_count  = 4
  priv_subnet_count = 3
  max_subnets       = 20
  public_cidrs      = [for i in range(2, 255, 2) : cidrsubnet(local.vpc_cidr, 8, i)]
  private_cidrs     = [for i in range(1, 255, 2) : cidrsubnet(local.vpc_cidr, 8, i)]
}


# resource "aws_key_pair" "replicate_issues" {
#   key_name   = "replicate_issues"
#   public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCyurfbU5VRBvX8+oCJyKBIGwx78cOsZ8KUFy9GkQqzzo4AXxOk/Y1Rs6VSu40dv0z3wwUXjkeF8oX9eTKmJw8oyY9NufoCtWdFBlsaHHexO2zQSzbVj5p5sSpoTyBCoWf4xImxqWVPGW0AI2zl2qSPyKBkynYjQunlYCNj7qg/2LQ/D88jTYxAqIGU4+ch1dUqMnVIkb5oEfoTmN/W6tkUVY3APmEz023iZkpqiSQO/jbBxFC1YSEeH8S6onZiT76E17XG0cJwV/g7pU87VlMndLRYnZesLPTBZSw8aQUGJYleRsQ5c1QXiAlWVb86G5tEx0tNm5bn0sf/JI5uxWD1 ellarnol@38f9d3401647.ant.amazon.com"
# }


# # terraform import aws_security_group.allow_ephemeral_ports sg-090b030a8b8308a60
# resource "aws_security_group" "allow_ephemeral_ports" {
#   name        = "allow_ephemeral_ports"
#   description = "allow_ephemeral_ports"
#   count                   = var.pub_subnet_count
#   vpc_id      = aws_vpc.replication_sandbox.id

#   ingress {
    
#     description = "allow ephemeral ports"
#     from_port   = 1024
#     to_port     =  65535
#     protocol    = "tcp"
#     cidr_blocks = [aws_vpc.replication_sandbox.cidr_block]
#   }

   
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "allow_ephemeral_ports"
#   }
# }
