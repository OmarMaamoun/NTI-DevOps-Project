resource "aws_backup_vault" "jenkins_vault" {
  name        = var.vault_name
  kms_key_arn = null
  tags = {
    Name = "${var.environment}-BackupVault"
  }
}
resource "aws_backup_plan" "daily_backup" {
  name = "${var.backup_name}-daily-backup-plan"

  rule {
    rule_name         = "daily-backup"
    target_vault_name = aws_backup_vault.jenkins_vault.name
    schedule          = var.schedule
    start_window      = 60   
    completion_window = 180    

    lifecycle {
      delete_after = 7
    }
  }
}
resource "aws_iam_role" "aws_backup_role" {
  name = "aws-backup-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "aws_backup_role_policy" {
  role       = aws_iam_role.aws_backup_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_backup_selection" "jenkins_selection" {
  name         = "${var.backup_name}-selection"
  iam_role_arn = aws_iam_role.aws_backup_role.arn
  plan_id      = aws_backup_plan.daily_backup.id
  resources = [var.resource_arn]
}