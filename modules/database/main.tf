resource "aws_db_subnet_group" "default" {
  name       = "jtl_reporter_db_subnet_group"
  subnet_ids = var.private_subnets

  tags = {
    Name = "My DB subnet group"
  }
}

resource "aws_security_group" "allow_postgres_traffic" {
  name        = "allow_postgres"
  description = "Allow Postgres traffic"
  vpc_id      = var.vpc_id

  ingress {
    description = "allow Postgres"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow postgres"
  }
}

resource "aws_db_instance" "db-test1" {
  allocated_storage      = 10
  identifier             = "postgres-test2"
  db_subnet_group_name   = aws_db_subnet_group.default.id
  engine                 = "postgres"
  engine_version         = "14"
  instance_class         = "db.t3.micro"
  username               = "postgres"
  password               = "postgres"
  vpc_security_group_ids = [aws_security_group.allow_postgres_traffic.id]
  publicly_accessible    = false
  skip_final_snapshot    = true
}
