# ☁️ Cloud Infrastructure Orchestrator

[![Terraform](https://img.shields.io/badge/Terraform-1.11_IaC-844FBA?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![Google Cloud](https://img.shields.io/badge/Google_Cloud-WIF_&_Cloud_Run-4285F4?logo=googlecloud&logoColor=white)](https://cloud.google.com/)
[![GCS Remote State](https://img.shields.io/badge/State_Backend-GCS_Bucket_Versioning-00C853?logo=googlecloud&logoColor=white)](https://cloud.google.com/storage)
[![Artifact Registry](https://img.shields.io/badge/Artifact_Registry-2--Version_Retention-EA4335?logo=docker&logoColor=white)](https://cloud.google.com/artifact-registry)
[![Zero Keys](<https://img.shields.io/badge/Security-Zero_JSON_Keys_(OIDC)-00B0FF>)](https://cloud.google.com/iam/docs/workload-identity-federation)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Production-ready Terraform Infrastructure as Code (IaC) orchestrating **Google Cloud Platform (GCP)** and **Firebase Hosting**. Implements **Workload Identity Federation (WIF)**, **GCS Remote State Backend with Versioning**, **128 MiB Cloud Run micro-footprint**, and **Automated 2-Version Artifact Registry cleanup policies** without static JSON service account keys.

---

## 🏛️ Ecosystem Architecture: Unified Keyless WIF Pool

```mermaid
flowchart TD
    subgraph GitHub["GitHub Actions CI/CD (Ephemeral Runners)"]
        OIDC["GitHub OIDC Token Issuer\n(token.actions.githubusercontent.com)"]
        RUNNER_FE["Frontend Runner\n(prj-generic-gallery)"]
        RUNNER_BE["Backend Runner\n(ms-generic-gallery)"]
        RUNNER_IAC["Infra Orchestrator Runner\n(infra-cloud-orchestrator)"]
    end

    subgraph GCP_IAM["Google Cloud IAM & Workload Identity"]
        WIP["Single Central WIF Pool\n(gh-gae-pool)"]
        PROVIDER["WIF Provider\n(gh-gae-provider)"]
        SA_FE["Frontend Service Account\n(gh-action-fe-deployer)"]
        SA_BE["Backend Service Account\n(gh-action-be-deployer)"]
        SA_TF["Terraform IaC Service Account\n(github-action-680566572)"]
    end

    subgraph GCP_SERVICES["Google Cloud & Firebase Production Services"]
        GCS_STATE[("GCS Remote State Bucket\ngs://${project_id}-tfstate\n(Versioning Enabled)")]
        CR["Cloud Run (ms-generic-gallery)\n128 MiB / Gen1 / Scale 0-2"]
        AR["Artifact Registry (apps)\n2-Version Retention Policy"]
        FB["Firebase Hosting\nGlobal Edge CDN"]
    end

    OIDC --> WIP
    WIP --> PROVIDER

    RUNNER_FE -.->|Short-Lived OIDC| SA_FE
    RUNNER_BE -.->|Short-Lived OIDC| SA_BE
    RUNNER_IAC -.->|Short-Lived OIDC| SA_TF

    SA_FE -->|Deploys Static Assets| FB
    SA_BE -->|Pushes Docker Images| AR
    SA_BE -->|Deploys Container| CR
    SA_TF -->|Locks & Manages State| GCS_STATE
    SA_TF -->|Provisions & Manages| AR
    SA_TF -->|Provisions & Manages| CR
```

---

## 🌟 Enterprise Engineering Wins

### 1. 🔑 Zero JSON Service Account Keys Forever

- **OIDC Token Exchange**: GitHub Actions runners authenticate dynamically by exchanging short-lived JWT tokens with Google's Security Token Service (`sts.googleapis.com`).
- Eliminates service account key generation, downloading, and annual rotation risks.
- If a GitHub runner is compromised, no static credentials or `.json` keys exist to be leaked.

### 2. 🗄️ Resilient GCS Remote State Management

- **Persistent Cloud Storage Backend (`gs://${project_id}-tfstate`)**: Backed by a dedicated GCS bucket with **Object Versioning** enabled.
- **Solves Ephemeral Runner Drift**: GitHub Actions runners are ephemeral; storing state in GCS eliminates `Error 409: Resource already exists` conflicts and guarantees atomic state locking via Google Cloud Storage.
- **Dynamic Project Configuration**: Initialized dynamically via:
  ```bash
  terraform init -backend-config="bucket=${GCP_PROJECT_ID}-tfstate"
  ```
  The code contains **zero hardcoded bucket names**, making it reusable across any GCP environment.

### 3. 📦 Automated 2-Version Artifact Registry Cleanup Policy

- Configured with native GCP declarative `cleanup_policies` on `google_artifact_registry_repository.apps_docker`.
- Automatically enforces `keep_count = 2` for tagged release images and deletes stale untagged layer manifests daily, preventing storage quota exhaustion and reducing GCP billing.

### 4. ⚡ 128 MiB Cloud Run Service Orchestration

- Declaratively provisions `google_cloud_run_v2_service.backend` with **128 MiB** memory and **1000m CPU**.
- Sets `execution_environment = "EXECUTION_ENVIRONMENT_GEN1"` and request-based CPU allocation (`cpu_idle = true`).
- Configures scale-to-zero (`min_instance_count = 0`, `max_instance_count = 2`), ensuring $0 idle hosting cost.

### 5. 🎯 Granular Least-Privilege IAM Roles

| Service Account               | Role Scope                                                                    | Justification                                                                                            |
| :---------------------------- | :---------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------- |
| **`gh-action-fe-deployer`**   | `roles/firebasehosting.admin`<br>`roles/serviceusage.serviceUsageConsumer`    | Deploys static Angular bundles to Firebase Hosting CDN and inspects enabled APIs.                        |
| **`gh-action-be-deployer`**   | `roles/run.admin`<br>`roles/artifactregistry.writer`<br>`roles/storage.admin` | Pushes Node 26 Docker images to Artifact Registry, deploys Cloud Run revisions, and prunes old versions. |
| **`github-action-680566572`** | `roles/owner` (or fine-grained IaC Admin)                                     | Provisions infrastructure, manages IAM bindings, and locks GCS state bucket.                             |

---

## 📁 Repository Structure & Scaffold

```text
infra-cloud-orchestrator/
├── .github/workflows/
│   ├── ci.yml                 # PR quality gate (terraform fmt, init, validate)
│   └── provision-infra.yml    # Parameterized workflow dispatch to plan/apply via GCS state
├── versions.tf                # Terraform (~> 1.11), Google (~> 5.0), GitHub (~> 6.0), and GCS backend
├── variables.tf               # Parameterized variables (memory, cpu, scaling, retention, repos)
├── main.tf                    # APIs enablement & conditional Workload Identity Pool / Provider
├── frontend.tf                # Frontend Deployer SA, Firebase Hosting IAM & WIF binding
├── backend.tf                 # Backend Deployer SA, Cloud Run (128Mi), & Artifact Registry
├── github_secrets.tf          # Auto-provisions encrypted GitHub Actions repository secrets
├── outputs.tf                 # Emits Provider, SA emails, and bucket resource names
├── terraform.tfvars.example   # Reusable configuration template
└── README.md                  # Comprehensive architectural guide & runbooks
```

---

## 🚀 Quickstart & Deployment Guide

### 1. Prerequisites

- **Terraform** >= 1.10.0 (tested on 1.11.x)
- **Google Cloud SDK (`gcloud`)** authenticated with admin privileges:
  ```bash
  gcloud auth login
  gcloud auth application-default login
  gcloud config set project YOUR_PROJECT_ID
  ```
- **GitHub Personal Access Token** with `repo` scope (allows Terraform to automatically provision encrypted repository secrets in your GitHub repos).

### 2. Configure Variables

Copy the example variables file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
project_id         = "meraki-public"
project_number     = "961243721322"
github_org         = "himanshusaraswat"
frontend_repo_name = "prj-generic-gallery"
backend_repo_name  = "ms-generic-gallery"

# Workload Identity Pool
create_pool        = false # Set to true for a brand-new project without an existing pool
pool_id            = "gh-gae-pool"
provider_id        = "gh-gae-provider"

# Automated GitHub Secrets provisioning
enable_github_secrets = true

# Cloud Run Configuration
cloud_run_memory      = "128Mi"
cloud_run_cpu         = "1000m"
cloud_run_max_scale   = 2
artifact_keep_count   = 2
```

### 3. Initialize with GCS Remote State

```bash
# Initialize Terraform pointing to your persistent GCS state bucket
terraform init -backend-config="bucket=${GCP_PROJECT_ID}-tfstate"

# Validate configuration syntax
terraform validate
```

### 4. Review Plan & Apply

```bash
export GITHUB_TOKEN="ghp_your_github_personal_access_token"

# Review proposed infrastructure changes
terraform plan

# Apply changes to GCP and GitHub
terraform apply
```

### 5. Automated GitHub Secrets

When `terraform apply` finishes, it automatically creates encrypted repository secrets in your GitHub repositories:

1. **Frontend Repository Secrets (`prj-generic-gallery`)**:
   - `WORKLOAD_IDENTITY_PROVIDER`
   - `FIREBASE_SERVICE_ACCOUNT_EMAIL`
   - `GCP_PROJECT_ID`
2. **Backend Repository Secrets (`ms-generic-gallery`)**:
   - `DEV_STG_WORKLOAD_IDENTITY_PROVIDER`
   - `DEV_STG_WIP_SA`
   - `DEV_STG_PROJECT_ID`

---

## 🔒 GitHub Actions Deployment Example (Keyless WIF)

Here is how your Frontend and Backend deployment workflows authenticate without static keys:

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
        run: npx firebase-tools deploy --only hosting --project ${{ secrets.GCP_PROJECT_ID }}
```

---

## ❓ FAQ & Troubleshooting

### Q: Why do we include `roles/serviceusage.serviceUsageConsumer`?

`firebase-tools` >= 15.35.0 queries `serviceusage.googleapis.com` before deployments to verify enabled APIs. Without this role, Firebase deploys fail with HTTP 403 Forbidden.

### Q: Why does Terraform use a GCS remote state backend?

GitHub Actions runners are ephemeral. Without remote state persistence, each runner runs `terraform apply` with an empty state, triggering `Error 409: Resource already exists`. The GCS backend `gs://${project_id}-tfstate` guarantees persistent, atomic state management across all runs.

### Q: How do I onboard another project?

Copy `terraform.tfvars.example` to `my-project.tfvars`, set `create_pool = true`, populate the new Project ID and Project Number, and run:

```bash
terraform init -backend-config="bucket=my-project-tfstate"
terraform apply -var-file="my-project.tfvars"
```

---

## 📄 License

MIT © [Himanshu Saraswat](https://github.com/himanshusaraswat)
