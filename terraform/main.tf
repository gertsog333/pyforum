data "http" "my_ip" {
  url = "https://checkip.amazonaws.com/"
}

locals {
  my_ip = "${chomp(data.http.my_ip.response_body)}/32"
}

module "vpc" {
  source       = "./modules/vpc"
  project_name = var.project_name
  aws_region   = var.aws_region
  my_ip        = local.my_ip
}

module "iam" {
  source         = "./modules/iam"
  project_name   = var.project_name
  aws_account_id = var.aws_account_id
  aws_region     = var.aws_region
  ecr_repo_arn   = module.ecr.repository_arn
  s3_bucket_name = module.s3.bucket_name
}

module "ecr" {
  source       = "./modules/ecr"
  project_name = var.project_name
}

module "s3" {
  source         = "./modules/s3"
  project_name   = var.project_name
  aws_account_id = var.aws_account_id
}

module "secrets" {
  source       = "./modules/secrets"
  project_name = var.project_name
}

module "rds" {
  source             = "./modules/rds"
  project_name       = var.project_name
  private_subnet_ids = module.vpc.private_subnet_ids
  sg_rds_id          = module.vpc.sg_rds_id
  db_name            = module.secrets.db_name
  db_username        = module.secrets.db_username
  db_password        = module.secrets.db_password
}

module "ec2" {
  source                        = "./modules/ec2"
  project_name                  = var.project_name
  aws_region                    = var.aws_region
  aws_account_id                = var.aws_account_id
  public_subnet_id              = module.vpc.public_subnet_ids[0]
  sg_app_id                     = module.vpc.sg_app_id
  sg_jenkins_id                 = module.vpc.sg_jenkins_id
  my_ip                         = local.my_ip
  app_instance_profile_name     = module.iam.app_instance_profile_name
  jenkins_instance_profile_name = module.iam.jenkins_instance_profile_name
  rds_endpoint                  = module.rds.rds_endpoint
}
