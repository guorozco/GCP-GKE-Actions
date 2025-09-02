# Production Environment Configuration
# Include the root terragrunt configuration
include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Terraform module source
terraform {
  source = "../../modules/gke"
}

# Environment-specific inputs - FREE TIER OPTIMIZED
inputs = {
  environment       = "production"
  cluster_name      = "gke-production"
  region            = "us-east1"            # Free tier eligible region
  
  # FREE TIER SETTINGS (slightly higher than staging)
  enable_autopilot   = false               # Standard mode for more control
  enable_preemptible = true                # Use preemptible for cost savings
  node_type          = "e2-small"          # Slightly larger but still free tier
  node_count         = 1                   # Start minimal
  min_node_count     = 1                   # Minimum for cost
  max_node_count     = 3                   # Limited scaling for free tier
  disk_size_gb       = 32                  # Reduced disk size
  
  # Network configuration
  subnet_cidr   = "10.20.0.0/16"
  pods_cidr     = "10.21.0.0/16"
  services_cidr = "10.22.0.0/16"
  master_cidr   = "172.18.0.0/28"
}

