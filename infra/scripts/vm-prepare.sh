#!/usr/bin/env bash
# =============================================================================
# TerraStream — preparo da VM (Ubuntu 24.04 aarch64, Oracle Always Free/PAYG)
#
# Consolida o que foi feito manualmente antes de instalar o k3s:
#   1. Diagnóstico da VM
#   2. Firewall interno (iptables): 80/443 e rede de pods do k3s
#   3. Persistência das regras (iptables-persistent)
#   4. (opcional) Atualização do DuckDNS
#
# Idempotente: pode rodar várias vezes sem duplicar regras.
# Uso (na VM):   sudo bash vm-prepare.sh
# DuckDNS:       sudo DUCKDNS_TOKEN=xxx DUCKDNS_DOMAIN=terrastream bash vm-prepare.sh
#
# NÃO mexe na chain InstanceServices (é da Oracle: metadata, iSCSI, DNS).
#
# A migrar para cloud-init/Terraform (módulo oci-vm ou k3s-bootstrap),
# para a VM ser reproduzível sem ajuste manual.
# =============================================================================
set -euo pipefail

POD_CIDR="10.42.0.0/16"   # rede de pods padrão do k3s (flannel)

if [[ $EUID -ne 0 ]]; then
  echo "Rode como root: sudo bash $0" >&2
  exit 1
fi

log() { printf '\n==> %s\n' "$*"; }

# -----------------------------------------------------------------------------
# 1. Diagnóstico
# -----------------------------------------------------------------------------
log "Diagnóstico da VM"
echo "arch:  $(uname -m)"
echo "vCPU:  $(nproc)"
free -h | sed -n '1,2p'
df -h / | sed -n '1,2p'
head -3 /etc/os-release

# -----------------------------------------------------------------------------
# 2. Firewall interno
#    A imagem da Oracle termina INPUT e FORWARD com REJECT; toda regra nossa
#    precisa entrar ANTES dele. O helper descobre a posição do REJECT e insere
#    ali, só se a regra ainda não existir (iptables -C).
# -----------------------------------------------------------------------------
reject_pos() {
  # $1 = chain. Imprime o nº da linha do REJECT final (vazio se não houver).
  iptables -L "$1" -n --line-numbers | awk '$2=="REJECT"{print $1; exit}'
}

ensure_rule() {
  # $1 = chain, demais = especificação da regra
  local chain="$1"; shift
  if iptables -C "$chain" "$@" 2>/dev/null; then
    echo "já existe:  $chain $*"
    return
  fi
  local pos
  pos="$(reject_pos "$chain")"
  if [[ -n "$pos" ]]; then
    iptables -I "$chain" "$pos" "$@"
  else
    iptables -A "$chain" "$@"
  fi
  echo "adicionada: $chain $*"
}

log "Firewall: 80/443 (ingress HTTP/HTTPS)"
ensure_rule INPUT -p tcp -m multiport --dports 80,443 -m state --state NEW -j ACCEPT

log "Firewall: rede de pods do k3s ($POD_CIDR)"
# INPUT: pod -> host. Sem isso o REJECT quebra comunicação pod->host.
ensure_rule INPUT   -s "$POD_CIDR" -j ACCEPT
# FORWARD: pod<->pod e pod<->internet. O REJECT do FORWARD derruba a rede dos
# pods se o firewall for restaurado depois do k3s subir.
ensure_rule FORWARD -s "$POD_CIDR" -j ACCEPT
ensure_rule FORWARD -d "$POD_CIDR" -j ACCEPT
# Obs.: 10.43.0.0/16 (services) NÃO precisa de regra: é IP virtual, o kube-proxy
# faz DNAT para o IP do pod e ele nunca aparece como origem de pacote.

# -----------------------------------------------------------------------------
# 3. Persistência
#    Salvar ANTES de instalar o k3s, para as chains KUBE-* do kube-proxy não
#    entrarem no arquivo persistido.
# -----------------------------------------------------------------------------
log "Persistência (iptables-persistent)"
if ! dpkg -s iptables-persistent >/dev/null 2>&1; then
  export DEBIAN_FRONTEND=noninteractive
  echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
  echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
  apt-get update -qq
  apt-get install -y iptables-persistent
fi
if command -v k3s >/dev/null 2>&1 && [[ "${FORCE_SAVE:-0}" != "1" ]]; then
  # Com o k3s instalado, o iptables contém chains KUBE-*/CNI-* geridas pelo
  # k3s. Salvá-las mistura regras nossas com as do kube-proxy no arquivo
  # persistido. Este script foi feito para rodar ANTES do k3s.
  echo "AVISO: k3s detectado, pulando 'netfilter-persistent save'."
  echo "       (use FORCE_SAVE=1 apenas se souber o que está fazendo)"
else
  netfilter-persistent save
fi

log "Estado final"
iptables -S INPUT
iptables -S FORWARD

# -----------------------------------------------------------------------------
# 4. DuckDNS (opcional)
#    Sem DUCKDNS_TOKEN/DUCKDNS_DOMAIN o passo é ignorado. Sem "ip=" o DuckDNS
#    usa o IP de origem da requisição, que na VM é o IP público dela.
# -----------------------------------------------------------------------------
if [[ -n "${DUCKDNS_TOKEN:-}" && -n "${DUCKDNS_DOMAIN:-}" ]]; then
  log "DuckDNS: atualizando ${DUCKDNS_DOMAIN}.duckdns.org"
  resp="$(curl -fsS "https://www.duckdns.org/update?domains=${DUCKDNS_DOMAIN}&token=${DUCKDNS_TOKEN}&ip=")"
  echo "resposta: $resp (esperado: OK)"
  getent hosts "${DUCKDNS_DOMAIN}.duckdns.org" || echo "DNS ainda não propagou; tente de novo em instantes."
else
  log "DuckDNS: ignorado (defina DUCKDNS_TOKEN e DUCKDNS_DOMAIN para atualizar)"
fi

log "Pronto. Próximo passo: security list da OCI e módulo k3s-bootstrap."