provider "aws" {
  region = "ap-south-1"
}

module "vpc" {
  source               = "./modules/vpc"
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_count  = 2
  private_subnet_count = 2
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
  availability_zones   = ["ap-south-1a", "ap-south-1b"]
}


module "database" {
  source          = "./modules/database"
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
  public_subnets  = module.vpc.public_subnets

}

module "efs" {
  source = "./modules/efs"
  vpc_id = module.vpc.vpc_id
}

module "ecs" {
  source          = "./modules/ecs"
  file_system     = module.efs.id
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
  public_subnets  = module.vpc.public_subnets
  psql_host       = module.database.psql_host
  psql_password   = module.database.psql_password
  psql_user       = module.database.psql_user
  
}
