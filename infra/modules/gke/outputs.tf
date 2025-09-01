output "cluster_name" {
  description = "Name of the GKE cluster"
  value       = var.enable_autopilot ? google_container_cluster.gke_autopilot_cluster[0].name : google_container_cluster.gke_standard_cluster[0].name
}

output "cluster_endpoint" {
  description = "Endpoint of the GKE cluster"
  value       = var.enable_autopilot ? google_container_cluster.gke_autopilot_cluster[0].endpoint : google_container_cluster.gke_standard_cluster[0].endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "CA certificate of the GKE cluster"
  value       = var.enable_autopilot ? google_container_cluster.gke_autopilot_cluster[0].master_auth.0.cluster_ca_certificate : google_container_cluster.gke_standard_cluster[0].master_auth.0.cluster_ca_certificate
  sensitive   = true
}

output "cluster_location" {
  description = "Location of the GKE cluster"
  value       = var.enable_autopilot ? google_container_cluster.gke_autopilot_cluster[0].location : google_container_cluster.gke_standard_cluster[0].location
}

output "network_name" {
  description = "Name of the VPC network"
  value       = var.enable_autopilot ? "default" : google_compute_network.gke_network[0].name
}

output "subnet_name" {
  description = "Name of the subnet"
  value       = var.enable_autopilot ? "default" : google_compute_subnetwork.gke_subnet[0].name
}

output "service_account_email" {
  description = "Email of the GKE service account"
  value       = google_service_account.gke_service_account.email
}

output "node_pool_name" {
  description = "Name of the node pool"
  value       = var.enable_autopilot ? "autopilot-managed" : google_container_node_pool.gke_node_pool[0].name
}

output "cluster_mode" {
  description = "GKE cluster mode (autopilot or standard)"
  value       = var.enable_autopilot ? "autopilot" : "standard"
}

