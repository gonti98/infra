resource "oci_core_vcn" "this" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.name_prefix}-vcn"
  cidr_blocks    = [var.vcn_cidr]
  dns_label      = replace(var.name_prefix, "-", "")
}

resource "oci_core_internet_gateway" "this" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.name_prefix}-igw"
  enabled        = true
}

resource "oci_core_route_table" "public" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.name_prefix}-public-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.this.id
  }
}

resource "oci_core_security_list" "public" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.name_prefix}-public-sl"

  # HTTPS (updates, packages, OCI APIs, etc.)
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "6" # TCP
    tcp_options {
      min = 443
      max = 443
    }
  }

  # HTTP (some package mirrors/repos)
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "6" # TCP
    tcp_options {
      min = 80
      max = 80
    }
  }

  # DNS
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "17" # UDP
    udp_options {
      min = 53
      max = 53
    }
  }

  # NTP (optional but common for correct time)
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "17" # UDP
    udp_options {
      min = 123
      max = 123
    }
  }

  # ICMP (path MTU, reachability, diagnostics)
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "1" # ICMP
  }

  ingress_security_rules {
    source   = var.ssh_source_cidr
    protocol = "6"
    tcp_options {
      min = 22
      max = 22
    }
  }
}

resource "oci_core_subnet" "public" {
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.this.id
  display_name      = "${var.name_prefix}-public-subnet"
  cidr_block        = var.public_subnet_cidr
  dns_label         = "public"
  route_table_id    = oci_core_route_table.public.id
  security_list_ids = [oci_core_security_list.public.id]
}
