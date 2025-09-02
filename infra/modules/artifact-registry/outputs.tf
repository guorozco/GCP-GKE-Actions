output "repository_name" {
  description = "Name of the Artifact Registry repository"
  value       = google_artifact_registry_repository.main.name
}

output "repository_url" {
  description = "URL of the Artifact Registry repository"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${var.repository_name}"
}

output "registry_url" {
  description = "Base URL of the Artifact Registry"
  value       = "${var.region}-docker.pkg.dev"
}

output "location" {
  description = "Location of the Artifact Registry repository"
  value       = google_artifact_registry_repository.main.location
}

output "repository_id" {
  description = "ID of the Artifact Registry repository"
  value       = google_artifact_registry_repository.main.repository_id
}

output "service_account_email" {
  description = "Email of the Artifact Registry service account"
  value       = var.create_service_account ? google_service_account.artifact_registry_sa[0].email : null
}

output "service_account_name" {
  description = "Name of the Artifact Registry service account"
  value       = var.create_service_account ? google_service_account.artifact_registry_sa[0].name : null
}

output "secret_config_id" {
  description = "ID of the Secret Manager secret containing registry configuration"
  value       = google_secret_manager_secret.artifact_registry_config.secret_id
}

output "docker_push_command" {
  description = "Example command to push Docker images to this registry"
  value       = "docker push ${var.region}-docker.pkg.dev/${var.project_id}/${var.repository_name}/IMAGE_NAME:TAG"
}

output "docker_pull_command" {
  description = "Example command to pull Docker images from this registry"
  value       = "docker pull ${var.region}-docker.pkg.dev/${var.project_id}/${var.repository_name}/IMAGE_NAME:TAG"
}

output "gcloud_configure_command" {
  description = "Command to configure Docker with gcloud for this registry"
  value       = "gcloud auth configure-docker ${var.region}-docker.pkg.dev"
}
