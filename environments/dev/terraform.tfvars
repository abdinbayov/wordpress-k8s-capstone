# Project Configuration
project_name = "wordpress-capstone"
environment  = "dev"
owner        = "devops-team"
aws_region   = "eu-north-1"

# Networking
vpc_cidr             = "10.0.0.0/16"
availability_zones   = ["eu-north-1a", "eu-north-1b", "eu-north-1c"]
private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

# EKS
kubernetes_version  = "1.28"
node_desired_size   = 3
node_min_size       = 2
node_max_size       = 5
node_instance_types = ["t3.medium"]