# Cloud Infrastructure Orchestrator (GCP & Firebase Workload Identity Federation)

Production-ready Terraform Infrastructure as Code (IaC) to configure **Workload Identity Federation (WIF)** for Google Cloud Platform (GCP) and Firebase Hosting.

Eliminates the operational overhead and security vulnerabilities of static JSON service account keys in GitHub Actions.

---

## 🏛️ Architecture: Single Unified Pool for All Cloud Services

```
                                      +------------------------------------+
                                      |     GitHub Actions OIDC Issuer     |
                                      | token.actions.githubusercontent.com|
                                      +-----------------+------------------+
                                                        |
                                                        v
                                      +------------------------------------+
                                      |  Workload Identity Pool (Single)   |
                                      |       github-actions-pool          |
                                      +-----------------+------------------+
                                                        |
                         +------------------------------+------------------------------+
                         |                                                             |
                         v                                                             v
       +------------------------------------+                        +------------------------------------+
       |   Frontend Deployer (Firebase)     |                        |    Backend Deployer (App Engine)   |
       |     gh-action-fe-deployer          |                        |       gh-action-be-deployer        |
       +-----------------+------------------+                        +-----------------+------------------+
                         |                                                             |
                         | [roles/firebasehosting.admin]                               | [roles/appengine.appAdmin]
                         | [roles/serviceusage.serviceUsageConsumer]                   | [roles/storage.admin]
                         |                                                             | [roles/serviceusage.serviceUsageConsumer]
                         v                                                             v
       +------------------------------------+                        +------------------------------------+
       |          Firebase Hosting          |                        |        App Engine / Cloud Run      |
       |       (your-frontend-repo)         |                        |        (your-backend-repo)         |
       +------------------------------------+                        +------------------------------------+
```

### Key Design Highlights
- **Single Workload Identity Pool**: One pool centrally federates identities for both Frontend and Backend, following Google Cloud security best practices.
- **Granular Least-Privilege Access**:
  - The Frontend repository can **only** impersonate the Frontend deployer service account.
  - The Backend repository can **only** impersonate the Backend deployer service account.
- **Zero JSON Keys Forever**: GitHub runners dynamically exchange temporary OIDC tokens for Google OAuth access tokens. No secrets to rotate or leak.
- **100% Variable-Driven & Automated Secrets**: Fully parameterized. Terraform automatically provisions encrypted GitHub Actions repository secrets in your repos.

---

## 📁 Repository Structure

```
.
├── .github/workflows/
│   └── provision-infra.yml   # Interactive workflow_dispatch to plan/apply via GitHub Actions
├── versions.tf               # Terraform and Provider versions (Google ~> 5.0, GitHub ~> 6.0)
├── variables.tf              # Configurable parameters (project_id, repos, pool_id, etc.)
├── main.tf                   # APIs enablement & conditional Workload Identity Pool / Provider
├── frontend.tf               # Frontend Service Account, Firebase Hosting IAM, & WIF binding
├── backend.tf                # Backend Service Account, App Engine IAM, & WIF binding
├── github_secrets.tf         # Automatically creates encrypted repository secrets in GitHub
├── outputs.tf                # Generates the exact WIP and SA values for GitHub Secrets
├── terraform.tfvars.example  # Example values ready to copy and run
├── .gitignore                # Protects against committing state or sensitive tfvars
└── README.md                 # Complete documentation & usage guide
```

---

## 🚀 Quickstart Guide

### 1. Prerequisites
- **Terraform** >= 1.5.0
- **Google Cloud SDK (`gcloud`)** authenticated with admin privileges:
  ```bash
  gcloud auth login
  gcloud auth application-default login
  gcloud config set project YOUR_PROJECT_ID
  ```
- **GitHub Personal Access Token** with `repo` scope (to let Terraform automatically configure GitHub Secrets).

### 2. Configure Variables
Copy the example variables file:
```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your project details:
```hcl
project_id         = "your-project-id"
project_number     = "123456789012"
github_org         = "your-github-org"
frontend_repo_name = "your-frontend-repo"
backend_repo_name  = "your-backend-repo"

# For a brand-new project:
create_pool        = true
pool_id            = "github-actions-pool"
provider_id        = "github-actions-provider"

# Automated GitHub Secrets:
enable_github_secrets = true
```

### 3. Initialize & Validate
```bash
terraform init
terraform validate
```

### 4. Review Plan & Apply
```bash
export GITHUB_TOKEN="ghp_your_personal_access_token"

# Review proposed changes
terraform plan

# Apply to GCP and GitHub
terraform apply
```

### 5. Configured GitHub Secrets
When `terraform apply` finishes, it automatically creates encrypted repository secrets in GitHub:

1. **Frontend Repository Secrets**:
   - `WORKLOAD_IDENTITY_PROVIDER`
   - `FIREBASE_SERVICE_ACCOUNT_EMAIL`
   - `GCP_PROJECT_ID`
2. **Backend Repository Secrets**:
   - `DEV_STG_WORKLOAD_IDENTITY_PROVIDER`
   - `DEV_STG_WIP_SA`
   - `DEV_STG_PROJECT_ID`

---

## 🔒 GitHub Actions Deployment Example (Keyless WIF)

Your Frontend repository deployment workflow (e.g. `.github/workflows/deploy.yml`):

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write # Required for Workload Identity Federation

    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Authenticate to Google Cloud (Keyless WIF)
        id: auth
        uses: google-github-actions/auth@v2
        with:
          project_id: ${{ secrets.GCP_PROJECT_ID }}
          workload_identity_provider: ${{ secrets.WORKLOAD_IDENTITY_PROVIDER }}
          service_account: ${{ secrets.FIREBASE_SERVICE_ACCOUNT_EMAIL }}
          create_credentials_file: true

      - name: Deploy to Firebase Hosting
        env:
          GOOGLE_APPLICATION_CREDENTIALS: ${{ steps.auth.outputs.credentials_file_path }}
        run: npx firebase-tools@15.34.0 deploy --only hosting --project ${{ secrets.GCP_PROJECT_ID }}
```

---

## ❓ FAQ

### Q: Why do we include `roles/serviceusage.serviceUsageConsumer`?
`firebase-tools` >= 15.35.0 queries `serviceusage.googleapis.com` before deployments to verify enabled APIs. Without this role, Firebase deploys fail with HTTP 403 Forbidden.

### Q: How do I onboard another project?
Copy `terraform.tfvars.example` to `my-project.tfvars`, set `create_pool = true`, populate the new Project ID and Project Number, and run:
```bash
terraform apply -var-file="my-project.tfvars"
```
It provisions a dedicated WIF pool, providers, and service accounts for that project.
