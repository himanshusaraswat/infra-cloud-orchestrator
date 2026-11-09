/**
 * Automatically create GitHub Actions Repository Secrets.
 * Eliminates manual configuration in GitHub Settings UI.
 */

# 1. Frontend Repository Secrets
resource "github_actions_secret" "fe_wip" {
  count           = var.enable_github_secrets ? 1 : 0
  repository      = var.frontend_repo_name
  secret_name     = "WORKLOAD_IDENTITY_PROVIDER"
  plaintext_value = "projects/${var.project_number}/locations/global/workloadIdentityPools/${var.pool_id}/providers/${var.provider_id}"
}

resource "github_actions_secret" "fe_sa" {
  count           = var.enable_github_secrets ? 1 : 0
  repository      = var.frontend_repo_name
  secret_name     = "FIREBASE_SERVICE_ACCOUNT_EMAIL"
  plaintext_value = "${var.frontend_service_account_id}@${var.project_id}.iam.gserviceaccount.com"
}

resource "github_actions_secret" "fe_project_id" {
  count           = var.enable_github_secrets ? 1 : 0
  repository      = var.frontend_repo_name
  secret_name     = "GCP_PROJECT_ID"
  plaintext_value = var.project_id
}

# 2. Backend Repository Secrets
resource "github_actions_secret" "be_wip" {
  count           = var.enable_github_secrets ? 1 : 0
  repository      = var.backend_repo_name
  secret_name     = "DEV_STG_WORKLOAD_IDENTITY_PROVIDER"
  plaintext_value = "projects/${var.project_number}/locations/global/workloadIdentityPools/${var.pool_id}/providers/${var.provider_id}"
}

resource "github_actions_secret" "be_sa" {
  count           = var.enable_github_secrets ? 1 : 0
  repository      = var.backend_repo_name
  secret_name     = "DEV_STG_WIP_SA"
  plaintext_value = "${var.backend_service_account_id}@${var.project_id}.iam.gserviceaccount.com"
}

resource "github_actions_secret" "be_project_id" {
  count           = var.enable_github_secrets ? 1 : 0
  repository      = var.backend_repo_name
  secret_name     = "DEV_STG_PROJECT_ID"
  plaintext_value = var.project_id
}
