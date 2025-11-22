variable "aws_region" {
  description = "AWS Region"
  default     = "us-east-1"
}

variable "app_name" {
  description = "Application Name"
  default     = "proxyer"
}

variable "db_password" {
  description = "Database Password"
  type        = string
  sensitive   = true
}

variable "db_username" {
  description = "Database Username"
  default     = "proxyuser"
}

variable "image_identifier" {
  description = "Docker Image Identifier (ECR URI or Public Image)"
  type        = string
}

variable "port" {
  description = "Port to expose"
  default     = "8080"
}
