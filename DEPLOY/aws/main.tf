terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC for RDS and App Runner
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.app_name}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.aws_region}a", "${var.aws_region}b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
}

# Security Group for RDS
resource "aws_security_group" "rds_sg" {
  name        = "${var.app_name}-rds-sg"
  description = "Allow PostgreSQL access from App Runner"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# RDS Instance
resource "aws_db_instance" "default" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = "14"
  instance_class       = "db.t4g.micro"
  db_name              = "proxydb"
  username             = var.db_username
  password             = var.db_password
  parameter_group_name = "default.postgres14"
  skip_final_snapshot  = true
  publicly_accessible  = false
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.default.name
}

resource "aws_db_subnet_group" "default" {
  name       = "${var.app_name}-db-subnet-group"
  subnet_ids = module.vpc.private_subnets

  tags = {
    Name = "My DB subnet group"
  }
}

# App Runner Service
resource "aws_apprunner_service" "service" {
  service_name = "${var.app_name}-service"

  source_configuration {
    image_repository {
      image_identifier      = var.image_identifier
      image_repository_type = "ECR" # Or ECR_PUBLIC
      image_configuration {
        port = var.port
        runtime_environment_variables = {
          DATABASE_URL = "postgres://${var.db_username}:${var.db_password}@${aws_db_instance.default.address}:5432/proxydb?sslmode=require"
          PORT         = var.port
          LOG_LEVEL    = "3"
        }
      }
    }
    auto_deployments_enabled = true
    authentication_configuration {
      # access_role_arn = aws_iam_role.apprunner_role.arn # Needed for private ECR
    }
  }

  network_configuration {
    egress_configuration {
      egress_type       = "VPC"
      vpc_connector_arn = aws_apprunner_vpc_connector.connector.arn
    }
  }
}

resource "aws_apprunner_vpc_connector" "connector" {
  vpc_connector_name = "${var.app_name}-vpc-connector"
  subnets            = module.vpc.private_subnets
  security_groups    = [aws_security_group.rds_sg.id]
}
