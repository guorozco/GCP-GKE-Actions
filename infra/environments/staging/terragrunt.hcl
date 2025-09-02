# Staging Environment Configuration
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
  environment       = "staging"
  cluster_name      = "gke-staging"
  region            = "us-central1"         # Free tier eligible region (Autopilot requires regional)
  
  # FREE TIER SETTINGS
  enable_autopilot   = true               # Autopilot is more cost-effective
  enable_preemptible = true               # Use preemptible nodes for cost savings
  node_type          = "e2-micro"         # Free tier eligible machine type
  node_count         = 1                  # Minimal nodes
  min_node_count     = 1                  # Minimum for cost
  max_node_count     = 3                  # Limited scaling for free tier
  disk_size_gb       = 32                 # Reduced disk size
  
  # Network configuration (only used if autopilot is disabled)
  subnet_cidr   = "10.10.0.0/16"
  pods_cidr     = "10.11.0.0/16"
  services_cidr = "10.12.0.0/16"
  master_cidr   = "172.17.0.0/28"
}

