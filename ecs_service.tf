# -----------------------------------
# ECS Service (with ALB)
# -----------------------------------
resource "aws_ecs_service" "nagoyameshi_service" {
  name            = "${var.project}-${var.environment}-service"
  cluster         = aws_ecs_cluster.app_cluster.id
  task_definition = aws_ecs_task_definition.nagoyameshi_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  # デプロイ時のパラメータ（ローリングアップデート推奨設定）
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  # ECS Exec を使って artisanコマンド等が叩ける
  enable_execute_command = true

  network_configuration {
    subnets          = [aws_subnet.private_subnet_1a.id, aws_subnet.private_subnet_1c.id]
    security_groups  = [aws_security_group.app_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.alb_target_group.arn
    container_name   = "nagoyameshi-app"
    container_port   = 80
  }

  depends_on = [
    aws_lb_listener.https_listener,
    aws_lb_target_group.alb_target_group
  ]
}
