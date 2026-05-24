provider "aws" {
  region = local.config.env.region # Change to your preferred region

  default_tags {
    tags = local.config.common_tags
  }
}