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