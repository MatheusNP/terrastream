terraform {
  required_version = ">= 1.12"
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.35"
    }
  }
}

# Requer um provider "kubernetes"/"helm" já configurado na raiz (environments/prod),
# apontando para o kubeconfig obtido via scripts/kubeconfig.sh do k3s-bootstrap.
# O apply deste módulo precisa do SSH tunnel (127.0.0.1:6443) aberto.

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.chart_version
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  # Cluster de 2 OCPU/12GB: reduz réplicas/recursos padrão do chart.
  # HA components (redis-ha, notifications HA) ficam desligados — não fazem
  # sentido em single-node e economizam RAM.
  values = [yamlencode({
    redis-ha = { enabled = false }
    controller = {
      replicas = 1
    }
    server = {
      replicas = 1
      # Sem TLS/ingress externo por enquanto: acesso via `kubectl port-forward`.
      # Quando Traefik+cert-manager estiverem no ar (via este mesmo ArgoCD),
      # um Application dedicado expõe o server com Ingress+TLS.
      extraArgs = ["--insecure"]
    }
    repoServer = {
      replicas = 1
    }
    applicationSet = {
      replicas = 1
    }
  })]
}

# App-of-apps: único recurso do ArgoCD gerenciado pelo Terraform. A partir
# daqui, tudo que entra no cluster (Traefik, cert-manager, NATS, Postgres,
# ESO, Prometheus...) é um Application dentro de infra/gitops/apps/*.yaml,
# versionado no Git — sem novo terraform apply.
resource "kubernetes_manifest" "root_app" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "root"
      namespace = kubernetes_namespace.argocd.metadata[0].name
      finalizers = [
        "resources-finalizer.argocd.argoproj.io",
      ]
    }
    spec = {
      project = "default"
      source = {
        repoURL        = var.repo_url
        targetRevision = var.target_revision
        path           = var.gitops_path
        directory = {
          recurse = true
        }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = kubernetes_namespace.argocd.metadata[0].name
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = [
          "CreateNamespace=true",
        ]
      }
    }
  }

  depends_on = [helm_release.argocd]
}
