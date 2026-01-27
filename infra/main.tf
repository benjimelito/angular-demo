data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# --- RDS Security Group (allow Postgres from your IP) ---
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Allow Postgres from my IP"
  vpc_id      = data.aws_vpc.default.id
}

resource "aws_security_group_rule" "rds_postgres_ingress" {
  type              = "ingress"
  security_group_id = aws_security_group.rds.id
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = [var.my_ip_cidr]
}

# Allow DB to make outbound connections (default allow-all egress)
resource "aws_security_group_rule" "rds_egress" {
  type              = "egress"
  security_group_id = aws_security_group.rds.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

# --- RDS Postgres (simple, public for now) ---
resource "aws_db_instance" "postgres" {
  identifier        = "${var.project_name}-db"
  engine            = "postgres"
  engine_version    = "15"
  instance_class    = "db.t4g.micro"
  allocated_storage = 20

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  publicly_accessible    = true
  vpc_security_group_ids = [aws_security_group.rds.id]

  skip_final_snapshot   = true
  deletion_protection   = false
  backup_retention_period = 0
}

# --- Elastic Beanstalk (Node API) ---
resource "aws_elastic_beanstalk_application" "api" {
  name = "${var.project_name}-api"
}

data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eb_ec2_role" {
  name               = "${var.project_name}-eb-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

resource "aws_iam_role_policy_attachment" "eb_web_tier" {
  role       = aws_iam_role.eb_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_instance_profile" "eb_ec2_profile" {
  name = "${var.project_name}-eb-ec2-profile"
  role = aws_iam_role.eb_ec2_role.name
}

locals {
  database_url = "postgresql://${var.db_username}:${var.db_password}@${aws_db_instance.postgres.address}:5432/${var.db_name}?schema=public"
}

resource "aws_elastic_beanstalk_environment" "api_env" {
  name                = "${var.project_name}-api-env"
  application         = aws_elastic_beanstalk_application.api.name
  solution_stack_name = var.eb_solution_stack

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "SingleInstance"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_ec2_profile.name
  }

  # Environment variable your app & Prisma expect
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DATABASE_URL"
    value     = local.database_url
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "NODE_ENV"
    value     = "production"
  }
}
