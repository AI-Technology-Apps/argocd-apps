resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "kube-system"
  create_namespace = false
  version          = "8.0.5"

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

# Update the project to allow all repository URLs
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
      sourceRepos = ["*"] # Allow all repos including remote Helm repos
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


resource "kubernetes_manifest" "applicationset" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "ApplicationSet"
    metadata = {
      name      = "helm-charts"
      namespace = "kube-system"
    }
    spec = {
      generators = [
        {
          git = {
            repoURL  = local.repo_url
            revision = "HEAD"
            files = [
              {
                path = "apps/*/repo.yaml"
              }
            ]
          }
        }
      ]
      template = {
        metadata = {
          name = "{{name}}"      # from repo.yaml
        }
        spec = {
          project = "{{project}}"  # from repo.yaml, must exist in ArgoCD
          source = {
            repoURL        = local.repo_url    # from repo.yaml
            chart          = "{{chart}}"    # from repo.yaml
            targetRevision = "{{version}}"  # from repo.yaml
            path           = "{{path}}"     # from repo.yaml
            helm = {
              valueFiles = ["values.yaml"]
            }
          }
          destination = {
            server    = "https://kubernetes.default.svc"
            namespace = "{{namespace}}"   # from repo.yaml
          }
          syncPolicy = {
            automated = {
              prune    = true
              selfHeal = true
            }
            syncOptions = ["CreateNamespace=true"]
          }
        }
      }
    }
  }
}
