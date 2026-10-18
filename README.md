# oci-infra — Infrastructure as Code

Declarative infrastructure for the whole flow: cloud resources → Kubernetes
cluster → application, managed with OpenTofu, GitOps (ArgoCD) and CI/CD.

This repo (`oci-infra`) is the first piece — the cloud layer. See
[Repos](#repos) for the full picture.

> **Status:** work in progress. Stage 0 (foundation) is done, Stage 1
> (network, compute, cluster) is in progress. See the [Roadmap](#roadmap).

## Layout

```
environments/
  dev/
    backend.tf          # s3 backend: skip_* flags and use_path_style for OCI
    backend.hcl         # bucket, key, region of the state
    provider.tf, versions.tf
    main.tf             # calls the modules
    variables.tf, outputs.tf
    dev.auto.tfvars     # non-secret values for dev, loaded automatically
modules/
  network/              # VCN, internet gateway, route table, security list, subnet
  compute/              # Always Free Ampere A1 VM (2 OCPU, 12 GB)
run_tofu.sh             # wrapper: fmt → init → validate → plan/apply
.env                    # local secrets, gitignored, sourced by run_tofu.sh
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

Secrets and account-specific values go to `.env`. `run_tofu.sh` loads it
automatically.

```bash
# State backend (S3-compatible API of OCI Object Storage)
AWS_ENDPOINT_URL_S3=     # https://<namespace>.compat.objectstorage.<region>.oraclecloud.com; namespace: `oci os ns get`
AWS_ACCESS_KEY_ID=       # Console → My profile → Customer secret keys → Generate (access key)
AWS_SECRET_ACCESS_KEY=   # same place; shown only once at creation

# OCI provider
TF_VAR_compartment_ocid= # Console → Identity → Compartments → Copy OCID (or tenancy OCID for root)
TF_VAR_fingerprint=      # Console → My profile → API keys (shown next to the key)
TF_VAR_private_key_path= # path only; the .pem file stays outside the repo
TF_VAR_ssh_source_cidr=  # your public IP + /32, e.g. `echo "$(curl -s ifconfig.me)/32"`
TF_VAR_tenancy_ocid=     # Console → My profile → Tenancy → Copy OCID (or ~/.oci/config)
TF_VAR_user_ocid=        # Console → My profile → Copy OCID (or ~/.oci/config)
```

The Customer Secret Key is **not** the API key used by the provider. The
AWS-style variable names are only there because the OpenTofu `s3` backend uses
the AWS SDK; no AWS account or AWS CLI is needed.

Non-secret values (region, CIDRs, name prefix, SSH public key path) live in
`environments/dev/dev.auto.tfvars` and are loaded automatically. Each variable
is set in either `.env` or the tfvars file, never both.

## Usage

```bash
./run_tofu.sh            # plan for dev
./run_tofu.sh apply      # apply for dev (OpenTofu asks for confirmation)
./run_tofu.sh plan prod  # plan for another env (needs environments/prod/, not created yet)
```

`run_tofu.sh` runs `tofu fmt`, `tofu init -reconfigure -backend-config=backend.hcl`,
`tofu validate`, then the requested action (`plan` by default).

Each environment must use its own backend `key` (e.g. `prod/terraform.tfstate`),
set in that environment's `backend.hcl`, otherwise environments overwrite each
other's state.

## Limitations

- Locking uses `use_lockfile` (conditional writes) on OCI's S3-compatible API,
  which is not an AWS-native guarantee. It was checked with two parallel `plan`
  runs, where the second one fails on the lock.
- The S3 backend needs several `skip_*` flags and `use_path_style` to work
  with OCI; see `environments/dev/backend.tf`.
- State is not encrypted yet; native OpenTofu state encryption is planned
  (Stage 1), since OCI's S3-compat layer has no AWS SSE-KMS. `sensitive`
  variables are hidden in the output only, their values are still in the state.
- The Always Free Ampere A1 allowance is 2 OCPUs and 12 GB in total, and
  capacity in a region can run out ("Out of capacity" on `apply`).

## Repos

| Repo | Contents |
| - | - |
| `oci-infra` | OpenTofu: network, cluster, buckets, IAM, ArgoCD bootstrap |
| `k8s-gitops` | manifests for ArgoCD: platform and apps, per environment |
| `demo-app` | app code, Dockerfile, tests, CI |

## Roadmap

### Stage 0: foundation

- [x] State backend in OCI Object Storage (S3) with lockfile locking
- [x] Verify locking: two parallel `plan` runs, the second must fail on the lock
- [x] `oci-infra` skeleton with the `dev` environment
- [x] End-to-end test of the backend and provider
- [x] README with usage

### Stage 1: network and cluster (`oci-infra`)

- [x] Modules: VCN, internet gateway, route table, security list, public subnet
- [x] Always Free Ampere A1 VM (2 OCPU, 12 GB)
- [ ] Compartment managed by OpenTofu instead of an existing OCID
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
