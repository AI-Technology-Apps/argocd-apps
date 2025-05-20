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
          node-role.kubernetes.io/control-plane: "true"
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


resource "kubernetes_manifest" "argocd_project" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "AppProject"
    metadata = {
      name      = "ai-tools"
      namespace = "kube-system"
    }
    spec = {
      description = "Project created via Terraform"
      sourceRepos = [local.repo_url]
      destinations = [{
        namespace = "*"
        server    = "*"
      }]
      clusterResourceWhitelist = [{
        group = "*"
        kind  = "*"
      }]
    }
  }
}


resource "kubernetes_manifest" "local_applicationset" {
  depends_on = [ helm_release.argocd, kubernetes_manifest.argocd_project ]
  manifest = yamldecode(templatefile("${path.module}/templates/local-applicationset.yaml.tpl", {
    repo_url = local.repo_url
  }))
}

resource "kubernetes_manifest" "remote_applicationset" {
  depends_on = [ helm_release.argocd, kubernetes_manifest.argocd_project ]
  manifest = yamldecode(templatefile("${path.module}/templates/remote-applicationset.yaml.tpl", {
    repo_url = local.repo_url
  }))
}
  