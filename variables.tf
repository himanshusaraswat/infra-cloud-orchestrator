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

variable "github_token" {
  description = "GitHub Personal Access Token with repo scope (or set via GITHUB_TOKEN environment variable)"
  type        = string
  default     = null
  sensitive   = true
}
