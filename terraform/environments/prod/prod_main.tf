module "vpc" {
    source = "../../modules/vpc"
    environment = var.env
}

module "rds" {
    source = "../../modules/rds"   
    secret-manager-id = module.secrets.secret-id
    private_subnets = module.vpc.private-subnets
    az = module.vpc.azones
    vpc-id = module.vpc.vpc-id
    environment = var.env
}

module "secrets" {
    source = "../../modules/secrets"
    environment = var.env
}

module "s3" {
    source = "../../modules/s3"
    bucket_name = var.bucket
    environment = var.env
}
/*
module "IdentityCenter" {
    source = "../../modules/IdentityCenter"
    providers = {
        aws = aws.identity_center
    }
    s3-arn = module.s3.s3-arn
    secret-arn = module.secrets.secret-manager-arn
    ec2-arn = module.rds.ec2_arn
}
*/
module "github" {
    source = "../../modules/github"
    ecr_arn = module.ecs.ecr-arn
    environment = var.env
}

module "ecs" {
    source = "../../modules/ecs"
    s3 = module.s3.s3-arn
    secrets = module.secrets.secret-manager-arn
    vpc = module.vpc.vpc-id
    db-sg = module.rds.db_sg
    private-subnets = module.vpc.private-subnets
    nacl = module.vpc.vpc-nacls
    public = module.vpc.public-cidr
    target-arn = module.ec2.target
    alb_sg = module.ec2.alb-sg
    db_name = module.rds.db_name
    db_username = module.rds.db_username
    db_password = module.rds.db_password
    s3_bucket = module.s3.bucket-name
    region = var.aws_region
    environment = var.env
}

module "ec2" {
    source = "../../modules/ec2"
    vpc_id = module.vpc.vpc-id
    public-cidr = module.vpc.public-cidr
    vpc-prv-subnets = module.vpc.private-subnets
    nacl = module.vpc.vpc-nacls
    public-subnet = module.vpc.vpc-public-subnet
    ecs-sg-var = module.ecs.ecs-sg
    environment = var.env
}