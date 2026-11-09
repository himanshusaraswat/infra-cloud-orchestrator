output "workload_identity_provider" {
  description = "Single Workload Identity Provider driving all cloud deployments (FE + BE). Set in GitHub repository secrets."
  value       = "projects/${var.project_number}/locations/global/workloadIdentityPools/${var.pool_id}/providers/${var.provider_id}"
}

output "frontend_service_account_email" {
  description = "Frontend Service Account email. Set as FIREBASE_SERVICE_ACCOUNT_EMAIL in Frontend GitHub secrets."
  value       = "${var.frontend_service_account_id}@${var.project_id}.iam.gserviceaccount.com"
}

output "backend_service_account_email" {
  description = "Backend Service Account email. Set as DEV_STG_WIP_SA in Backend GitHub secrets."
  value       = "${var.backend_service_account_id}@${var.project_id}.iam.gserviceaccount.com"
}

output "cloud_run_url" {
  description = "Public URL of the deployed Cloud Run service (if enabled)"
  value       = var.deploy_cloud_run ? google_cloud_run_v2_service.backend[0].uri : null
}

output "artifact_registry_repo" {
  description = "Docker repository URI in Artifact Registry (if enabled)"
  value       = var.deploy_cloud_run ? "${var.region}-docker.pkg.dev/${var.project_id}/apps" : null
}
