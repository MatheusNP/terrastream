# infra/gitops/apps

Cada arquivo `.yaml` aqui é um recurso `Application` do ArgoCD, lido pelo
Application raiz (`root`, criado pelo módulo Terraform `argocd-bootstrap`).

Adicionar um novo componente de plataforma (Traefik, cert-manager, NATS,
Postgres, ESO, Prometheus/Grafana) = criar um novo arquivo aqui e dar commit.
Não requer `terraform apply`.

Convenção de nome: `NN-nome.yaml`, número só para ordenar visualmente no
diretório (o ArgoCD não depende de ordem — dependências reais entre
componentes usam `sync-wave` na annotation `argocd.argoproj.io/sync-wave`).

## Exemplo (Traefik via chart oficial)

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: traefik
  namespace: argocd
  annotations:
    argocd.argoproj.io/sync-wave: "0"
spec:
  project: default
  source:
    repoURL: https://traefik.github.io/charts
    chart: traefik
    targetRevision: "33.x.x"   # fixar versão antes de usar
    helm:
      values: |
        # values do Traefik aqui
  destination:
    server: https://kubernetes.default.svc
    namespace: traefik
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```