/**
 * Frontend Firebase Hosting Deployment Identity & Permissions
 * Driven by the shared Workload Identity Pool.
 */

# Dedicated service account for Frontend deployment
resource "google_service_account" "frontend_deployer" {
  count        = var.create_pool ? 1 : 0
  project      = var.project_id
  account_id   = var.frontend_service_account_id
  display_name = "GitHub Actions Frontend Firebase Deployer"
}

# Grant Firebase Hosting Admin
resource "google_project_iam_member" "fe_hosting_admin" {
  count   = var.create_pool ? 1 : 0
  project = var.project_id
  role    = "roles/firebasehosting.admin"
  member  = "serviceAccount:${var.frontend_service_account_id}@${var.project_id}.iam.gserviceaccount.com"
}

# Grant Service Usage Consumer (prevents the 403 API check issue)
resource "google_project_iam_member" "fe_service_usage" {
  count   = var.create_pool ? 1 : 0
  project = var.project_id
  role    = "roles/serviceusage.serviceUsageConsumer"
  member  = "serviceAccount:${var.frontend_service_account_id}@${var.project_id}.iam.gserviceaccount.com"
}

# Bind Frontend GitHub repository to impersonate this Service Account via WIF
resource "google_service_account_iam_member" "fe_workload_identity_user" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/${var.frontend_service_account_id}@${var.project_id}.iam.gserviceaccount.com"
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/projects/${var.project_number}/locations/global/workloadIdentityPools/${var.pool_id}/attribute.repository/${var.github_org}/${var.frontend_repo_name}"
}
