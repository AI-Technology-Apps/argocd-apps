resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = "kube-system"
  create_namespace = false
  version    = "8.0.5"

  values = [
    <<-EOF
      global:
        domain: "argocd.kjones.org"
        nodeSelector:
          node-role.kubernetes.io/master: "true"
      server:
        extraArgs:
          - --insecure # disable TLS cert verification for local
        service:
          type: ClusterIP
        ingress:
          enabled: true
          ingressClassName: "traefik"
      configs:
        params:
          server.insecure: true
    EOF
  ]
}

resource "kubernetes_manifest" "applicationset" {
  depends_on = [ helm_release.argocd ]
  manifest = yamldecode(file("${path.module}/templates/applicationset.yaml"))
}
  