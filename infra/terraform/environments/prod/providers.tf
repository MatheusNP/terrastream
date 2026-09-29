provider "oci" {
  config_file_profile = "DEFAULT"
  region               = var.oci_region
}

provider "kubernetes" {
  config_path = "~/.kube/terrastream.yaml"
}

provider "helm" {
  kubernetes = {
    config_path = "~/.kube/terrastream.yaml"
  }
}