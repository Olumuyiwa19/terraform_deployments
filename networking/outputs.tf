# -- networking/outputs.tf

output "vpc_id" {
  value = aws_vpc.replication_sandbox.id
}