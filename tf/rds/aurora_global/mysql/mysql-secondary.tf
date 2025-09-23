module "db" {
  source = "terraform-aws-modules/rds-aurora/aws"

  # !! Change me
  global_cluster_identifier = "project-rds"

  name           = "${var.project_name}-rds"
  database_name  = "dev"
  engine         = "aurora-mysql"
  engine_version = "8.0.mysql_aurora.3.08.2"
  instance_class = "db.r6g.large"
  instances = {
    0 = {
      availability_zone = local.vpc_azs[0]
      instance_class    = "db.r6g.large"
    },
    1 = {
      availability_zone = local.vpc_azs[1]
      instance_class    = "db.r6g.large"
    }
  }

  is_primary_cluster = false

  port = 3307

  vpc_id               = local.vpc_id
  db_subnet_group_name = local.vpc_rds_subnet_group_names[0]
  security_group_rules = {
    vpc_ingress = {
      cidr_blocks = ["10.0.0.0/8"]
    }
  }

  manage_master_user_password = false
  master_username             = "myadmin"
  master_password             = "admin123!!"

  deletion_protection                 = true
  skip_final_snapshot                 = true
  apply_immediately                   = true
  kms_key_id                          = aws_kms_key.primary.arn
  iam_database_authentication_enabled = true

  cluster_performance_insights_enabled          = true
  cluster_performance_insights_retention_period = 465

  backup_retention_period                = 7
  performance_insights_enabled           = true
  performance_insights_retention_period  = 465
  database_insights_mode                 = "advanced"
  create_monitoring_role                 = true
  monitoring_interval                    = 30
  cloudwatch_log_group_retention_in_days = 7
  enabled_cloudwatch_logs_exports = [
    "audit",
    "error",
    "general",
    "slowquery"
  ]

  create_db_cluster_parameter_group           = true
  create_db_parameter_group                   = true
  db_cluster_parameter_group_family           = "aurora-mysql8.0"
  db_parameter_group_family                   = "aurora-mysql8.0"
  db_cluster_db_instance_parameter_group_name = "aurora-mysql8.0"
}

data "aws_iam_policy_document" "rds" {
  statement {
    sid       = "Enable IAM User Permissions"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.caller.account_id}:root",
        data.aws_caller_identity.caller.arn,
      ]
    }
  }

  statement {
    sid = "Allow use of the key"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]

    principals {
      type = "Service"
      identifiers = [
        "monitoring.rds.amazonaws.com",
        "rds.amazonaws.com",
      ]
    }
  }
}

resource "aws_kms_key" "primary" {
  policy = data.aws_iam_policy_document.rds.json
}

resource "aws_kms_alias" "primary" {
  name          = "alias/rds/${var.project_name}-rds"
  target_key_id = aws_kms_key.primary.key_id
}

resource "aws_db_cluster_snapshot" "init" {
  db_cluster_identifier          = module.db.cluster_id
  db_cluster_snapshot_identifier = "${module.db.cluster_id}-init"
}
