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

# Direct manifest definitions for ApplicationSets
resource "kubernetes_manifest" "local_applicationset" {
  depends_on = [helm_release.argocd, kubernetes_manifest.argocd_project]
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "ApplicationSet"
    metadata = {
      name      = "local-helm-charts"
      namespace = "kube-system"
    }
    spec = {
      generators = [{
        git = {
          repoURL     = local.repo_url
          revision    = "HEAD"
          directories = [{
            path = "apps/local/*"
          }]
        }
      }]
      template = {
        metadata = {
          name = "{{path.basename}}"
        }
        spec = {
          project = "ai-tools"
          source = {
            repoURL         = local.repo_url
            targetRevision  = "HEAD"
            path            = "{{path.path}}"
            helm = {
              valueFiles = ["values.yaml"]
            }
          }
          destination = {
            server    = "https://kubernetes.default.svc"
            namespace = "{{path.basename}}"
          }
          syncPolicy = {
            automated = {
              prune     = true
              selfHeal  = true
            }
            syncOptions = ["CreateNamespace=true"]
          }
        }
      }
    }
  }
}

resource "kubernetes_manifest" "remote_applicationset" {
  depends_on = [helm_release.argocd, kubernetes_manifest.argocd_project]
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "ApplicationSet"
    metadata = {
      name      = "remote-helm-charts"
      namespace = "kube-system"
    }
    spec = {
      generators = [{
        git = {
          repoURL     = local.repo_url
          revision    = "HEAD"
          directories = [{
            path = "apps/remote/*/repo.yaml"
          }]
        }
      }]
      template = {
        metadata = {
          name = "{{path.basename}}"
        }
        spec = {
          project = "ai-tools"
          source = {
            repoURL        = "{{file.repo.url}}"
            chart          = "{{file.repo.chart}}"
            targetRevision = "{{file.repo.version}}"
            path           = "{{file.repo.path}}"
            helm = {
              valueFiles = ["values.yaml"]
            }
          }
          destination = {
            server    = "https://kubernetes.default.svc"
            namespace = "{{file.repo.namespace | default path.basename}}"
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
