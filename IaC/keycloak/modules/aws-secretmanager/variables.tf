variable "secret_value" {
  description = "value to be stored in the secret"
  type = string
  sensitive = true
  ephemeral = true
}

variable "secret_name" {
  type = string
}

variable "secret_version" {
  type = number
}