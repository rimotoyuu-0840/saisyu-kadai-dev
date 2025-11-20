# -----------------------------------
# Application Load Balancer (ALB)
# -----------------------------------
resource "aws_lb" "alb" {
  name               = "${var.project}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_sg.id]
  subnets = [
    aws_subnet.public_subnet_1a.id,
    aws_subnet.public_subnet_1c.id
  ]

  tags = {
    Name = "${var.project}-${var.environment}-alb"
  }
}

# -----------------------------------
# Target Group (Fargate用)
# -----------------------------------
resource "aws_lb_target_group" "alb_target_group" {
  name        = "${var.project}-${var.environment}-tg"
  port        = 80 # ← Apacheが80で待ち受けるため変更
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc.id
  target_type = "ip" # ← Fargateは必ず ip

  health_check {
    protocol            = "HTTP"
    path                = "/health"
    port                = "traffic-port"
    interval            = 30
    timeout             = 20
    healthy_threshold   = 3
    unhealthy_threshold = 5
    matcher             = "200"
  }

  tags = {
    Name = "${var.project}-${var.environment}-tg"
  }
}

# -----------------------------------
# HTTP Listener (HTTP → HTTPS へリダイレクト)
# -----------------------------------
resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# -----------------------------------
# HTTPS Listener (ACM証明書)
# -----------------------------------
resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.tokyo_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group.arn
  }
}

