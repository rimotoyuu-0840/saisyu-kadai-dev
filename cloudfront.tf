# -----------------------------------
# CloudFront Origin Access Identity
# -----------------------------------
resource "aws_cloudfront_origin_access_identity" "s3_origin_identity" {
  comment = "Access identity for S3 bucket"
}

# -----------------------------------
# CloudFront Distribution
# -----------------------------------
resource "aws_cloudfront_distribution" "cf" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "CloudFront distribution for ${var.project}-${var.environment}"
  price_class     = "PriceClass_200"

  aliases = [
    "${var.environment}.${var.domain}"
  ]

  # ALB Origin（動的コンテンツ）
  origin {
    domain_name = aws_lb.alb.dns_name
    origin_id   = "alb-origin"

    custom_origin_config {
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
      http_port              = 80
      https_port             = 443
    }
  }

  # S3 Origin（静的ファイル）
  origin {
    domain_name = aws_s3_bucket.s3_static_bucket.bucket_regional_domain_name
    origin_id   = "s3-origin"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.s3_origin_identity.cloudfront_access_identity_path
    }
  }

  # デフォルトビヘイビア（ALB）
  default_cache_behavior {
    target_origin_id       = "alb-origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD"]
    compress        = true

    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  # 静的コンテンツビヘイビア（S3）
  ordered_cache_behavior {
    path_pattern           = "/static/*"
    target_origin_id       = "s3-origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]
    compress        = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 86400
    max_ttl     = 31536000
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.virginia_cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["JP"]
    }
  }

  web_acl_id = aws_wafv2_web_acl.waf_cloudfront.arn

  tags = {
    Name = "${var.project}-${var.environment}-cf"
  }
}

# -----------------------------------
# WAF (日本のみ許可)
# -----------------------------------
resource "aws_wafv2_web_acl" "waf_cloudfront" {
  name        = "${var.project}-${var.environment}-waf"
  description = "Allow only Japan IPs for CloudFront"
  scope       = "CLOUDFRONT"
  default_action {
    block {}
  }

  rule {
    name     = "AllowJapan"
    priority = 1
    action {
      allow {}
    }
    statement {
      geo_match_statement {
        country_codes = ["JP"]
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AllowJapan"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "WAFMetrics"
    sampled_requests_enabled   = true
  }
}

# -----------------------------------
# Route53 Record for CloudFront
# -----------------------------------
resource "aws_route53_record" "cf_record" {
  zone_id = aws_route53_zone.route53_zone.zone_id
  name    = "${var.environment}.${var.domain}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cf.domain_name
    zone_id                = aws_cloudfront_distribution.cf.hosted_zone_id
    evaluate_target_health = false
  }
}
