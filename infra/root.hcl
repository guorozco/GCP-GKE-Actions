# Root Terragrunt Configuration
# This file contains common configuration for all environments

# Configure Terragrunt to automatically store tfstate files in GCS
remote_state {
  backend = "gcs"
  config = {
    bucket  = "${get_env("TF_VAR_project_id", "")}-tfstate-${basename(dirname(get_terragrunt_dir()))}"
    prefix  = "${path_relative_to_include()}/terraform.tfstate"
    project = get_env("TF_VAR_project_id", "")
    location = "US"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# Generate an additional Terraform file with the provider configuration
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}
EOF
}

# Common inputs for all modules
inputs = {
  project_id = get_env("TF_VAR_project_id", "")
}

