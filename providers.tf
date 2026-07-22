# Provider version + region config (region wired through variables.tf).
provider "aws" {
  region = var.aws_region
}
