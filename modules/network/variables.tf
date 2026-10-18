variable "compartment_ocid" {
  type        = string
  description = "OCID of the compartment where VCN and subnet resources are created."
  sensitive   = true
}

variable "name_prefix" {
  type        = string
  description = "Prefix used for naming network resources (lowercase alphanumeric, hyphens allowed)."
}

variable "vcn_cidr" {
  type        = string
  description = "CIDR block for the VCN."
}

variable "public_subnet_cidr" {
  type        = string
  description = "CIDR block for the public subnet (must be a subset of vcn_cidr)."
}

variable "ssh_source_cidr" {
  type        = string
  description = "CIDR block allowed for SSH ingress to the public subnet."
  sensitive   = true
}
