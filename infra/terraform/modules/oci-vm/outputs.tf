output "public_ip" {
  description = "IP público reservado da VM — usado para atualizar o DuckDNS e conectar via SSH"
  value       = oci_core_public_ip.reserved.ip_address
}

output "instance_id" {
  value = oci_core_instance.vm.id
}