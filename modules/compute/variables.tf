variable "compartment_ocid" {
  type        = string
  description = "OCID of the compartment where the compute instance is created."
  sensitive   = true
}

variable "tenancy_ocid" {
  type        = string
  description = "OCID of the tenancy."
  sensitive   = true
}

variable "name" {
  type        = string
  description = "Display name for the compute instance."
}

variable "subnet_id" {
  type        = string
  description = "OCID of the subnet to attach the instance to."
}

variable "ssh_public_key_path" {
  type        = string
  description = "Path to the SSH public key to add to the instance (supports ~ expansion)."
}

variable "ocpus" {
  type        = number
  default     = 2
  description = "Number of OCPUs for VM.Standard.A1.Flex."
}

variable "memory_in_gbs" {
  type        = number
  default     = 12
  description = "Memory in GB for VM.Standard.A1.Flex."
}

variable "boot_volume_gbs" {
  type        = number
  default     = 50
  description = "Boot volume size in GB."
}

variable "availability_domain_index" {
  type        = number
  default     = 0
  description = "Index of the availability domain from the tenancy's AD list to use."
}
