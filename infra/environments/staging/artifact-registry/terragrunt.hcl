# Staging Artifact Registry Configuration
# Include the root terragrunt configuration
include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Terraform module source
terraform {
  source = "../../../modules/artifact-registry"
}

# Dependencies - make sure this runs after GKE if both are being deployed
dependencies {
  paths = ["../"]  # Reference to the GKE configuration
}

# Environment-specific inputs - FREE TIER OPTIMIZED
inputs = {
  environment       = "staging"
  region           = "us-central1"        # Same region as GKE staging
  repository_name  = "staging-docker"    # Environment-specific name
  description      = "Docker images for staging environment"
  
  # Free tier optimization settings
  cleanup_policy_dry_run = false
  
  # Cleanup policies to save storage costs
  cleanup_policies = [
    {
      id     = "delete-old-images"
      action = "DELETE"
      condition = {
        older_than = "2592000s"  # 30 days
        tag_state  = "UNTAGGED"
      }
    },
    {
      id     = "keep-recent-tagged"
      action = "KEEP"
      condition = {
        tag_state  = "TAGGED"
        newer_than = "86400s"    # Keep tagged images for 1 day minimum
      }
    }
  ]
  
  # Security and access settings
  create_service_account       = true
  enable_vulnerability_scanning = true
  immutable_tags              = false  # Allow overwriting for staging
  
  # Allow GKE staging cluster to pull images
  allowed_readers = []  # Will use default GKE service account
  allowed_writers = []  # Can be configured later for CI/CD
}
