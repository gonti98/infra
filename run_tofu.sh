#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")"

usage() {
  echo "Usage: $0 [plan|apply] [env]"
  echo "  action  plan | apply (default: plan)"
  echo "  env     environment name (default: dev)"
}

case "${1:-}" in
-h | --help | h | help)
  usage
  exit 0
  ;;
esac

ACTION="${1:-plan}"
TARGET_ENV="${2:-dev}"
ENV_DIR="environments/${TARGET_ENV}"
[[ -d "$ENV_DIR" ]] || {
  echo "unknown env: $TARGET_ENV" >&2
  exit 1
}

set -a
if [[ -f .env ]]; then
  # shellcheck source=/dev/null
  source .env
fi
set +a

case "$ACTION" in
plan | apply) ;;
*)
  usage >&2
  exit 1
  ;;
esac

tofu fmt -recursive -no-color

tofu -chdir="$ENV_DIR" init -reconfigure -backend-config=backend.hcl -input=false -no-color

tofu -chdir="$ENV_DIR" validate -no-color

tofu -chdir="$ENV_DIR" "$ACTION" -no-color
