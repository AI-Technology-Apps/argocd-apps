apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: local-helm-charts
  namespace: kube-system
spec:
  generators:
  - git:
      repoURL: "${repo_url}"
      revision: HEAD
      directories:
      - path: "apps/local/*"
  template:
    metadata:
      name: '{{path.basename}}'
    spec:
      project: "ai-tools"
      source:
        # Local chart configuration - from Git repository
        repoURL: "${repo_url}"
        targetRevision: "HEAD"
        path: '{{path.path}}'
        helm:
          valueFiles:
          - values.yaml
      destination:
        server: "https://kubernetes.default.svc"
        namespace: '{{path.basename}}'
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
