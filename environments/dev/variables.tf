# --- Secrets via .env ---
variable "tenancy_ocid" {
  type        = string
  description = "OCID of the OCI tenancy"
  sensitive   = true
}

variable "ssh_source_cidr" {
  type        = string
  description = "CIDR allowed to reach SSH, e.g. your IP as 203.0.113.10/32"
  sensitive   = true
}

# --- Non secret values via dev.auto.tfvars ---

variable "environment_prefix" {
  type        = string
  description = "Prefix for resource names, e.g. dev or prod (lowercase letters and digits, max 15 chars)"
}

variable "vcn_cidr" {
  type        = string
  description = "CIDR block of the VCN, e.g. 10.0.0.0/16"
}

variable "public_subnet_cidr" {
  type        = string
  description = "CIDR block of the public subnet, must be inside vcn_cidr"
}

variable "ssh_public_key_path" {
  type        = string
  description = "Path to the SSH public key added to the VM"
}
