variable "host" {
  type        = string
  description = "IP público (ou domínio) da VM onde o k3s será instalado"
}

variable "ssh_user" {
  type        = string
  description = "Usuário SSH da VM (Ubuntu na OCI = ubuntu)"
  default     = "ubuntu"
}

variable "ssh_private_key_path" {
  type        = string
  description = "Caminho da chave privada SSH usada para acessar a VM"
  default     = "~/.ssh/terrastream"
}

variable "k3s_version" {
  type        = string
  description = "Versão fixada do k3s, no formato do instalador (ex: v1.35.6+k3s1)"
}

variable "tls_sans" {
  type        = list(string)
  description = "Nomes/IPs extras no certificado da API do k3s (domínio DuckDNS e IP público)"
  default     = []
}
