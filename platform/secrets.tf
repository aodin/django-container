# Secerts are generated here and never written to source control
# AWS Secrets Manager takes a minimum of 7 days and a default of 30 days to delete
# a secret, unless you force an immediate deletion using the CLI


resource "random_password" "django_secret_key" {
  length  = 64
  special = false
}

resource "aws_secretsmanager_secret" "django_secret_key" {
  name        = "${local.name}/django-secret-key"
  description = "Django SECRET_KEY for ${local.name}"

  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "django_secret_key" {
  secret_id     = aws_secretsmanager_secret.django_secret_key.id
  secret_string = random_password.django_secret_key.result
}

resource "random_password" "db" {
  length  = 40
  special = false # RDS rejects several punctuation characters in master passwords
}

resource "aws_secretsmanager_secret" "db_password" {
  name        = "${local.name}/db-password"
  description = "RDS master password for ${local.name}"

  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db.result
}
