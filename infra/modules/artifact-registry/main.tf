# Artifact Registry Repository
resource "google_artifact_registry_repository" "main" {
  location      = var.region
  repository_id = var.repository_name
  description   = "${var.description} for ${var.environment} environment"
  format        = var.format

  # Free tier optimization - use standard mode
  mode = "STANDARD_REPOSITORY"

  # Cleanup policies for cost optimization
  dynamic "cleanup_policies" {
    for_each = var.cleanup_policies
    content {
      id     = cleanup_policies.value.id
      action = cleanup_policies.value.action

      condition {
        tag_state             = lookup(cleanup_policies.value.condition, "tag_state", null)
        tag_prefixes          = lookup(cleanup_policies.value.condition, "tag_prefixes", null)
        version_name_prefixes = lookup(cleanup_policies.value.condition, "version_name_prefixes", null)
        package_name_prefixes = lookup(cleanup_policies.value.condition, "package_name_prefixes", null)
        older_than           = lookup(cleanup_policies.value.condition, "older_than", null)
        newer_than           = lookup(cleanup_policies.value.condition, "newer_than", null)
      }
    }
  }

  cleanup_policy_dry_run = var.cleanup_policy_dry_run

  labels = {
    environment = var.environment
    managed-by  = "terraform"
    purpose     = "container-images"
  }
}

# Service Account for Artifact Registry access (optional)
resource "google_service_account" "artifact_registry_sa" {
  count        = var.create_service_account ? 1 : 0
  account_id   = "${var.repository_name}-ar-sa"
  display_name = "Artifact Registry Service Account for ${var.repository_name}"
  description  = "Service account for Artifact Registry operations in ${var.environment}"
}

# IAM binding for the service account to access Artifact Registry
resource "google_artifact_registry_repository_iam_member" "artifact_registry_reader" {
  count      = var.create_service_account ? 1 : 0
  location   = google_artifact_registry_repository.main.location
  repository = google_artifact_registry_repository.main.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.artifact_registry_sa[0].email}"
}

resource "google_artifact_registry_repository_iam_member" "artifact_registry_writer" {
  count      = var.create_service_account ? 1 : 0
  location   = google_artifact_registry_repository.main.location
  repository = google_artifact_registry_repository.main.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.artifact_registry_sa[0].email}"
}

# IAM bindings for additional readers
resource "google_artifact_registry_repository_iam_member" "readers" {
  for_each   = toset(var.allowed_readers)
  location   = google_artifact_registry_repository.main.location
  repository = google_artifact_registry_repository.main.name
  role       = "roles/artifactregistry.reader"
  member     = each.value
}

# IAM bindings for additional writers
resource "google_artifact_registry_repository_iam_member" "writers" {
  for_each   = toset(var.allowed_writers)
  location   = google_artifact_registry_repository.main.location
  repository = google_artifact_registry_repository.main.name
  role       = "roles/artifactregistry.writer"
  member     = each.value
}

# GKE Integration: Grant GKE service account access to pull images
data "google_client_config" "default" {}

# This data source will be used to get the GKE service account
# We'll create this as a conditional resource that can be used if GKE integration is needed
resource "google_artifact_registry_repository_iam_member" "gke_reader" {
  count      = length(var.allowed_readers) > 0 ? 0 : 1  # Only if no custom readers specified
  location   = google_artifact_registry_repository.main.location
  repository = google_artifact_registry_repository.main.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${data.google_client_config.default.project}-compute@developer.gserviceaccount.com"
}

# Store Artifact Registry credentials in Secret Manager
resource "google_secret_manager_secret" "artifact_registry_config" {
  secret_id = "${var.repository_name}-config"
  
  labels = {
    environment = var.environment
    managed-by  = "terraform"
    purpose     = "artifact-registry"
  }

  replication {
    auto {}
  }
}

# Store the registry URL and configuration
resource "google_secret_manager_secret_version" "artifact_registry_config" {
  secret      = google_secret_manager_secret.artifact_registry_config.id
  secret_data = jsonencode({
    registry_url    = "${var.region}-docker.pkg.dev"
    repository_url  = "${var.region}-docker.pkg.dev/${var.project_id}/${var.repository_name}"
    location        = var.region
    project_id      = var.project_id
    repository_name = var.repository_name
    format          = var.format
    environment     = var.environment
  })
}
