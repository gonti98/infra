output "public_ip" {
  value       = oci_core_instance.this.public_ip
  description = "Public IP address of the compute instance."
}

output "instance_id" {
  value       = oci_core_instance.this.id
  description = "OCID of the compute instance."
}

output "private_ip" {
  value       = oci_core_instance.this.private_ip
  description = "Private IP address of the compute instance."
}
