#!/usr/bin/env bash
# Roda na SUA MÁQUINA. Baixa o kubeconfig do k3s da VM e o salva localmente.
# A API (6443) não é exposta: o kubeconfig aponta para https://127.0.0.1:6443
# e você acessa via SSH tunnel (veja as instruções impressas no final).
#
# Uso: bash kubeconfig.sh <ip-ou-dominio>
set -euo pipefail

HOST="${1:?uso: $0 <ip-ou-dominio>}"
KEY="${SSH_KEY:-$HOME/.ssh/terrastream}"
SSH_USER="${SSH_USER:-ubuntu}"
OUT="${KUBECONFIG_OUT:-$HOME/.kube/terrastream.yaml}"

mkdir -p "$(dirname "$OUT")"
ssh -i "$KEY" "$SSH_USER@$HOST" 'cat /etc/rancher/k3s/k3s.yaml' \
  | sed 's/\bdefault\b/terrastream/g' > "$OUT"
chmod 600 "$OUT"

cat <<EOF

Kubeconfig salvo em: $OUT

1) Abra o tunnel (deixe rodando em OUTRO terminal):
   ssh -i $KEY -N -L 6443:127.0.0.1:6443 $SSH_USER@$HOST

2) Neste terminal:
   export KUBECONFIG=$OUT
   kubectl get nodes
EOF
