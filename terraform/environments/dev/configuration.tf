terraform{
    backend "s3" {
        bucket = "cloudsave-terraform-state"
        key = "dev/terraform.tfstate"
        region = "af-south-1"
    }
    
    required_providers{
        aws ={
            source = "hashicorp/aws"
            version = "~>6.0"
        }
        local ={
            source = "hashicorp/local"
            version = "~>2.9"
        }
        tls = {
            source = "hashicorp/tls"
            version = "~>4.4"
        }
    }
}

provider "aws"{
    region = var.aws_region
}

provider "aws" {
    alias = "identity_center"
    region = var.identity_center_region 
}

variable "identity_center_region" {
    default = "us-east-1"
}

variable "aws_region"{
    type = string
    default = "af-south-1"
}

variable "bucket" {
    default = "cloudsave-bucket-871145212791"
}