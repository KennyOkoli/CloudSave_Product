module "vpc" {
    source = "../../modules/vpc"
}

module "rds" {
    source = "../../modules/rds"   
    secret-manager-id = module.secrets.secret-id
    private_subnets = module.vpc.private-subnets
    az = module.vpc.azones
    vpc-id = module.vpc.vpc-id
}

module "secrets" {
    source = "../../modules/secrets"
}

module "s3" {
    source = "../../modules/s3"
}

module "IdentityCenter" {
    source = "../../modules/IdentityCenter"
    providers = {
        aws = aws.identity_center
    }
    s3-arn = module.s3.s3-arn
    secret-arn = module.secrets.secret-manager-arn
}

module "github" {
    source = "../../modules/github"
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
}

module "ec2" {
    source = "../../modules/ec2"
    vpc_id = module.vpc.vpc-id
    public-cidr = module.vpc.public-cidr
    vpc-prv-subnets = module.vpc.private-subnets
    nacl = module.vpc.vpc-nacls
    public-subnet = module.vpc.vpc-public-subnet
    ecs-sg-var = module.ecs.ecs-sg
}