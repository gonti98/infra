# --- OCI provider ---

variable "tenancy_ocid" {
  type        = string
  description = "OCID of the OCI tenancy"
  sensitive   = true
}

variable "user_ocid" {
  type        = string
  description = "OCID of the OCI user that owns the API key"
  sensitive   = true
}

variable "fingerprint" {
  type        = string
  description = "Fingerprint of the OCI API public key"
  sensitive   = true
}

variable "private_key_path" {
  type        = string
  description = "Path to the OCI API private key (.pem), kept outside the repo"
}

variable "region" {
  type        = string
  description = "OCI region for the provider, e.g. eu-stockholm-1"
}

# --- Environment ---

variable "environment_prefix" {
  type        = string
  description = "Prefix for resource names, e.g. dev or prod (lowercase letters and digits, max 15 chars)"
}

variable "compartment_ocid" {
  type        = string
  description = "OCID of the compartment where resources are created"
  sensitive   = true
}

# --- Network ---

variable "vcn_cidr" {
  type        = string
  description = "CIDR block of the VCN, e.g. 10.0.0.0/16"
}

variable "public_subnet_cidr" {
  type        = string
  description = "CIDR block of the public subnet, must be inside vcn_cidr"
}

variable "ssh_source_cidr" {
  type        = string
  description = "CIDR allowed to reach SSH, e.g. your IP as 203.0.113.10/32"
  sensitive   = true
}

# --- Compute ---

variable "ssh_public_key_path" {
  type        = string
  description = "Path to the SSH public key added to the VM"
}
