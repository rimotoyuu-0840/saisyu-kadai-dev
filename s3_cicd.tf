resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "${var.project}-${var.environment}-codepipeline-bucket"

  tags = {
    Name = "${var.project}-${var.environment}-codepipeline-bucket"
  }
}
