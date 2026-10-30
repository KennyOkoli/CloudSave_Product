terraform{
    backend "s3" {
        bucket = "cloudsave-prod-tfstate"
        key = "prod/terraform.tfstate"
        region = "af-south-1"
    }
    
    required_providers{
        aws ={
            source = "hashicorp/aws"
            version = "~>6.0"
        }
    }
}

provider "aws"{
    region = var.aws_region
}

variable "aws_region"{
    type = string
    default = "af-south-1"
}

variable "bucket" {
    default = "cloudsave-bucket-prod"
}

variable "env" {
    default = "prod"
}