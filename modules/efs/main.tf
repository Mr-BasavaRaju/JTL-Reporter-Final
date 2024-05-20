resource "aws_efs_file_system" "efs" {
  creation_token = "mongodb-efs"
  encrypted      = true
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
  performance_mode = "generalPurpose"

  tags = {
    Name = "efs-jtl-reporter"
  }
}
resource "aws_efs_access_point" "access_point" {
  file_system_id = aws_efs_file_system.efs.id
}

resource "aws_security_group" "efs_security_group" {
  vpc_id = var.vpc_id
  name   = "efs_security_group"
  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "efs_security_group"
  }
}
resource "aws_efs_mount_target" "mount_targets" {
  for_each        = toset(var.private_subnet_ids)
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs_security_group.id]
}
