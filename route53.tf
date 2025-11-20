# ---------------------------------
# Route53
# ---------------------------------
data "aws_route53_zone" "route53_zone" {
  name = "${var.domain}."
}

resource "aws_route53_record" "alb_record" {
  zone_id = data.aws_route53_zone.route53_zone.zone_id
  name    = "${var.subdomain}.${var.domain}"
  type    = "A"

  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = true
  }
}
