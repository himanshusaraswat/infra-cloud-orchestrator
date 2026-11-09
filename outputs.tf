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
