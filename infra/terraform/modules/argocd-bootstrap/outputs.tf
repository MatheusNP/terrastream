output "namespace" {
  value = kubernetes_namespace.argocd.metadata[0].name
}

output "get_initial_admin_password_cmd" {
  description = "Comando para ler a senha inicial do usuário admin do ArgoCD (via tunnel SSH ativo)"
  value       = "kubectl -n ${kubernetes_namespace.argocd.metadata[0].name} get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo"
}

output "port_forward_cmd" {
  description = "Comando para acessar a UI do ArgoCD localmente (via tunnel SSH ativo)"
  value       = "kubectl -n ${kubernetes_namespace.argocd.metadata[0].name} port-forward svc/argocd-server 8080:80"
}
