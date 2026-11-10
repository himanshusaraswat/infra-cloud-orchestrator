---
entity_id: infra-cloud-orchestrator-agent-guide
name: Terraform 1.11 & Keyless WIF IaC Agent Guide
version: 1.0.0
engine: terraform-1.11
provider: google-cloud-platform
auth: workload-identity-federation-keyless
state_storage: gcs-remote-versioned
---

# ☁️ Infrastructure Agent Guide: Terraform 1.11 & Keyless WIF

This guide defines the IaC architecture, security protocols, and operational procedures for [`infra-cloud-orchestrator`](file:///Users/himanshusaraswat/workspace_hs/infra-cloud-orchestrator/README.md).

---

## 🔑 Part 1: Zero-Secret Keyless Architecture (WIF OIDC)

`infra-cloud-orchestrator` manages infrastructure using **Workload Identity Federation (WIF)**, eliminating static long-lived Service Account JSON keys.

### 1. Mandatory Identity Rules

- ❌ **NEVER** declare `google_service_account_key` resources in Terraform.
- ❌ **NEVER** export or commit `.json` credentials to GitHub Secrets or local workspaces.
- ✅ All CI/CD pipelines use `google-github-actions/auth@v2` with `workload_identity_provider` and `service_account` impersonation.
- ✅ Bound strictly to repository identity via attribute conditions:
  ```hcl
  attribute_condition = "assertion.repository == 'himanshusaraswat/infra-cloud-orchestrator'"
  ```

---

## 🗄️ Part 2: State Management & Remote Backend

### 1. Remote GCS Backend

- Terraform state is stored securely in a Google Cloud Storage (GCS) bucket with object versioning enabled.
- State locking is handled natively by GCS.
- Initialization pattern:
  ```sh
  terraform init -backend-config="bucket=${PROJECT_ID}-tfstate"
  ```
- ❌ **NEVER** commit `terraform.tfstate` or `terraform.tfstate.backup` to Git.

---

## 📦 Part 3: Resource Invariants & Policy as Code

### 1. Cloud Run Microservice Constraints

- Memory: Exactly `128Mi` (enforce via `limits = { memory = "128Mi", cpu = "1000m" }`).
- CPU Throttling: `cpu_idle = true` to ensure zero costs during idle periods.
- Environment: Always inject `NODE_OPTIONS="--max-old-space-size=90"`.

### 2. Artifact Registry Lifecycle Management

- Retain only the **2 most recent container versions** to prevent unbounded storage costs:
  ```hcl
  cleanup_policies {
    id     = "keep-minimum-versions"
    action = "KEEP"
    most_recent_versions {
      keep_count = 2
    }
  }
  ```

---

## 🚦 Part 4: Shift-Left Quality Gate

Before pushing any commit, run:

```sh
# 1. Format Check
terraform fmt -check -recursive

# 2. Syntax Validation
terraform validate
```

Husky pre-commit hooks (`.husky/pre-commit`) will reject commits if formatting fails.
