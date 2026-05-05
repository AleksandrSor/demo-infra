variable "project_region" {
  type = string
  default = "us-east-1"
}

variable "project_name" {
  type = string
  default = "sa-demo"
}

variable "tf_user_name" {
  type = string
  default = "sa-demo-tf-user"
}

variable "tf_user_path" {
  type = string
  default = "/automation/iac/"
}

variable "tf_role_name" {
  type = string
  default = "TFExecutionRole"
}

variable "tf_extra_admin_user" {
  type = string
  description = "Extra user to put into some policies"
  default = "terraf1admin"
}

variable "common_tags" {
  type        = map(string)
  description = "A map of tags to apply to all resources"
  default = {
    Project     = "sa-demo"
    Environment = "Development"
    ManagedBy   = "Tofu"
  }
}