provider "aws" {
  region = var.project_region # Change to your preferred region

  default_tags {
    tags = var.common_tags
  }
}