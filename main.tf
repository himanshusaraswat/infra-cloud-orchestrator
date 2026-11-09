/**
 * Single Unified Workload Identity Pool for All Cloud Services (FE + BE)
 * Google Cloud Best Practice: One pool per project driving all deployments via GitHub Actions OIDC.
 */

# 1. Enable Required Google Cloud APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "sts.googleapis.com",
    "serviceusage.googleapis.com",
    "firebasehosting.googleapis.com",
    "appengine.googleapis.com"
  ])
  project            = var.project_id
  service            = each.key
  disable_on_destroy = false
}

# 2. Workload Identity Pool (created when create_pool = true for a new project)
resource "google_iam_workload_identity_pool" "shared_pool" {
  count                     = var.create_pool ? 1 : 0
  project                   = var.project_id
  workload_identity_pool_id = var.pool_id
  display_name              = var.pool_id
  description               = "Single identity pool driving all services (Firebase Hosting & App Engine)"
  depends_on                = [google_project_service.required_apis]
}

# 3. Workload Identity OIDC Provider for GitHub Actions
resource "google_iam_workload_identity_pool_provider" "shared_provider" {
  count                              = var.create_pool ? 1 : 0
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.shared_pool[0].workload_identity_pool_id
  workload_identity_pool_provider_id = var.provider_id
  display_name                       = var.provider_id

  attribute_mapping = {
    "google.subject"             = "assertion.sub"
    "attribute.actor"            = "assertion.actor"
    "attribute.repository"       = "assertion.repository"
    "attribute.repository_owner" = "assertion.repository_owner"
  }

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}
