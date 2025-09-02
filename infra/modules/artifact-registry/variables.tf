variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The region for the Artifact Registry"
  type        = string
}

variable "environment" {
  description = "Environment name (staging, production, etc.)"
  type        = string
}

variable "repository_name" {
  description = "Name of the Artifact Registry repository"
  type        = string
  default     = "docker-images"
}

variable "description" {
  description = "Description of the Artifact Registry repository"
  type        = string
  default     = "Docker images repository"
}

variable "format" {
  description = "Repository format (DOCKER, MAVEN, NPM, etc.)"
  type        = string
  default     = "DOCKER"
  
  validation {
    condition = contains([
      "DOCKER", "MAVEN", "NPM", "APT", "YUM", "PYTHON", "KUBEFLOW", "GO"
    ], var.format)
    error_message = "Format must be one of: DOCKER, MAVEN, NPM, APT, YUM, PYTHON, KUBEFLOW, GO."
  }
}

variable "cleanup_policy_dry_run" {
  description = "If true, the cleanup policy is in dry run mode"
  type        = bool
  default     = false
}

variable "cleanup_policies" {
  description = "List of cleanup policies for the repository"
  type = list(object({
    id     = string
    action = string
    condition = object({
      tag_state             = optional(string)
      tag_prefixes          = optional(list(string))
      version_name_prefixes = optional(list(string))
      package_name_prefixes = optional(list(string))
      older_than           = optional(string)
      newer_than           = optional(string)
    })
  }))
  default = []
}

variable "enable_vulnerability_scanning" {
  description = "Enable vulnerability scanning for images"
  type        = bool
  default     = true
}

variable "immutable_tags" {
  description = "Enable immutable tags"
  type        = bool
  default     = false
}

variable "create_service_account" {
  description = "Create a service account for Artifact Registry access"
  type        = bool
  default     = true
}

variable "allowed_readers" {
  description = "List of members that can read from the repository"
  type        = list(string)
  default     = []
}

variable "allowed_writers" {
  description = "List of members that can write to the repository"
  type        = list(string)
  default     = []
}
