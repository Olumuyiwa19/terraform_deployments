# -- networking/main.tf

data "aws_availability_zones" "available" {}

resource "random_integer" "random" {
  min = 1
  max = 100
}

resource "random_shuffle" "az_list" {
  input        = data.aws_availability_zones.available.names
  result_count = var.max_subnets
}

resource "aws_vpc" "replication_sandbox" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "replication_sandbox-${random_integer.random.id}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_subnet" "replication_sandbox_public_subnet" {
  count                   = var.pub_subnet_count
  vpc_id                  = aws_vpc.replication_sandbox.id
  cidr_block              = var.public_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone       = random_shuffle.az_list.result[count.index]

  tags = {
    Name = "replication_sandboxy_public_subnet_${count.index + 1}"
  }
}

resource "aws_subnet" "replication_sandbox_private_subnet" {

  count                   = var.priv_subnet_count
  vpc_id                  = aws_vpc.replication_sandbox.id
  cidr_block              = var.private_cidrs[count.index]
  map_public_ip_on_launch = false
  availability_zone       = random_shuffle.az_list.result[count.index]

  tags = {
    Name = "replication_sandboxy_private_subnet_${count.index + 1}"
  }
}


resource "aws_internet_gateway" "replication-gw" {
  vpc_id = aws_vpc.replication_sandbox.id

  tags = {
    Name = "replication_sandbox_route_table-gw"
  }
}

resource "aws_route_table" "replication_sandbox_route_table" {
  vpc_id = aws_vpc.replication_sandbox.id

  tags = {
    Name = "replication_sandbox_rt"
  }
}

resource "aws_route_table" "replication_sandbox_route_table_priv" {
  vpc_id = aws_vpc.replication_sandbox.id

  tags = {
    Name = "replication_sandbox_rt"
  }
}


resource "aws_route_table_association" "route_table_association" {
  count          = var.pub_subnet_count
  subnet_id      = aws_subnet.replication_sandbox_public_subnet.*.id[count.index]
  route_table_id = aws_route_table.replication_sandbox_route_table.id
}

resource "aws_route" "route" {
  route_table_id         = aws_route_table.replication_sandbox_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.replication-gw.id
}

resource "aws_route" "nat_route" {
  count = 1
  route_table_id         = aws_route_table.replication_sandbox_route_table_priv.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id   =  aws_nat_gateway.nat[count.index].id
}

resource "aws_eip" "eip-nat-gw" {
  vpc = true
  depends_on = [aws_internet_gateway.replication-gw]
}



resource "aws_nat_gateway" "nat" {

count = 1
allocation_id = aws_eip.eip-nat-gw.id
subnet_id =  aws_subnet.replication_sandbox_public_subnet.*.id[count.index]
depends_on = [aws_internet_gateway.replication-gw]
}
resource "aws_default_route_table" "replication_default_rt" {

  default_route_table_id = aws_vpc.replication_sandbox.default_route_table_id

  tags = {
    Name = "replication_sandbox_rt"
  }

}

resource "aws_security_group" "allow_ephemeral_ports" {
  name        = "allow_ephemeral_ports"
  description = "allow_ephemeral_ports"

  vpc_id      = aws_vpc.replication_sandbox.id

  ingress {
    
    description = "allow ephemeral ports"
    from_port   = 1024
    to_port     =  65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ephemeral_ports"
  }
}

data "aws_ami" "microsoft" {
  most_recent = true
  #use aws ec2 describe-images --filters "Name=platform,Values=windows" --owners amazon | grep -i  -A10 -B10 sql
  filter {
    name   = "name"
    values = ["EC2LaunchV2_Preview-Windows_Server-2019-English-Full-SQL_2019_Express-2020.10.14"]
  }
 
  owners = ["amazon"] # Canonical
}

resource "aws_instance" "sql_server_private" {

  count = 1
  security_groups = [aws_security_group.allow_ephemeral_ports.id]
  ami = data.aws_ami.microsoft.id
  instance_type = "t2.2xlarge"
  subnet_id =  aws_subnet.replication_sandbox_private_subnet.*.id[count.index]
  key_name = "WINDOWS_EC2_2"
  tags = {
    Name = "sql_server_private",
    auto-delete: "no"
  }
}

resource "aws_instance" "sql_server_public" {
  count = 1
  security_groups = [aws_security_group.allow_ephemeral_ports.id]
  ami = data.aws_ami.microsoft.id
  instance_type = "t2.2xlarge"
  subnet_id =  aws_subnet.replication_sandbox_public_subnet.*.id[count.index]
  key_name = "WINDOWS_EC2_2"

  tags = {
    Name = "sql_server_public",
    auto-delete: "no"
  }
}


resource "aws_lambda_function" "lambda_test_deployment" {
  
  role =   aws_iam_role.sts_iam_role.arn
  function_name = "deployedWithTerraform" 
  handler       = "lambda_handler.lambda_handler"
  s3_bucket = "deploy-to-me"
  s3_key = "lambda_handler.zip"

  runtime = "python3.8"
  count = 1
   vpc_config {
    # aws_subnet.replication_sandbox_private_subnet.*.id[count.index]
    subnet_ids  = [aws_subnet.replication_sandbox_private_subnet[0].id]
    security_group_ids = [aws_security_group.allow_ephemeral_ports.id]
  }
 
}
#https://stackoverflow.com/questions/57288992/terraform-how-to-create-iam-role-for-aws-lambda-and-deploy-both
resource "aws_iam_role" "sts_iam_role" {
  name = "basic_sts_role_lambda"
# https://stackoverflow.com/questions/63430774/terraform-lambda-function-validation-exception
  assume_role_policy = <<-EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "catchAll" {
   policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "*",
        "Resource": "*"
        }
     ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "mergeRolePolicy" {
  role       = aws_iam_role.sts_iam_role.name
  policy_arn = aws_iam_policy.catchAll.arn
}

