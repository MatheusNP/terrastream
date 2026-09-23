variable "compartment_id" {
  description = "OCID do compartment onde os recursos serão criados (a raiz da tenancy, se não houver compartments dedicados)"
  type        = string
}

variable "region" {
  description = "Região OCI"
  type        = string
  default     = "sa-saopaulo-1"
}

variable "vm_display_name" {
  description = "Nome de exibição da instância"
  type        = string
  default     = "terrastream-vm"
}

variable "ssh_public_key" {
  description = "Conteúdo da chave pública SSH (não o caminho do arquivo)"
  type        = string
}

variable "ssh_allowed_cidr" {
  type        = string
  description = "CIDR com acesso SSH (ex: 200.1.2.3/32)"
}

variable "ocpus" {
  description = "Número de OCPUs (Always Free: máximo 2)"
  type        = number
  default     = 2
}

variable "memory_in_gbs" {
  description = "RAM em GB (Always Free: máximo 12)"
  type        = number
  default     = 12
}

variable "boot_volume_size_in_gbs" {
  description = "Tamanho do boot volume (Always Free: até 200GB no total entre todos os volumes)"
  type        = number
  default     = 100
}

variable "availability_domain_index" {
  type    = number
  default = 0
}