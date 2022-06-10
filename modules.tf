module "aurora" {
  source  = "app.terraform.io/eLuma/aurora/aws"
  version = "0.0.10"

  name           = "eluma-feature-rds-aurora-cluster"
  engine         = "aurora-mysql"
  engine_version = "8.0.mysql_aurora.3.02.0"
  instance_class = "db.t3.medium"
  instances = {
    one   = {}
    two   = {}
  }

  vpc_id  = aws_vpc.vpc.id
  create_db_subnet_group = true
  db_subnet_group_name = "eluma-feature-rds-subnetgrpd"
  kms_key_id = aws_kms_key.db.arn
  subnets = aws_subnet.private.*.id
  master_username = var.master_username
  master_password = var.master_password
  allowed_security_groups = [aws_security_group.ecs-task.id]
  database_name = "tms"
  port = "3306"
  storage_encrypted   = true
  apply_immediately   = false

  #db_parameter_group_name         = "default"
  #db_cluster_parameter_group_name = "default"


  tags = {
    Environment = "feature"
    Terraform   = "true"
  }
}