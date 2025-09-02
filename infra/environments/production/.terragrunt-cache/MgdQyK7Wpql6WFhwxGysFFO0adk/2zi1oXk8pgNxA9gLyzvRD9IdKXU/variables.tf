variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
}

variable "region" {
  description = "The region for the GKE cluster"
  type        = string
}

variable "environment" {
  description = "Environment name (staging, production, etc.)"
  type        = string
}

variable "node_type" {
  description = "The machine type for the GKE nodes"
  type        = string
  default     = "e2-micro"  # Free tier eligible
}

variable "node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
  default     = 1  # Minimal for cost optimization
}

variable "min_node_count" {
  description = "Minimum number of nodes in the node pool"
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum number of nodes in the node pool"
  type        = number
  default     = 3  # Reduced for free tier
}

variable "network_name" {
  description = "Name of the VPC network"
  type        = string
  default     = "gke-network"
}

variable "subnet_name" {
  description = "Name of the subnet"
  type        = string
  default     = "gke-subnet"
}

variable "subnet_cidr" {
  description = "CIDR range for the subnet"
  type        = string
  default     = "10.0.0.0/16"
}

variable "pods_cidr" {
  description = "CIDR range for pods"
  type        = string
  default     = "10.1.0.0/16"
}

variable "services_cidr" {
  description = "CIDR range for services"
  type        = string
  default     = "10.2.0.0/16"
}

variable "master_cidr" {
  description = "CIDR range for the master nodes"
  type        = string
  default     = "172.16.0.0/28"
}

variable "enable_autopilot" {
  description = "Enable GKE Autopilot mode for cost optimization"
  type        = bool
  default     = true
}

variable "disk_size_gb" {
  description = "Boot disk size for nodes"
  type        = number
  default     = 32  # Reduced from 100GB for cost savings
}

variable "enable_preemptible" {
  description = "Use spot nodes for cost savings (spot instances are newer than preemptible)"
  type        = bool
  default     = true
}

