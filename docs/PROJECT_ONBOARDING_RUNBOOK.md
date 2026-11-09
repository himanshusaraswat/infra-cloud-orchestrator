# Project Onboarding Runbook: Keyless GCP & Firebase Deployments

This runbook provides the exact, copy-pasteable steps to provision Workload Identity Federation (WIF) for any new Google Cloud & Firebase project and connect it to GitHub Actions.

---

## ⏱️ Estimated Time: 2 Minutes

---

## 📋 Prerequisites
1. **Google Cloud Account**: Owner or IAM Admin access to the target GCP/Firebase project.
2. **GitHub Account**: Admin/Write access to the target frontend/backend repositories.
3. **Local CLI Tools**:
   - `terraform` >= 1.5.0
   - `gcloud` authenticated (`gcloud auth login && gcloud auth application-default login`)
   - GitHub Personal Access Token (classic) with `repo` scope (optional, for automated secret creation).

---

## 🛠️ Step 1: Collect Target Project Details

From your [Google Cloud Console](https://console.cloud.google.com/) or [Firebase Console](https://console.firebase.google.com/):

| Parameter | Example Value | Description |
| :--- | :--- | :--- |
| **`project_id`** | `my-prod-project` | Target Google Cloud Project ID |
| **`project_number`** | `123456789012` | Found on GCP Project Dashboard / Overview |
| **`github_org`** | `my-company-or-user` | GitHub username or organization |
| **`frontend_repo_name`** | `my-frontend-app` | GitHub repo for Firebase Hosting |
| **`backend_repo_name`** | `my-backend-api` | GitHub repo for App Engine / Cloud Run |

---

## 🚀 Step 2: Provision Infrastructure via Terraform

Navigate to your `infra-cloud-orchestrator` repository:

```bash
cd infra-cloud-orchestrator
```

### Option A: Fully Automated (Creates GCP resources + Injects GitHub Secrets)

```bash
export GITHUB_TOKEN="ghp_your_personal_access_token_here"

/tmp/terraform apply \
  -var="project_id=my-prod-project" \
  -var="project_number=123456789012" \
  -var="github_org=my-company-or-user" \
  -var="frontend_repo_name=my-frontend-app" \
  -var="backend_repo_name=my-backend-api" \
  -var="create_pool=true" \
  -var="enable_github_secrets=true"
```

### Option B: Via `.tfvars` File

1. Create `projects/my-prod-project.tfvars`:
   ```hcl
   project_id         = "my-prod-project"
   project_number     = "123456789012"
   github_org         = "my-company-or-user"
   frontend_repo_name = "my-frontend-app"
   backend_repo_name  = "my-backend-api"
   create_pool        = true
   enable_github_secrets = true
   ```
2. Run:
   ```bash
   export GITHUB_TOKEN="ghp_your_token"
   /tmp/terraform apply -var-file="projects/my-prod-project.tfvars"
   ```

---

## 📦 Step 3: Add CI/CD Workflow to the Target Repositories

### A. Frontend Repository (`my-frontend-app`)
Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Firebase Hosting

on:
  push:
    branches:
      - main  # or develop

permissions:
  contents: read
  id-token: write # Mandatory for OIDC Workload Identity token exchange

jobs:
  build_and_deploy:
    runs-on: ubuntu-latest
    steps:
      - id: checkout
        name: Checkout Code
        uses: actions/checkout@v4

      - id: setupNode
        name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: 'npm'

      - id: install
        name: Install Dependencies
        run: npm ci

      - id: build
        name: Build Artifacts
        run: npm run build

      # 1. Keyless authentication via Google WIF
      - id: auth
        name: Authenticate to Google Cloud (Keyless WIF)
        uses: google-github-actions/auth@v2
        with:
          project_id: ${{ secrets.GCP_PROJECT_ID }}
          workload_identity_provider: ${{ secrets.WORKLOAD_IDENTITY_PROVIDER }}
          service_account: ${{ secrets.FIREBASE_SERVICE_ACCOUNT_EMAIL }}
          create_credentials_file: true

      # 2. Deploy directly via Firebase CLI using Google ADC
      - id: deploy
        name: Deploy to Firebase Hosting
        env:
          GOOGLE_APPLICATION_CREDENTIALS: ${{ steps.auth.outputs.credentials_file_path }}
        run: npx firebase-tools@15.34.0 deploy --only hosting --project ${{ secrets.GCP_PROJECT_ID }}
```

### B. Backend Repository (`my-backend-api`)
Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Google Cloud App Engine

on:
  push:
    branches:
      - main  # or develop

permissions:
  contents: read
  id-token: write

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 22

      - run: npm ci
      - run: npm run build

      - id: auth
        name: Authenticate to Google Cloud (Keyless WIF)
        uses: google-github-actions/auth@v2
        with:
          project_id: ${{ secrets.DEV_STG_PROJECT_ID }}
          workload_identity_provider: ${{ secrets.DEV_STG_WORKLOAD_IDENTITY_PROVIDER }}
          service_account: ${{ secrets.DEV_STG_WIP_SA }}

      - id: deploy
        name: Deploy to App Engine
        uses: google-github-actions/deploy-appengine@v2
        with:
          deliverables: './app.yml'
```

---

## 🔍 Verification & Troubleshooting

### 1. How to verify token exchanges in Google Cloud Console
1. Open [IAM & Admin ➔ Workload Identity Pools](https://console.cloud.google.com/iam-admin/workload-identity-pools).
2. Click on your pool (e.g. `github-actions-pool` or `gh-gae-pool`).
3. Under **Workload Identity Federation usage**, you should see an active graph showing token exchanges per second.

### 2. Common Pitfalls & Solutions

| Symptom | Cause | Solution |
| :--- | :--- | :--- |
| `SyntaxError: Unexpected token '/', "/home/runn"...` | Using legacy `FirebaseExtended/action-hosting-deploy` with credential path string | Use `npx firebase-tools deploy` directly with `GOOGLE_APPLICATION_CREDENTIALS` |
| `Error: Failed to authenticate, have you run firebase login?` | Missing `attribute.repository` mapping in the OIDC Provider | Ensure the OIDC Provider maps `"attribute.repository": "assertion.repository"` |
| `Permission denied to get service [firebasehosting.googleapis.com] (HTTP 403)` | `firebase-tools` checking Service Usage API | Service Account must have `roles/serviceusage.serviceUsageConsumer` |
| `the GitHub Action workflow must specify exactly one of "workload_identity_provider" or "credentials_json"` | GitHub Secret is empty or missing | Set the secret in GitHub **Settings ➔ Secrets and variables ➔ Actions ➔ Secrets** |
