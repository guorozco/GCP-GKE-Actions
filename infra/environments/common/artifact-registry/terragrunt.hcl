# Common Artifact Registry Configuration
# This can be used for shared registries across environments

# Include the root terragrunt configuration
include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Terraform module source
terraform {
  source = "../../../modules/artifact-registry"
}

# Shared configuration for common images
inputs = {
  environment       = "shared"
  region           = "us-central1"        # Central location for shared registry
  repository_name  = "shared-docker"     # Shared across environments
  description      = "Shared Docker images for all environments"
  
  # Moderate cleanup policies for shared registry
  cleanup_policy_dry_run = false
  
  cleanup_policies = [
    {
      id     = "delete-old-untagged"
      action = "DELETE"
      condition = {
        older_than = "1209600s"  # 14 days for shared images
        tag_state  = "UNTAGGED"
      }
    },
    {
      id     = "keep-stable-tags"
      action = "KEEP"
      condition = {
        tag_prefixes = ["stable", "release", "v"]
        tag_state   = "TAGGED"
      }
    }
  ]
  
  # Security settings for shared registry
  create_service_account       = true
  enable_vulnerability_scanning = true
  immutable_tags              = true   # Protect shared images
  
  # Allow both staging and production to read
  allowed_readers = [
    "serviceAccount:${get_env("TF_VAR_project_id", "")}-compute@developer.gserviceaccount.com"
  ]
  
  # Restrict writers to CI/CD systems
  allowed_writers = []  # Configure with CI/CD service accounts
}
