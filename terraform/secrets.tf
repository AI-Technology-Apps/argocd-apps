resource "helm_release" "sealed_secrets" {
  name       = "sealed-secrets"
  namespace  = "kube-system"
  repository = "https://bitnami-labs.github.io/sealed-secrets"
  chart      = "sealed-secrets"
  version    = "2.17.2"

  values = [
    <<-EOF
      nodeSelector:
        node-role.kubernetes.io/master: "true"
      fullnameOverride: "sealed-secrets-controller"
      rbac:
        create: true
    EOF
  ]

  timeout = 300
  wait    = true
}