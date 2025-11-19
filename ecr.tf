# -----------------------------------
# ECR Repository (Laravel App)
# -----------------------------------
resource "aws_ecr_repository" "app_ecr" {
  name                 = "nagoyameshi-app" # ← Buildspec.yml と噛み合わせる
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name    = "nagoyameshi-app"
    Project = var.project
    Env     = var.environment
  }
}

# -----------------------------------
# (Optional) Delete old images automatically
# -----------------------------------
resource "aws_ecr_lifecycle_policy" "clean_old_images" {
  repository = aws_ecr_repository.app_ecr.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Delete old images, keep only last 10"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# -----------------------------------
# Output (ECR URI)
# -----------------------------------
output "ecr_repository_url" {
  value = aws_ecr_repository.app_ecr.repository_url
}
