module "vm" {
  source = "../../modules/oci-vm"

  availability_domain_index = var.availability_domain_index
  compartment_id            = var.compartment_id
  ssh_allowed_cidr          = var.ssh_allowed_cidr
  region                    = var.oci_region
  ssh_public_key            = file(pathexpand("~/.ssh/terrastream.pub"))
}

output "vm_public_ip" {
  value = module.vm.public_ip
}