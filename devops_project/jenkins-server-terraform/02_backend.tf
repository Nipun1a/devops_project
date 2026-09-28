# Specify the backend configuration for storing Terraform state files in S3.
terraform {
  backend "s3" {
    # The S3 bucket where the Terraform state file will be stored.
    bucket = "nipun1abucket"

    # The S3 bucket is located in eu-north-1. This is independent of the
    # ap-south-1 region used by the AWS provider for project resources.
    region = "eu-north-1"

    # The key (path) within the S3 bucket for storing the state file.
    key = "three-tier-devdecops-project/jenkins-server-terraform/terraform.tfstate"

    # Use native S3 state locking instead of the deprecated DynamoDB locking parameter.
    use_lockfile = true

    # Ensures the state file is encrypted at rest in the S3 bucket.
    encrypt = true
  }

  # Specifies the minimum Terraform version required for this configuration.
  required_version = ">=1.10.0"

  # Specifies the required provider configurations for this Terraform project.
  required_providers {
    aws = {
      # The minimum version of the AWS provider required for this configuration.
      version = ">= 2.7.0"

      # The source of the AWS provider, using the HashiCorp registry.
      source = "hashicorp/aws"
    }
  }
}
