module "vm" {
  source = "../../modules/oci-vm"

  availability_domain_index = var.availability_domain_index
  compartment_id            = var.compartment_id
  ssh_allowed_cidr          = var.ssh_allowed_cidr
  region                    = var.oci_region
  ssh_public_key            = file(pathexpand("~/.ssh/terrastream.pub"))
}

module "k3s" {
  source = "../../modules/k3s-bootstrap"

  host                 = module.vm.public_ip
  ssh_private_key_path = "~/.ssh/terrastream"
  k3s_version          = "v1.35.6+k3s1"
  tls_sans             = ["terrastream.duckdns.org", module.vm.public_ip]
}

output "vm_public_ip" {
  value = module.vm.public_ip
}