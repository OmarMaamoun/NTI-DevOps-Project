provider "aws" {
    region= var.region
}

module "my_vpc"{
    source="./modules/vpc"
    environment= var.environment
    vpc_cider=var.vpc_cider
    az1=var.az1
    az2=var.az2
    private_subnet=var.private_subnet
    public_subnet=var.public_subnet
    private_az2_subnet=var.private_az2_subnet
    public_az2_subnet=var.public_az2_subnet
    cidr_blocks=var.cidr_blocks
    cluster_name = var.cluster_name 


}


module "jenkins_ec2"{
    source="./modules/ec2"
    instance_type=var.instance_type
    key_name= var.key_name
    subnet_id= module.my_vpc.public_subnet_id
    security_group_id= module.my_vpc.security_group_id
    environment= var.environment
}

module "rds_instance"{
    source="./modules/rds"
    environment= var.environment
    rds_instance_type= var.rds_instance_type
    db_name= var.db_name
    db_username= var.db_username
    db_password= var.db_password
    db_sg_id= module.my_vpc.db_sg_id
    db_subnet_group= module.my_vpc.db_subnet_group_name
    engine=var.engine

}

module "s3_logs"{
    source ="./modules/s3"
    bucket_name= var.bucket_name
    environment=var.environment
    account_id = "117676877497"

}


module "ec2-backup"{
    source="./modules/backup"
    vault_name= var.vault_name
    schedule =var.schedule
    backup_name= var.backup_name
    resource_arn= module.jenkins_ec2.ec2_arn
    environment=var.environment
}

module "ecr_registery"{
    source="./modules/ecr"
    environment=var.environment
    image_tag_mutable=var.image_tag_mutable
}

module "eks_cluster" {
  source              = "./modules/eks"
  cluster_name        = var.cluster_name
  vpc_id              = module.my_vpc.vpc_id
  eks_public_subnets   = module.my_vpc.eks_public_subnets
  eks_private_subnets   = module.my_vpc.eks_private_subnets
  environment         = var.environment
  ec2_security_group_id = module.my_vpc.security_group_id
  instance_type       = var.instance_type
  bucket_name         = var.bucket_name
}