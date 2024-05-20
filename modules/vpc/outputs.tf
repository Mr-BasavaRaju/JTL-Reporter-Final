output "vpc_id" {
  value = aws_vpc.main.id
}

output "private_subnets" {
  value = aws_subnet.private[*].id
}

output "public_subnets" {
  value = aws_subnet.public[*].id
}
output "aws_internet_gateway_id" {
  value = aws_internet_gateway.my_igw.id
}
output "public_route_table_id" {
  value = aws_route_table.public.id
}
output "private_route_table_id" {
  value = aws_route_table.private.id
}

output "security_group_id" {
  value = aws_security_group.my_security_group.id
}
