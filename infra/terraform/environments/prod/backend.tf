terraform {
  backend "oci" {
    bucket              = "terrastream-tfstate"
    namespace           = "grjd1hp8gh2i"
    region              = "sa-saopaulo-1"
    key                 = "prod/terraform.tfstate"
    config_file_profile = "DEFAULT"
  }
}
