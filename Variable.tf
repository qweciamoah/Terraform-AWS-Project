variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "bastion_instance_type" {
  description = "Instance type for bastion host"
  type        = string
  default     = "t3.micro"
}

variable "web_instance_type" {
  description = "Instance type for web servers"
  type        = string
  default     = "t3.micro"
}

variable "db_instance_type" {
  description = "Instance type for database server"
  type        = string
  default     = "t3.small"
}

variable "key_name" {
  description = "Name of existing AWS key pair to allow SSH access (optional). Leave empty to use password auth from user-data"
  type        = string
  default     = ""
}

variable "my_ip" {
  description = "Your current IP address in CIDR format (e.g. 203.0.113.5/32) for bastion SSH access"
  type        = string
  default     = "0.0.0.0/0"
}
