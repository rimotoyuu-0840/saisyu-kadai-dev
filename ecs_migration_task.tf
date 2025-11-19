# -----------------------------------
# ECS Task Definition (Migration)
# -----------------------------------
resource "aws_ecs_task_definition" "nagoyameshi_migration_task" {
  family                   = "nagoyameshi-migration-task"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "nagoyameshi-migration"
      image     = "${aws_ecr_repository.app_ecr.repository_url}:latest"
      essential = true

      command = [
        "php",
        "artisan",
        "migrate",
        "--force"
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_log_group.name
          awslogs-region        = "ap-northeast-1"
          awslogs-stream-prefix = "migration"
        }
      }

      environment = [
        { name = "DB_HOST", value = aws_ssm_parameter.mysql_host.value },
        { name = "DB_PORT", value = aws_ssm_parameter.mysql_port.value },
        { name = "DB_DATABASE", value = aws_ssm_parameter.mysql_database.value },
        { name = "DB_USERNAME", value = aws_ssm_parameter.mysql_username.value },
        { name = "DB_PASSWORD", value = aws_ssm_parameter.mysql_password.value }
      ]
    }
  ])
}
