variable "chart_version" {
  type        = string
  description = "Versão fixada do chart argo-cd (argo-helm). Confirmar a mais recente em https://github.com/argoproj/argo-helm/releases antes de aplicar (ex: 10.8.0)."
}

variable "repo_url" {
  type        = string
  description = "URL HTTPS do repositório Git que o ArgoCD vai observar (público, sem credencial)"
}

variable "target_revision" {
  type        = string
  description = "Branch/tag/commit observado pelo Application raiz"
  default     = "main"
}

variable "gitops_path" {
  type        = string
  description = "Pasta do repositório lida pelo Application raiz (app-of-apps)"
  default     = "infra/gitops/apps"
}

variable "namespace" {
  type        = string
  description = "Namespace onde o ArgoCD é instalado"
  default     = "argocd"
}
