resource "random_password" "rds_user_password" {
  length  = 24
  special = false
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "${var.project_prefix}-${var.environment}-subnet-group"
  subnet_ids = var.vpc_subnets

  tags = {
    Name = "${var.project_prefix}-${var.environment}-subnet-group"
    Environment = var.environment
  }
}

resource "aws_rds_cluster_instance" "rds_cluster_instances" {
  identifier          = "${var.project_prefix}-${var.environment}-node"
  cluster_identifier  = aws_rds_cluster.rds_cluster.id
  instance_class      = var.aurora_rds_cluster.instance_type
  publicly_accessible = var.aurora_rds_cluster.publicly_accessible
  engine              = aws_rds_cluster.rds_cluster.engine
  engine_version      = aws_rds_cluster.rds_cluster.engine_version
}
resource "aws_rds_cluster" "rds_cluster" {
  cluster_identifier      = "${var.project_prefix}-${var.environment}-cluter"
  engine                  = "aurora-postgresql"
  engine_mode             = "provisioned"
  engine_version          = var.aurora_rds_cluster.engine_version
  db_subnet_group_name    = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  availability_zones      = [
    "${var.aws_region}a",
    "${var.aws_region}b",
    "${var.aws_region}c"
  ]
  final_snapshot_identifier = "${var.project_prefix}-${var.environment}-rds-cluter-final-snapshot"

  database_name           = var.project_prefix
  master_username         = "postgres"
  master_password         = random_password.rds_user_password.result
  backup_retention_period = var.aurora_rds_cluster.backup_retention_period
  deletion_protection     = var.aurora_rds_cluster.deletion_protection
}

resource "aws_security_group" "rds_sg" {
  name        = "${var.project_prefix}-${var.environment}-rds-cluster-sg"
  description = "Allow traffic to rds cluster"
  vpc_id      = module.cluster_vpc.vpc_id

  tags = {
    Name = "${var.project_prefix}-${var.environment}-rds-cluster-sg"
    Environment = var.environment
  }

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = local.eks_in_allowed_subnets_cidrs
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
	}
}

resource "aws_ssm_parameter" "ssm_rds_cluster_host" {
  name  = "/${var.project_prefix}/${var.environment}/postgres/host"
  value = aws_rds_cluster.rds_cluster.endpoint
  type  = "String"

  tags = {
    environment = var.environment
  }
}
