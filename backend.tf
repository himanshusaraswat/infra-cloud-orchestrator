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

# IAM Permissions for App Engine & Cloud Run Deployment
resource "google_project_iam_member" "be_appengine_admin" {
  count   = var.create_pool ? 1 : 0
  project = var.project_id
  role    = "roles/appengine.appAdmin"
  member  = "serviceAccount:${var.backend_service_account_id}@${var.project_id}.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "be_cloudrun_admin" {
  count   = var.create_pool ? 1 : 0
  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${var.backend_service_account_id}@${var.project_id}.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "be_artifactregistry_writer" {
  count   = var.create_pool ? 1 : 0
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${var.backend_service_account_id}@${var.project_id}.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "be_service_account_user" {
  count   = var.create_pool ? 1 : 0
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
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

# --------------------------------------------------------------------------------------------------
# Optional Managed Cloud Run Service & Artifact Registry Docker Repository
# --------------------------------------------------------------------------------------------------

resource "google_artifact_registry_repository" "apps_docker" {
  count         = var.deploy_cloud_run ? 1 : 0
  project       = var.project_id
  location      = var.region
  repository_id = "apps"
  description   = "Docker container registry for backend microservices"
  format        = "DOCKER"

  cleanup_policy_dry_run = false

  # Policy 1: Always retain the N most recent image versions (1 active + 1 rollback)
  cleanup_policies {
    id     = "keep-recent-versions"
    action = "KEEP"
    most_recent_versions {
      keep_count = var.artifact_retention_count
    }
  }

  # Policy 2: Automatically delete untagged container image digests (free up storage immediately)
  cleanup_policies {
    id     = "delete-untagged"
    action = "DELETE"
    condition {
      tag_state = "UNTAGGED"
    }
  }

  # Policy 3: Purge historical tagged versions older than 30 days
  cleanup_policies {
    id     = "delete-older-than-30d"
    action = "DELETE"
    condition {
      tag_state  = "TAGGED"
      older_than = "2592000s" # 30 days
    }
  }
}

resource "google_cloud_run_v2_service" "backend" {
  count    = var.deploy_cloud_run ? 1 : 0
  project  = var.project_id
  name     = var.backend_repo_name
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    execution_environment = "EXECUTION_ENVIRONMENT_GEN1"

    scaling {
      min_instance_count = var.cloud_run_min_instances
      max_instance_count = var.cloud_run_max_instances
    }

    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/apps/${var.backend_repo_name}:latest"
      resources {
        limits = {
          cpu    = var.cloud_run_cpu
          memory = var.cloud_run_memory
        }
        cpu_idle          = true
        startup_cpu_boost = true
      }
      ports {
        container_port = 3000
      }
      env {
        name  = "NODE_ENV"
        value = "production"
      }
      env {
        name  = "NODE_OPTIONS"
        value = "--max-old-space-size=90"
      }
    }
  }

  depends_on = [google_artifact_registry_repository.apps_docker]
}

resource "google_cloud_run_v2_service_iam_member" "backend_public_invoker" {
  count    = var.deploy_cloud_run ? 1 : 0
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.backend[0].name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
