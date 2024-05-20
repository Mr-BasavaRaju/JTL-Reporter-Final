
# ECS Cluster
resource "aws_ecs_cluster" "my_cluster" {
  name = "jtl-reporter_cluster"
}

# ECS Task Definition
resource "aws_ecs_task_definition" "nginx" {
  family                   = "nginx"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048
  container_definitions = jsonencode([{
    name      = "nginx"
    image     = "nginx:latest"
    cpu       = 256
    memory    = 512
    essential = true
    portMappings = [{
      containerPort = 80
      hostPort      = 80
    }]
  }])
  task_role_arn      = aws_iam_role.ecs_task_execution_role.arn
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
}

resource "aws_ecs_task_definition" "JtlTaskDefinition" {
  family       = "JtlTaskDefinition"
  cpu          = 256
  memory       = 512
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  volume {
    name = "mongodb-efs"

    efs_volume_configuration {
      file_system_id = var.file_system
    }

  }
  container_definitions = jsonencode([
    {
      name = "jtl_reporter_fe"
      command = [
        "/bin/sh",
        "-c",
      "echo \" be fe listener mongodb\" >> /etc/hosts && nginx -g \"daemon off;\""]
      depends_on = [{
        condition = "START",
        container_name = "jtl_reporter_be" },
        { condition = "START",
      container_name = "jtl_reporter_mongodb" }]
      essential      = true
      cpu = 256
      memory = 512
      image          = "novyl/jtl-reporter-fe:v3.4.1"
      container_port = 3000
    },
    {
      name = "jtl_reporter_mongodb"
      command = [
        "/bin/sh",
        "-c",
      "echo 'db.createCollection(\"data-chunks\"); newCol = db.getCollection(\"data-chunks\"); newCol.createIndex({ dataId: -1 }, { name: \"data-id-index\" });' > /docker-entrypoint-initdb.d/mongo-init.js && /usr/local/bin/docker-entrypoint.sh mongod"]
      environment = [{
        name = "MONGO_INITDB_DATABASE",
      value = "jtl-data" }]
      essential = true
      image     = "mongo:4.2.5-bionic"
      mount_points = [{
        container_path = "/data/db/"
        source_volume  = "mongodb-efs"
      }]
    },
    {
      name = "jtl_reporter_be"
      command = [
        "/bin/sh",
        "-c",
      "echo \" be fe listener mongodb\" >> /etc/hosts && npm run start"]
      environment = [
        { name = "DB_HOST", value = var.psql_host },
        { name = "DB_PASS", value = var.psql_password },
        { name = "DB_USER", value = var.psql_user },
        { name = "JWT_TOKEN", value = "<jwt_token>" },
        { name = "JWT_TOKEN_LOGIN", value = "<jwt_token_login>" },
        { name = "MONGO_CONNECTION_STRING", value = "mongodb://mongodb:27017" }
      ]
      essential = true
      image     = "novyl/jtl-reporter-be:v3.4.2"
    },
    {
      name = "jtl_reporter_migration"
      command = [
        "/bin/sh",
        "-c",
      "echo \" be fe listener mongodb\" >> /etc/hosts && npm run migrate up"]
      environment = [{
        name = "DATABASE_URL",
      value = "postgres://<postgres>:<postgres>@<psqlhost>/jtl_report" }]
      essential = false
      image     = "novyl/jtl-reporter-be:v3.4.2"
    },
    {
      name = "jtl_reporter_listener"
      command = [
        "/bin/sh",
        "-c",
      "echo \" be fe listener mongodb\" >> /etc/hosts && npm run start"]
      environment = [
        { name = "JWT_TOKEN", value = "<jwt_token>" },
        { name = "MONGO_CONNECTION_STRING", value = "mongodb://mongodb:27017" }
      ]
      essential = true
      image     = "novyl/jtl-reporter-listener-service:v1.0.1"
    }
  ])

}

# ECS Service
resource "aws_ecs_service" "jtl_reporter_fe" {
  name            = "jtl-reporter-service"
  cluster         = aws_ecs_cluster.my_cluster.id
  task_definition = aws_ecs_task_definition.JtlTaskDefinition.arn
  desired_count   = 1


  # Load balancer configuration  
  load_balancer {
    target_group_arn = aws_lb_target_group.service_bridge.arn
    container_name   = "jtl_reporter_fe"
    container_port   = 3000
  }


  #iam_role    = aws_iam_role.ecs_task_execution_role.arn
  launch_type = "FARGATE"

  network_configuration {
    subnets          = var.public_subnets
    security_groups  = var.lb_sg
    assign_public_ip = true
  }
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole1"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "ECS Task Execution Role"
  }
}

# IAM Role Policy for ECS Task Execution Role
resource "aws_iam_role_policy" "ecs_task_execution_role_policy2" {
  name = "ecs_task_execution_role_policy2"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : "*"
      }
    ]
  })
}

# IAM Role Policy for ECS Task Execution Role
resource "aws_iam_role_policy" "ecs_task_execution_role_policy" {
  name = "ecs_task_execution_role_policy1"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow",
      Action = [
        "ec2:DescribeInstances",
        "ec2:DescribeInstanceStatus",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeSubnets",
        "ec2:DescribeRouteTables",
        "elasticloadbalancing:DescribeLoadBalancers",
        "elasticloadbalancing:DescribeTargetGroups",
        "elasticloadbalancing:DescribeListeners",
        "elasticloadbalancing:DescribeRules",
        "elasticloadbalancing:RegisterTargets",
        "elasticloadbalancing:DeregisterTargets",

      ],
      Resource = "*"
    }]
  })
}

# IAM Role for ECS Service
resource "aws_iam_role" "ecs_service_role" {
  name = "ecsServiceRole1"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ecs.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "ECS Service Role"
  }
}

resource "aws_lb" "test" {
  name                       = "test-lb-tf"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = var.lb_sg
  subnets                    = var.public_subnets
  enable_deletion_protection = false

  tags = {
    Environment = "production"
  }
}

resource "aws_lb_target_group" "service_bridge" {
  port                 = 80 # Service traffic port
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = var.vpc_id
  deregistration_delay = 300

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
    matcher             = "200-299"
    path                = "/"
    protocol            = "HTTP"
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.test.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service_bridge.arn
  }
}

# Security Group
resource "aws_security_group" "lb_sg" {
  vpc_id = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}