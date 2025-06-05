provider "aws" {
  region  = var.region
  profile = var.aws_sso_profile

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project
      Owner       = var.owner
    }
  }
}