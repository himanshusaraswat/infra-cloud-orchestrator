variable "project_id" {
  description = "Target Google Cloud Project ID"
  type        = string
}

variable "project_number" {
  description = "Target Google Cloud Project Number (found in Project Settings)"
  type        = string
}

variable "github_org" {
  description = "GitHub Owner or Organization"
  type        = string
}

variable "frontend_repo_name" {
  description = "Frontend repository name for Firebase Hosting"
  type        = string
}

variable "backend_repo_name" {
  description = "Backend repository name for App Engine / Cloud Run"
  type        = string
}

variable "create_pool" {
  description = "Set to true to create a new Workload Identity Pool; false to reuse existing pool"
  type        = bool
  default     = true
}

variable "pool_id" {
  description = "Workload Identity Pool ID"
  type        = string
  default     = "github-actions-pool"
}

variable "provider_id" {
  description = "Workload Identity Provider ID"
  type        = string
  default     = "github-actions-provider"
}

variable "frontend_service_account_id" {
  description = "Service account ID for Frontend deployment"
  type        = string
  default     = "gh-action-fe-deployer"
}

variable "backend_service_account_id" {
  description = "Service account ID for Backend deployment"
  type        = string
  default     = "gh-action-be-deployer"
}

variable "enable_github_secrets" {
  description = "Whether to automatically create the GitHub repository secrets via Terraform"
  type        = bool
  default     = true
}

variable "region" {
  description = "Default Google Cloud Region for Cloud Run and Artifact Registry"
  type        = string
  default     = "us-central1"
}

variable "deploy_cloud_run" {
  description = "Whether to provision Cloud Run service and Artifact Registry Docker repository"
  type        = bool
  default     = false
}

variable "cloud_run_memory" {
  description = "Memory limit for Cloud Run instance (128Mi is the minimal footprint for Gen1 execution)"
  type        = string
  default     = "128Mi"
}

variable "cloud_run_cpu" {
  description = "CPU limit for Cloud Run instance (1000m / 1 vCPU with request-based throttling)"
  type        = string
  default     = "1000m"
}

variable "cloud_run_min_instances" {
  description = "Minimum number of instances (0 for scale-to-zero free tier)"
  type        = number
  default     = 0
}

variable "cloud_run_max_instances" {
  description = "Maximum number of instances (prevents runaway scaling and unexpected bills)"
  type        = number
  default     = 2
}

variable "artifact_retention_count" {
  description = "Number of recent container image versions to retain in Artifact Registry (1 active + 1 rollback)"
  type        = number
  default     = 2
}

variable "github_token" {
  description = "GitHub Personal Access Token with repo scope (or set via GITHUB_TOKEN environment variable)"
  type        = string
  default     = null
  sensitive   = true
}
