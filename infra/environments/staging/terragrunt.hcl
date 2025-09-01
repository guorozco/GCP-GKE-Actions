# Staging Environment Configuration
# Include the root terragrunt configuration
include "root" {
  path = find_in_parent_folders()
}

# Terraform module source
terraform {
  source = "../../modules/gke"
}

# Environment-specific inputs
inputs = {
  environment    = "staging"
  cluster_name   = "gke-staging"
  region         = "us-central1"
  node_type      = "e2-standard-2"  # Smaller nodes for staging
  node_count     = 2                # Fewer nodes for cost optimization
  min_node_count = 1
  max_node_count = 5
  
  # Network configuration
  subnet_cidr   = "10.10.0.0/16"
  pods_cidr     = "10.11.0.0/16"
  services_cidr = "10.12.0.0/16"
  master_cidr   = "172.17.0.0/28"
}

