# Secret Manager setup for storing sensitive GKE configuration
resource "google_secret_manager_secret" "gke_service_account_key" {
  secret_id = "${var.cluster_name}-gke-sa-key"
  
  labels = {
    environment = var.environment
    managed-by  = "terraform"
    cluster     = var.cluster_name
  }

  replication {
    auto {}
  }
}

# IAM binding for Secret Manager access
resource "google_secret_manager_secret_iam_member" "gke_service_account_access" {
  secret_id = google_secret_manager_secret.gke_service_account_key.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.gke_service_account.email}"
}

# Optional: Create secret for kubeconfig (for CI/CD access)
resource "google_secret_manager_secret" "kubeconfig" {
  secret_id = "${var.cluster_name}-kubeconfig"
  
  labels = {
    environment = var.environment
    managed-by  = "terraform"
    cluster     = var.cluster_name
  }

  replication {
    auto {}
  }
}

