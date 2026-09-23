variable "oci_region" {
  type    = string
  default = "sa-saopaulo-1"
}

variable "compartment_id" {
  type = string
}

variable "availability_domain_index" {
  type    = number
  default = 0
}

variable "ssh_allowed_cidr" {
  type        = string
  description = "CIDR com acesso SSH (ex: 200.1.2.3/32)"
}