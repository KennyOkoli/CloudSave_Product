variable "account"{
    type = string
    default = "871145212791"
}

variable "aws_region"{
    type = string
    default = "af-south-1"
}

variable "public_ip"{
    type = string
    default = "0.0.0.0/0"
}

variable "CS_cidr_block"{
    type = string
    default = "172.0.0.0/16"
}

variable "nat_tags" {
    default = ["nat-af-1a", "nat-af-1b"]
}

variable "private_subnets_tags"{
    default = ["prv-af-1a", "prv-af-1b"]
}

variable "public_subnet_tags"{
    default = ["pub-af-1a", "pub-af-1b"]
}

variable "key_name" {
    default = "cs_key_pair"
}
