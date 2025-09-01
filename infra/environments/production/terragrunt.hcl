# Production Environment Configuration
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
  environment    = "production"
  cluster_name   = "gke-production"
  region         = "us-east1"       # Different region for production
  node_type      = "e2-standard-4"  # Larger nodes for production
  node_count     = 3                # More nodes for high availability
  min_node_count = 2                # Higher minimum for production
  max_node_count = 15               # Higher maximum for scaling
  
  # Network configuration
  subnet_cidr   = "10.20.0.0/16"
  pods_cidr     = "10.21.0.0/16"
  services_cidr = "10.22.0.0/16"
  master_cidr   = "172.18.0.0/28"
}

