# -----------------------------------
# S3 Bucket
# -----------------------------------
resource "aws_s3_bucket" "s3_static_bucket" {
  bucket = "${var.project}-${var.environment}-static-bucket"

  tags = {
    Name = "${var.project}-${var.environment}-static-bucket"
  }
}

# -----------------------------------
# Versioning（専用リソース）
# -----------------------------------
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.s3_static_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# -----------------------------------
# Encryption（サーバーサイド暗号化）
# -----------------------------------
resource "aws_s3_bucket_server_side_encryption_configuration" "sse" {
  bucket = aws_s3_bucket.s3_static_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# -----------------------------------
# Public Access Block（非公開設定）
# -----------------------------------
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket                  = aws_s3_bucket.s3_static_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -----------------------------------
# Bucket Policy（CloudFront OAI許可）
# -----------------------------------
data "aws_iam_policy_document" "s3_policy" {
  statement {
    sid    = "AllowCloudFrontAccess"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.s3_origin_identity.iam_arn]
    }

    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.s3_static_bucket.arn}/*"]
  }
}

resource "aws_s3_bucket_policy" "s3_policy" {
  bucket = aws_s3_bucket.s3_static_bucket.id
  policy = data.aws_iam_policy_document.s3_policy.json
}
