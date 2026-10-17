data "oci_objectstorage_namespace" "ns" {}

output "namespace" {
  value = data.oci_objectstorage_namespace.ns.namespace
}
