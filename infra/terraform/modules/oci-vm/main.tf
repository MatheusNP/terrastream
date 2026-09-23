# Busca a(s) availability domain(s) disponíveis na região — evita hardcoded,
# funciona tanto em regiões de AD única (Vinhedo) quanto múltipla (São Paulo)
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_id
}

# Busca a imagem mais recente do Ubuntu para ARM (compatível com Ampere A1)
data "oci_core_images" "ubuntu_arm" {
  compartment_id           = var.compartment_id
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "24.04"
  shape                    = "VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# --- Rede ---

resource "oci_core_vcn" "main" {
  compartment_id = var.compartment_id
  display_name   = "terrastream-vcn"
  cidr_blocks    = ["10.0.0.0/16"]
  dns_label      = "terrastream"
}

resource "oci_core_internet_gateway" "main" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "terrastream-igw"
  enabled        = true
}

resource "oci_core_route_table" "main" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "terrastream-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.main.id
  }
}

# Regras de entrada: SSH (22), HTTP (80), HTTPS (443)
resource "oci_core_security_list" "main" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "terrastream-sl"

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  ingress_security_rules {
    source   = var.ssh_allowed_cidr
    protocol = "6" # TCP
    tcp_options {
      min = 22
      max = 22
    }
  }

  ingress_security_rules {
    source   = "0.0.0.0/0"
    protocol = "6"
    tcp_options {
      min = 80
      max = 80
    }
  }

  ingress_security_rules {
    source   = "0.0.0.0/0"
    protocol = "6"
    tcp_options {
      min = 443
      max = 443
    }
  }
}

resource "oci_core_subnet" "main" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.main.id
  display_name               = "terrastream-subnet"
  cidr_block                 = "10.0.1.0/24"
  route_table_id             = oci_core_route_table.main.id
  security_list_ids          = [oci_core_security_list.main.id]
  dns_label                  = "main"
  prohibit_public_ip_on_vnic = false
}

# --- Instância ---

resource "oci_core_instance" "vm" {
  compartment_id      = var.compartment_id
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[var.availability_domain_index].name
  display_name        = var.vm_display_name
  shape               = "VM.Standard.A1.Flex"

  shape_config {
    ocpus         = var.ocpus
    memory_in_gbs = var.memory_in_gbs
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.main.id
    assign_public_ip = false
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.ubuntu_arm.images[0].id
    boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
  }
}

# --- IP público reservado (sobrevive à recriação da instância) ---

data "oci_core_vnic_attachments" "vm" {
  compartment_id = var.compartment_id
  instance_id    = oci_core_instance.vm.id
}

data "oci_core_private_ips" "vm" {
  vnic_id = data.oci_core_vnic_attachments.vm.vnic_attachments[0].vnic_id
}

resource "oci_core_public_ip" "reserved" {
  compartment_id = var.compartment_id
  display_name   = "terrastream-ip"
  lifetime       = "RESERVED"
  private_ip_id  = data.oci_core_private_ips.vm.private_ips[0].id
}