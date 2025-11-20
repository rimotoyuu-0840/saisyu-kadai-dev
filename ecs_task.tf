# -----------------------------------
# CloudWatch Logs Group
# -----------------------------------
resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/${var.project}-${var.environment}"
  retention_in_days = 7

  tags = {
    Name = "${var.project}-${var.environment}-log-group"
  }
}

# -----------------------------------
# ECS Task Execution Role
# -----------------------------------
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project}-${var.environment}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_ecr_read" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# -----------------------------------
# ECS Task Role（アプリが使うロール）
# -----------------------------------
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project}-${var.environment}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# SSMパラメータ読み取り
resource "aws_iam_role_policy_attachment" "ecs_task_ssm_read" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}


# -----------------------------------
# Task Definition (Laravel + Apache)
# -----------------------------------
resource "aws_ecs_task_definition" "nagoyameshi_task" {
  depends_on = [aws_cloudwatch_log_group.ecs_log_group]

  family                   = "nagoyameshi-app"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"  # 最小構成
  memory                   = "1024" # 最小構成
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "nagoyameshi-app"
      image     = "${aws_ecr_repository.app_ecr.repository_url}:latest"
      essential = true

      portMappings = [{
        containerPort = 80
        hostPort      = 80
        protocol      = "tcp"
      }]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_log_group.name
          awslogs-region        = "ap-northeast-1"
          awslogs-stream-prefix = "ecs"
        }
      }

      environment = [
        # SSMパラメータを環境変数に読み込む
        { name = "APP_KEY", value = "base64:BHUgpqmN22cyp6fF98YCaAgM8Q+uwsm0pOGNGQEU3ok=" },
        { name = "DB_HOST", value = aws_ssm_parameter.mysql_host.value },
        { name = "DB_PORT", value = aws_ssm_parameter.mysql_port.value },
        { name = "DB_DATABASE", value = aws_ssm_parameter.mysql_database.value },
        { name = "DB_USERNAME", value = aws_ssm_parameter.mysql_username.value },
        { name = "DB_PASSWORD", value = random_string.db_password.result }
      ]
    }
  ])
}
