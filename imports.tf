# Declarative imports for pre-existing cloud resources to ensure idempotent pure IaC
import {
  to = google_artifact_registry_repository.apps_docker[0]
  id = "projects/meraki-public/locations/us-central1/repositories/apps"
}

import {
  to = google_service_account.frontend_deployer
  id = "projects/meraki-public/serviceAccounts/gh-action-fe-deployer@meraki-public.iam.gserviceaccount.com"
}
