# Optimized GKE configuration for free tier GCP accounts
# This configuration supports both Autopilot and Standard modes

# Service Account for GKE nodes with minimal privileges
resource "google_service_account" "gke_service_account" {
  account_id   = "${var.cluster_name}-gke-sa"
  display_name = "GKE Service Account for ${var.cluster_name}"
  description  = "Service account for GKE nodes in ${var.environment} environment"
}

# Minimal IAM bindings for cost optimization
resource "google_project_iam_member" "gke_service_account_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/storage.objectViewer"
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_service_account.email}"
}

# Simplified VPC Network for cost optimization
resource "google_compute_network" "gke_network" {
  count                   = var.enable_autopilot ? 0 : 1
  name                    = "${var.cluster_name}-${var.network_name}"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

# Simplified Subnet
resource "google_compute_subnetwork" "gke_subnet" {
  count         = var.enable_autopilot ? 0 : 1
  name          = "${var.cluster_name}-${var.subnet_name}"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.gke_network[0].id

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = var.pods_cidr
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = var.services_cidr
  }

  private_ip_google_access = true
}

# Minimal Router for NAT (only for standard mode)
resource "google_compute_router" "gke_router" {
  count   = var.enable_autopilot ? 0 : 1
  name    = "${var.cluster_name}-router"
  region  = var.region
  network = google_compute_network.gke_network[0].id
}

# Minimal NAT Gateway (only for standard mode)
resource "google_compute_router_nat" "gke_nat" {
  count                              = var.enable_autopilot ? 0 : 1
  name                               = "${var.cluster_name}-nat"
  router                             = google_compute_router.gke_router[0].name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# GKE Autopilot Cluster (cost-optimized)
resource "google_container_cluster" "gke_autopilot_cluster" {
  count    = var.enable_autopilot ? 1 : 0
  name     = var.cluster_name
  location = var.region

  # Enable Autopilot
  enable_autopilot = true

  # Minimal configuration for Autopilot
  ip_allocation_policy {
    cluster_ipv4_cidr_block  = ""
    services_ipv4_cidr_block = ""
  }

  # Enable private nodes
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.master_cidr
  }

  # Minimal addons for cost optimization
  addons_config {
    horizontal_pod_autoscaling {
      disabled = false
    }
    http_load_balancing {
      disabled = false
    }
  }

  # Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Resource labels
  resource_labels = {
    environment = var.environment
    managed-by  = "terraform"
    mode        = "autopilot"
  }

  # Release channel for automatic updates
  release_channel {
    channel = "REGULAR"
  }
}

# GKE Standard Cluster (cost-optimized)
resource "google_container_cluster" "gke_standard_cluster" {
  count      = var.enable_autopilot ? 0 : 1
  name       = var.cluster_name
  location   = var.region
  network    = google_compute_network.gke_network[0].self_link
  subnetwork = google_compute_subnetwork.gke_subnet[0].self_link

  # Remove default node pool
  remove_default_node_pool = true
  initial_node_count       = 1

  # Enable private cluster
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.master_cidr
  }

  # IP allocation policy for secondary ranges
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  # Minimal addons configuration for cost optimization
  addons_config {
    horizontal_pod_autoscaling {
      disabled = false
    }
    network_policy_config {
      disabled = true  # Disabled to reduce costs
    }
  }

  # Master authentication
  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  # Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Minimal logging and monitoring for cost optimization
  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  # Resource labels
  resource_labels = {
    environment = var.environment
    managed-by  = "terraform"
    mode        = "standard"
  }

  depends_on = [
    google_project_iam_member.gke_service_account_roles,
  ]
}

# Cost-optimized Node Pool (only for standard mode)
resource "google_container_node_pool" "gke_node_pool" {
  count      = var.enable_autopilot ? 0 : 1
  name       = "${var.cluster_name}-node-pool"
  location   = var.region
  cluster    = google_container_cluster.gke_standard_cluster[0].name
  
  # Aggressive autoscaling for cost optimization
  autoscaling {
    min_node_count = var.min_node_count
    max_node_count = var.max_node_count
  }

  initial_node_count = var.node_count

  # Cost-optimized node configuration
  node_config {
    preemptible  = var.enable_preemptible
    spot         = var.enable_preemptible  # Use spot instances when available
    machine_type = var.node_type

    # Service account
    service_account = google_service_account.gke_service_account.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_only",
    ]

    # Minimal shielded VM features
    shielded_instance_config {
      enable_secure_boot          = false  # Disabled for cost optimization
      enable_integrity_monitoring = false  # Disabled for cost optimization
    }

    # Workload Identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Labels
    labels = {
      environment = var.environment
      managed-by  = "terraform"
      preemptible = var.enable_preemptible ? "true" : "false"
    }

    # Taints for preemptible nodes
    dynamic "taint" {
      for_each = var.enable_preemptible ? [1] : []
      content {
        key    = "preemptible"
        value  = "true"
        effect = "NO_SCHEDULE"
      }
    }

    # Minimal disk configuration
    disk_size_gb = var.disk_size_gb
    disk_type    = "pd-standard"  # Standard persistent disk for cost optimization
    image_type   = "COS_CONTAINERD"
  }

  # Aggressive upgrade settings for faster updates
  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }

  # Management settings
  management {
    auto_repair  = true
    auto_upgrade = true
  }

  depends_on = [
    google_container_cluster.gke_standard_cluster,
  ]
}
