# Production Artifact Registry Configuration
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
  environment       = "production"
  region           = "us-east1"           # Same region as GKE production
  repository_name  = "production-docker" # Environment-specific name
  description      = "Docker images for production environment"
  
  # Free tier optimization settings
  cleanup_policy_dry_run = false
  
  # More conservative cleanup policies for production
  cleanup_policies = [
    {
      id     = "delete-very-old-images"
      action = "DELETE"
      condition = {
        older_than = "7776000s"  # 90 days
        tag_state  = "UNTAGGED"
      }
    },
    {
      id     = "keep-tagged-images"
      action = "KEEP"
      condition = {
        tag_state  = "TAGGED"
        newer_than = "604800s"   # Keep tagged images for 7 days minimum
      }
    }
  ]
  
  # Security and access settings
  create_service_account       = true
  enable_vulnerability_scanning = true
  immutable_tags              = true   # Prevent overwriting in production
  
  # Allow GKE production cluster to pull images
  allowed_readers = []  # Will use default GKE service account
  allowed_writers = []  # Can be configured later for CI/CD
}
