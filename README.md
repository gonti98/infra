# oci-infra — Infrastructure as Code

Declarative infrastructure for the whole flow: cloud resources → Kubernetes
cluster → application, managed with OpenTofu, GitOps (ArgoCD) and CI/CD.

This repo (`oci-infra`) is the first piece — the cloud layer. See
[Repos](#repos) for the full picture.

> **Status:** work in progress. Stage 0 (foundation) is done, Stage 1 is next.
> See the [Roadmap](#roadmap).

## Layout

```
environments/
  dev/            # per-env OpenTofu config (provider, backend, variables)
run_tofu.sh       # wrapper: fmt → init → validate → plan/apply
.env              # local secrets/vars, gitignored, sourced by run_tofu.sh
```

State lives in an S3-compatible bucket (OCI Object Storage, bucket `tofu-state`,
key `dev/terraform.tfstate`), reached through `AWS_ENDPOINT_URL_S3`.

## Requirements

- OpenTofu >= 1.10 (native state locking via `use_lockfile`), enforced by
  `required_version` in the code
- A Customer Secret Key for OCI Object Storage (state backend)
- An OCI API key (fingerprint, private key file, tenancy/user OCIDs)

## Setup

Create a `.env` file in the repo root (it is gitignored) with the variables
below, then run:

```bash
./run_tofu.sh
```

### Environment variables

`run_tofu.sh` loads `.env` automatically.

```bash
# State backend (S3-compatible API of OCI Object Storage)
AWS_ENDPOINT_URL_S3=https://<namespace>.compat.objectstorage.<region>.oraclecloud.com
AWS_ACCESS_KEY_ID=          # Customer Secret Key: access key
AWS_SECRET_ACCESS_KEY=      # Customer Secret Key: secret

# OCI provider
TF_VAR_region=
TF_VAR_tenancy_ocid=
TF_VAR_user_ocid=
TF_VAR_fingerprint=
TF_VAR_private_key_path=    # path only; the .pem file stays outside the repo
```

Where to get the values:

- **Namespace:** `oci os ns get`
- **Customer Secret Key:** OCI console → user → *Customer secret keys*.
  This is **not** the API key used by the provider.
- **API key / fingerprint:** OCI console → user → *API keys*.

The AWS-style variable names are only there because the OpenTofu `s3` backend
uses the AWS SDK; no AWS account or AWS CLI is needed.

## Usage

```bash
./run_tofu.sh            # plan for dev
./run_tofu.sh apply      # apply for dev
./run_tofu.sh plan prod  # plan for another env (needs environments/prod/, not created yet)
```

`run_tofu.sh` runs, in order: `tofu fmt`, `tofu init`, `tofu validate`, then
the requested action (`plan` by default).
<!-- TODO: verify this matches the script; mention which -backend-config / -var-file it passes -->

Each environment must use its own backend `key` (e.g. `prod/terraform.tfstate`),
otherwise environments overwrite each other's state.
<!-- TODO: say where the key is set (backend.hcl or backend.tf) -->

## Limitations

- Locking uses `use_lockfile` (conditional writes) on OCI's S3-compatible API,
  which is not an AWS-native guarantee. Concurrent behavior is being verified
  (see Stage 0).
- The S3 backend needs several `skip_*` flags and `use_path_style` to work
  with OCI; see `environments/dev/backend.tf`.
  <!-- TODO: confirm the path, or point to backend.hcl if that's where they live -->
- State is not encrypted yet; native OpenTofu state encryption is planned
  (Stage 1), since OCI's S3-compat layer has no AWS SSE-KMS.

## Repos

| Repo | Contents | Change frequency |
| - | - | - |
| `oci-infra` | OpenTofu: network, cluster, buckets, IAM, ArgoCD bootstrap | rarely |
| `k8s-gitops` | manifests for ArgoCD: platform and apps, per environment | often |
| `demo-app` | app code, Dockerfile, tests, CI | most often |

## Roadmap

### Stage 0: foundation

- [x] State backend in OCI Object Storage (S3) with lockfile locking
- [x] Verify locking: two parallel `plan` runs, the second must fail on the lock
- [x] `oci-infra` skeleton with the `dev` environment
- [x] First resource (namespace data source) as an end-to-end test
- [x] README with usage

### Stage 1: network and cluster (`oci-infra`)

- [ ] Kubernetes cluster on an always-free OCI shape
- [ ] Dedicated service user with a narrow IAM policy instead of the admin account
- [ ] Native OpenTofu state encryption (`encryption {}` block)
- [ ] Output with kubeconfig or access instructions

### Stage 2: ArgoCD bootstrap (`oci-infra`)

- [ ] ArgoCD installed via OpenTofu (provider `helm`)
- [ ] A single "root" app pointing at `k8s-gitops` (app-of-apps)
- [ ] From now on the cluster manages itself from git

### Stage 3: platform (`k8s-gitops`)

- [ ] Ingress controller
- [ ] cert-manager (TLS)
- [ ] External Secrets (from OCI Vault) or SOPS — no secrets in the repo
- [ ] Monitoring: Prometheus + Grafana
- [ ] Directory layout: `platform/`, `apps/`, separate overlays per environment (directories, not branches)

### Stage 4: app and CI (`demo-app`)

- [ ] Simple app (API + health check) with tests
- [ ] Pipeline: lint, tests, image build, scan (Trivy), push to registry
- [ ] Last step: PR to `k8s-gitops` bumping the image tag
- [ ] Deployment visible in ArgoCD as a synced app

### Stage 5: CI/CD for infrastructure (`oci-infra`)

- [ ] `plan` on pull requests, result posted as a comment
- [ ] `apply` after merge, with manual approval for `prod`
- [ ] Auth via OIDC or platform secrets, no keys in the repo
- [ ] `tofu fmt -check`, `validate`, `shellcheck`, `tflint`, `trivy config` in the pipeline

### Stage 6: polish

- [ ] `prod` environment (separate state key, separate tfvars)
- [ ] Architecture diagram in the README
- [ ] CI badge, repo pinned on the GitHub profile
- [ ] Decision records (`docs/adr/`): why these tools, and known limitations
