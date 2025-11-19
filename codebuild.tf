# -----------------------------------
# CodeBuild Project
# -----------------------------------
resource "aws_codebuild_project" "nagoyameshi_project" {
  name          = "${var.project}-${var.environment}-codebuild"
  service_role  = aws_iam_role.codebuild_role.arn
  build_timeout = 30

  # CodePipeline 出力の受け取り & 出力も渡す
  artifacts {
    type = "CODEPIPELINE"
  }

  # GitHub ソースは CodePipeline が渡すのでこれだけ
  source {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:7.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      name  = "REPOSITORY_URI"
      value = aws_ecr_repository.app_ecr.repository_url
    }

    environment_variable {
      name  = "CONTAINER_NAME"
      value = "nagoyameshi-app"
    }

    environment_variable {
      name  = "ECS_CLUSTER_NAME"
      value = aws_ecs_cluster.app_cluster.name
    }

    environment_variable {
      name  = "MIGRATION_TASK_DEFINITION"
      value = aws_ecs_task_definition.nagoyameshi_migration_task.family
    }

    environment_variable {
      name  = "SUBNET_ID_1"
      value = aws_subnet.private_subnet_1a.id
    }

    environment_variable {
      name  = "SUBNET_ID_2"
      value = aws_subnet.private_subnet_1c.id
    }

    environment_variable {
      name  = "SECURITY_GROUP_ID"
      value = aws_security_group.app_sg.id
    }
  }
}
