# =====================================
# SSM Parameters（DB接続情報）
# =====================================

resource "aws_ssm_parameter" "mysql_host" {
  name  = "/${var.project}/${var.environment}/MYSQL_HOST"
  type  = "String"
  value = aws_db_instance.mysql_standalone.address
}

resource "aws_ssm_parameter" "mysql_port" {
  name  = "/${var.project}/${var.environment}/MYSQL_PORT"
  type  = "String"
  value = aws_db_instance.mysql_standalone.port
}

resource "aws_ssm_parameter" "mysql_database" {
  name  = "/${var.project}/${var.environment}/MYSQL_DATABASE"
  type  = "String"
  value = aws_db_instance.mysql_standalone.db_name
}

resource "aws_ssm_parameter" "mysql_username" {
  name  = "/${var.project}/${var.environment}/MYSQL_USERNAME"
  type  = "SecureString"
  value = aws_db_instance.mysql_standalone.username
}

resource "aws_ssm_parameter" "mysql_password" {
  name  = "/${var.project}/${var.environment}/MYSQL_PASSWORD"
  type  = "SecureString"
  value = aws_db_instance.mysql_standalone.password
}
