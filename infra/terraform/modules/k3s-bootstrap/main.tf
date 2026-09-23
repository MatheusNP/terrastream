terraform {
  required_version = ">= 1.12"
}

# Configuração do k3s como arquivo (/etc/rancher/k3s/config.yaml), em vez de
# flags soltas no instalador: fica reproduzível e sobrevive a upgrades.
#  - disable traefik: Traefik será instalado via ArgoCD (infra/gitops/platform)
#  - servicelb NÃO é desabilitado: em single-node faz o bind de 80/443 no host
#  - tls-san: nomes/IPs válidos no certificado da API (acesso por SSH tunnel)
#  - kubeconfig 0644: legível por qualquer usuário DENTRO da VM (single-user);
#    a porta 6443 não é exposta na security list
locals {
  k3s_config = yamlencode({
    "disable"               = ["traefik"]
    "tls-san"               = var.tls_sans
    "write-kubeconfig-mode" = "0644"
  })
}

resource "terraform_data" "k3s" {
  # Mudou a versão ou a config -> o recurso é recriado e o script roda de novo.
  # O script é idempotente: só reinstala/reinicia se algo realmente mudou.
  triggers_replace = {
    host    = var.host
    version = var.k3s_version
    config  = local.k3s_config
  }

  connection {
    type        = "ssh"
    host        = var.host
    user        = var.ssh_user
    private_key = file(pathexpand(var.ssh_private_key_path))
    timeout     = "3m"
  }

  provisioner "file" {
    content = templatefile("${path.module}/scripts/install-k3s.sh.tftpl", {
      k3s_version = var.k3s_version
      config      = local.k3s_config
    })
    destination = "/tmp/install-k3s.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo bash /tmp/install-k3s.sh",
      "rm -f /tmp/install-k3s.sh",
    ]
  }
}
