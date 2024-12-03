resource "random_password" "redis_password" {
  count   = var.redis.auth_token_enabled ? 1 : 0
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "redis_password_secret" {
  count   = var.redis.auth_token_enabled ? 1 : 0
  name = "/${var.project_prefix}/${var.environment}/redis-password"
}
resource "aws_secretsmanager_secret_version" "redis_password_secret" {
  count   = var.redis.auth_token_enabled ? 1 : 0
  secret_id     = aws_secretsmanager_secret.redis_password_secret[0].id
  secret_string = random_password.redis_password[0].result
}


resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name       = "${var.project_prefix}-${var.environment}-redis-subg"
subnet_ids          = module.cluster_vpc.private_subnets
}

resource "aws_elasticache_parameter_group" "redis_parameter_group" {
  name   = "${var.project_prefix}-${var.environment}-redis-pg"
  family = "redis${var.redis.redis_engine_version}"

  parameter {
    name  = "maxmemory-policy"
    value = "noeviction"
  }
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = "${var.project_prefix}-${var.environment}-redis-cluster"
  description                = "${var.project_name} ${var.environment} redis cluster"
  engine_version             = var.redis.redis_engine_version
  node_type                  = var.redis.redis_node_type
  num_cache_clusters         = var.redis.cluster_size
  parameter_group_name       = aws_elasticache_parameter_group.redis_parameter_group.id
  multi_az_enabled           = var.redis.multi_az_enabled
  automatic_failover_enabled = var.redis.automatic_failover_enabled
  apply_immediately          = var.redis.apply_immediately
  transit_encryption_enabled = var.redis.transit_encryption_enabled
  auth_token                 = var.redis.auth_token_enabled ? random_password.redis_password[0].result : null
  port                       = 6379
  subnet_group_name          = aws_elasticache_subnet_group.redis_subnet_group.name
  security_group_ids         = [aws_security_group.redis_sg.id]

  snapshot_retention_limit   = var.redis.snapshot_retention_limit
  final_snapshot_identifier  = "${var.project_prefix}-${var.environment}-redis-final-snapshot"
}

resource "aws_security_group" "redis_sg" {
  name        = "${var.project_prefix}-${var.environment}-redis-sg"
  description = "Allow traffic to ${var.environment} redis cluster"
  vpc_id      = module.cluster_vpc.vpc_id

  tags = {
      Name = "${var.project_prefix}-${var.environment}-redis-sg"
      Environment = var.environment
  }
  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    cidr_blocks     = local.eks_in_allowed_subnets_cidrs
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
	}
}
