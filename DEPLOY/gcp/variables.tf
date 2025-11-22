variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  default     = "us-central1"
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

variable "image_uri" {
  description = "Container Image URI (gcr.io/...)"
  type        = string
}
