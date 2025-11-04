resource "aws_db_instance" "mydb" {
  identifier              = "${var.environment}-db"
  engine                  = var.engine
  instance_class          = var.rds_instance_type
  allocated_storage       = 20
  db_name                 = var.db_name
  username                = var.db_username
  password                = var.db_password
  skip_final_snapshot     = true
  publicly_accessible     = false
  vpc_security_group_ids  = [var.db_sg_id]
  db_subnet_group_name    = var.db_subnet_group
  
  backup_retention_period = 7

  tags = {
    Name = "${var.environment}-rds"
  }
}


resource "aws_secretsmanager_secret" "rds_credentials" {
  name = "${var.environment}-rds-credential-secrets"
}

resource "aws_secretsmanager_secret_version" "rds_credentials_value" {
  secret_id     = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
  })
}
