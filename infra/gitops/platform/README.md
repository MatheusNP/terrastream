# infra/gitops/platform

Manifests/Helm values referenciados pelos `Application` de `infra/gitops/apps/`
(ex: values.yaml grandes, ConfigMaps, NetworkPolicies) — mantidos separados
dos `Application` em si para não misturar "o que instalar" com "como
configurar".