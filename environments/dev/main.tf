resource "oci_identity_compartment" "this" {
  name           = "${var.environment_prefix}-compartment"
  description    = "Compartment for ${var.environment_prefix}"
  compartment_id = var.tenancy_ocid
  enable_delete  = true
}

module "network" {
  source = "../../modules/network"

  compartment_ocid   = oci_identity_compartment.this.compartment_id
  name_prefix        = var.environment_prefix
  vcn_cidr           = var.vcn_cidr
  public_subnet_cidr = var.public_subnet_cidr
  ssh_source_cidr    = var.ssh_source_cidr
}

module "vm" {
  source = "../../modules/compute"

  compartment_ocid    = oci_identity_compartment.this.compartment_id
  tenancy_ocid        = var.tenancy_ocid
  name                = "${var.environment_prefix}-vm"
  subnet_id           = module.network.public_subnet_id
  ssh_public_key_path = var.ssh_public_key_path
}
