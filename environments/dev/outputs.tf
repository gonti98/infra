output "vm_public_ip" {
  value       = module.vm.public_ip
  description = "Public IP address of the dev VM."
}

output "vcn_id" {
  value       = module.network.vcn_id
  description = "OCID of the dev VCN."
}

output "subnet_id" {
  value       = module.network.public_subnet_id
  description = "OCID of the dev public subnet."
}
