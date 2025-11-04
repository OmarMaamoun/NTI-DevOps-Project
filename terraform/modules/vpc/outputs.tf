output "vpc_id" {
  value = aws_vpc.main.id
}
output "public_subnet_id" {
  value = aws_subnet.public.id
}
output "private_subnet_id" {
  value = aws_subnet.private.id
}
output "security_group_id"{
  value=aws_security_group.dev-sg.id
}
output "db_sg_id"{
  value=aws_security_group.rds-sg.id
}
output "db_subnet_group_name" {
  value = aws_db_subnet_group.rds_subnet_group.name
}

output "public_subnet_id_az2" {
  value = aws_subnet.public_az2.id
}
output "private_subnet_id_az2" {
  value = aws_subnet.private_az2.id
}

output "eks_public_subnets" {
  value = [
    aws_subnet.public.id,
    aws_subnet.public_az2.id
  ]
}
output "eks_private_subnets" {
  value = [
    aws_subnet.private.id,
    aws_subnet.private_az2.id
  ]
}
