# -----------------------------------
# ACM Certificate (Tokyo & Virginia)
# -----------------------------------

# ----- for Tokyo region (ALB 用) -----
resource "aws_acm_certificate" "tokyo_cert" {
  domain_name       = "*.${var.domain}"
  validation_method = "DNS"

  tags = {
    Name    = "${var.project}-${var.environment}-wildcard-sslcert-tokyo"
    Project = var.project
    Env     = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

# DNS 検証用レコードを Route53 に自動作成
resource "aws_route53_record" "tokyo_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.tokyo_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  allow_overwrite = true
  zone_id         = aws_route53_zone.route53_zone.zone_id
  name            = each.value.name
  type            = each.value.type
  ttl             = 600
  records         = [each.value.record]
}

# 東京リージョンの証明書検証完了リソース
resource "aws_acm_certificate_validation" "tokyo_validation" {
  certificate_arn         = aws_acm_certificate.tokyo_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.tokyo_cert_validation : record.fqdn]
}

# ----- for Virginia region (CloudFront 用) -----
resource "aws_acm_certificate" "virginia_cert" {
  provider          = aws.virginia
  domain_name       = "*.${var.domain}"
  validation_method = "DNS"

  tags = {
    Name    = "${var.project}-${var.environment}-wildcard-sslcert-virginia"
    Project = var.project
    Env     = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "virginia_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.virginia_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  allow_overwrite = true
  zone_id         = aws_route53_zone.route53_zone.zone_id
  name            = each.value.name
  type            = each.value.type
  ttl             = 600
  records         = [each.value.record]
}

resource "aws_acm_certificate_validation" "virginia_validation" {
  provider                = aws.virginia
  certificate_arn         = aws_acm_certificate.virginia_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.virginia_cert_validation : record.fqdn]
}

# 出力
output "acm_tokyo_cert_arn" {
  value = aws_acm_certificate.tokyo_cert.arn
}

output "acm_virginia_cert_arn" {
  value = aws_acm_certificate.virginia_cert.arn
}
