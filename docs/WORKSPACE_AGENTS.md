---
entity_id: workspace-hs-governance
name: Workspace Multi-Agent Governance & Zero-Drift Protocol
version: 1.0.0
applies_to:
  - prj-generic-gallery
  - ms-generic-gallery
  - infra-cloud-orchestrator
governance_tier: enterprise-strict
---

# 🤖 Workspace Agent Governance & Zero-Drift Protocol

This document defines the **mandatory operational rules** for all AI coding assistants (Antigravity, subagents, swarms) and human contributors operating across the Generic Gallery Platform workspace.

---

## 📜 The 5 Golden Rules of Workspace Governance

### 1. 🔄 Rule 1: The Atomic Code-Doc Synchronization Contract

> **"Never mark a task complete if code or tests have changed without synchronizing the Knowledge Graph and READMEs in the exact same turn."**

- **When code changes**:
  - If a route or schema is added/modified in `ms-generic-gallery`, immediately update:
    1. `ms-generic-gallery/README.md` (Route catalog & schema)
    2. `prj-generic-gallery/src/app/core/images-from-server.service.ts` (API Client)
    3. `infra-cloud-orchestrator/docs/SYSTEM_KNOWLEDGE_GRAPH.md` (Contract Registry)
  - If a new environment variable or Terraform configuration is added in `infra-cloud-orchestrator`, update `infra-cloud-orchestrator/README.md` and the Knowledge Graph.
- **When tests change**:
  - Always execute the tests locally and capture the exact count of passing tests.
  - Update the SVG shields/badges and testing summary tables in the corresponding `README.md`.

### 2. 🛡️ Rule 2: Absolute Public Sanitization Protocol

> **"Zero real GCP Project Numbers, real Project IDs, private SA emails, or MongoDB Atlas cluster hostnames may ever appear in documentation."**

- Use the following standardized generic placeholders in all markdown, YAML, or example files:
  - Project Number: `<PROJECT_NUMBER>`
  - Project ID: `<PROJECT_ID>`
  - Service Account Email: `<SA_NAME>@<PROJECT_ID>.iam.gserviceaccount.com`
  - WIF Pool: `gh-actions-pool`
  - WIF Provider: `gh-actions-provider`
  - MongoDB URI: `mongodb+srv://<USER>:<PASSWORD>@your-cluster.mongodb.net/<DB_NAME>?retryWrites=true&w=majority`
- Never commit private keys, real tokens, or personal emails.

### 3. 🎯 Rule 3: Branch Parity & Lockstep Git Synchronization

> **"The `develop` and `main` branches across all three repositories must remain in lockstep parity."**

- Work is committed to `develop`.
- When changes are validated, `main` must be fast-forward synchronized with `develop`:
  ```sh
  git checkout main && git merge --ff-only develop && git push origin main && git checkout develop
  ```
- Before ending a turn, verify that all three repositories are on `develop`, working trees are clean (`git status`), and both `develop` and `main` match their remote tracking branches.

### 4. 🧪 Rule 4: Shift-Left Pre-Commit Verification

> **"Never bypass local pre-commit hooks (`git commit --no-verify` is strictly prohibited)."**

- Before committing, verify that the local Husky pre-commit hooks pass:
  - `prj-generic-gallery`: `npm run typecheck` + `npm run test:unit`
  - `ms-generic-gallery`: `npm run typecheck` + `npm test`
  - `infra-cloud-orchestrator`: `terraform fmt -check`

### 5. 🌐 Rule 5: Framework-Specific Standards Compliance

> **"Frontend code must adhere to Angular 22 Zoneless and Google Modern Web Guidance (MWG); Backend code must adhere to Fastify 5 128 MiB Cloud Run constraints."**

- Refer to the individual repository spoke rules:
  - [`prj-generic-gallery/AGENTS.md`](file:///Users/himanshusaraswat/workspace_hs/prj-generic-gallery/AGENTS.md)
  - [`ms-generic-gallery/AGENTS.md`](file:///Users/himanshusaraswat/workspace_hs/ms-generic-gallery/AGENTS.md)
  - [`infra-cloud-orchestrator/AGENTS.md`](file:///Users/himanshusaraswat/workspace_hs/infra-cloud-orchestrator/AGENTS.md)

---

## 🤖 Agent Turn Checklist

Before marking any task complete, every agent must mentally verify this checklist:

```markdown
- [ ] Code compiles and typechecks cleanly (0 TypeScript / Terraform errors)
- [ ] Automated tests run locally and pass 100%
- [ ] Test count badges and summary tables in README.md match the real test runner output
- [ ] System Knowledge Graph contract registry updated if API routes/types changed
- [ ] Public documentation sanitized (0 real GCP Project IDs / numbers / hostnames)
- [ ] Git working tree clean across all 3 repositories
- [ ] `develop` and `main` branches synchronized in all 3 repositories
```
