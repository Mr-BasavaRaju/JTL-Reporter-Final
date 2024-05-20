output "psql_host" {
  value = aws_db_instance.db-test1.endpoint
}

output "psql_password" {
  value = aws_db_instance.db-test1.password
}

output "psql_user" {
  value = aws_db_instance.db-test1.username
}