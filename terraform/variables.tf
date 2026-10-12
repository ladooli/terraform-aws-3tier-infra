variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}

variable "project_name" {
  description = "Project name - prefixed to every resource name"
  type        = string
  default     = "tf-3tier-oliver"
}

variable "vpc_cidr" {
  description = "IP range of the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones to create subnets in"
  type        = list(string)
  default     = ["eu-north-1a", "eu-north-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_server_cidrs" {
  description = "CIDR blocks for the private application subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "private_db_cidrs" {
  description = "CIDR blocks for the private database subnets"
  type        = list(string)
  default     = ["10.0.20.0/24", "10.0.21.0/24"]
}

variable "ec2_instance_type" {
  description = "Instance type for the application servers"
  type        = string
  default     = "t3.micro"
}

variable "bastion_instance_type" {
  description = "Instance type for the bastion host"
  type        = string
  default     = "t3.micro"
}

variable "key_pair_name" {
  description = "Name of an existing EC2 key pair used for SSH access"
  type        = string
  default     = "tf-3tier-key-oliver"
}

variable "ssh_allowed_cidr" {
  description = "CIDR block allowed to SSH into the bastion host"
  type        = string
  default     = "0.0.0.0/0"
}