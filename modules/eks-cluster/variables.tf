variable "existing_cluster_role_name" {
  description = "Name of existing IAM role for EKS cluster"
  type        = string
  default     = "AmazonEKSAutoClusterRole"
}

variable "existing_node_role_name" {
  description = "Name of existing IAM role for EKS nodes"
  type        = string
  default     = "AmazonEKSAutoNodeRole"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where EKS will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for EKS"
  type        = list(string)
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 3
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 5
}

variable "node_instance_types" {
  description = "List of instance types for nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}