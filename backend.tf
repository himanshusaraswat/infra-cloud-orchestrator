/**
 * Backend Service (App Engine / Cloud Run) Identity & Permissions
 * Driven by the same shared Workload Identity Pool.
 */

# Dedicated service account for Backend deployment
resource "google_service_account" "backend_deployer" {
  count        = var.create_pool ? 1 : 0
  project      = var.project_id
  account_id   = var.backend_service_account_id
  display_name = "GitHub Actions Backend App Engine Deployer"
}

# IAM Permissions for App Engine
resource "google_project_iam_member" "be_appengine_admin" {
  count   = var.create_pool ? 1 : 0
  project = var.project_id
  role    = "roles/appengine.appAdmin"
  member  = "serviceAccount:${var.backend_service_account_id}@${var.project_id}.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "be_storage_admin" {
  count   = var.create_pool ? 1 : 0
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${var.backend_service_account_id}@${var.project_id}.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "be_service_usage" {
  count   = var.create_pool ? 1 : 0
  project = var.project_id
  role    = "roles/serviceusage.serviceUsageConsumer"
  member  = "serviceAccount:${var.backend_service_account_id}@${var.project_id}.iam.gserviceaccount.com"
}

# Bind Backend GitHub repository to impersonate backend service account via the single shared WIF pool
resource "google_service_account_iam_member" "be_workload_identity_user" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/${var.backend_service_account_id}@${var.project_id}.iam.gserviceaccount.com"
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/projects/${var.project_number}/locations/global/workloadIdentityPools/${var.pool_id}/attribute.repository/${var.github_org}/${var.backend_repo_name}"
}
