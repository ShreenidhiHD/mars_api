variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS profile from ~/.aws/credentials"
  type        = string
  default     = "default"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "gemini_api_key" {
  description = "Gemini API key"
  type        = string
  sensitive   = true
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "hdshreenidhi.in" 
}

variable "billing_threshold" {
  description = "Billing threshold in USD to trigger alerts"
  type        = number
  default     = 1
}

variable "alert_email" {
  description = "Email address for billing alerts"
  type        = string
}
