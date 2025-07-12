# Terraform Configuration for AWS RDS PostgreSQL with an Advanced Backup Strategy
#
# This configuration provisions:
# 1. An RDS PostgreSQL database instance.
# 2. An AWS Backup Vault in the primary region.
# 3. An AWS Backup Vault in a secondary (DR) region.
# 4. An IAM Role for AWS Backup service.
# 5. A comprehensive AWS Backup Plan that:
#    - Enables point-in-time recovery for the last 30 days via RDS automated backups.
#    - Creates weekly full backups that are retained for one year (365 days).
#    - Copies these weekly backups to a different AWS region for disaster recovery.
# 6. An AWS Backup Selection to apply the plan to the RDS instance.


provider "aws" {
  region = "us-east-1"
}

# 2nd provider for the dr region
provider "aws" {
  alias  = "dr_region"
  region = "us-west-2"
}

# used default VPC and subnets for RDS,  but need to replace using existing or new VPC resources.
data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

resource "aws_db_subnet_group" "default" {
  name       = "main-db-subnet-group"
  subnet_ids = data.aws_subnet_ids.default.ids

  tags = {
    Name = "Main DB Subnet Group"
  }
}

# PostgreSQL instance. Clear text password could be replaced with a secure method.
resource "aws_db_instance" "postgres_db" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "14.6"
  instance_class       = "db.t3.micro"
  db_name              = "mydatabase"
  username             = "adminuser"
  password             = "YourSecurePassword123"
  db_subnet_group_name = aws_db_subnet_group.default.name
  skip_final_snapshot  = true

  # Point-in-Time-Recovery PITR enabled
  backup_retention_period = 30


  tags = {
    Name = "Postgres-DB-For-Backup"
  }
}

# iam assume role
resource "aws_iam_role" "backup_role" {
  name = "aws-backup-service-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "backup_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = aws_iam_role.backup_role.name
}

# Vault configuration
resource "aws_backup_vault" "primary_vault" {
  name = "primary-rds-backup-vault"
}

resource "aws_backup_vault" "dr_vault" {
  provider = aws.dr_region
  name     = "dr-rds-backup-vault"
}

# backup config schedule, retention, and cross-region copy actions.
resource "aws_backup_plan" "rds_backup_plan" {
  name = "rds-postgres-backup-plan"

  rule {
    rule_name         = "WeeklyFullBackups"
    target_vault_name = aws_backup_vault.primary_vault.name
    schedule          = "cron(0 5 ? * SAT *)" # Every Saturday at 5 AM UTC

    # retain weekly
    lifecycle {
      delete_after = 365
    }

    # cross-region copy for dr
    copy_action {
      destination_vault_arn = aws_backup_vault.dr_vault.arn
      lifecycle {
        delete_after = 365
      }
    }
  }

  tags = {
    Name = "RDSBackupPlan"
  }
}

# 
resource "aws_backup_selection" "rds_selection" {
  iam_role_arn = aws_iam_role.backup_role.arn
  name         = "rds-postgres-selection"
  plan_id      = aws_backup_plan.rds_backup_plan.id

  resources = [
    aws_db_instance.postgres_db.arn
  ]
}

# --- Outputs ---
output "rds_instance_endpoint" {
  description = "The endpoint of the RDS PostgreSQL instance."
  value       = aws_db_instance.postgres_db.endpoint
}

output "primary_backup_vault_name" {
  description = "The name of the primary AWS Backup vault."
  value       = aws_backup_vault.primary_vault.name
}

output "dr_backup_vault_name" {
  description = "The name of the disaster recovery AWS Backup vault."
  value       = aws_backup_vault.dr_vault.name
}
# --- End of Configuration ---
