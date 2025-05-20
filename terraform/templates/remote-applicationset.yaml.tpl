apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: remote-helm-charts
  namespace: kube-system
spec:
  generators:
  - git:
      repoURL: "${repo_url}"
      revision: HEAD
      directories:
      - path: "apps/remote/*"
  template:
    metadata:
      name: '{{path.basename}}'
    spec:
      # Default to 'default' project unless specified in repo.yaml
      project: "ai-tools"
      source:
        # Remote Helm repository configuration
        repoURL: '{{file.repo.url}}'
        chart: '{{file.repo.chart}}' 
        targetRevision: '{{file.repo.version}}'
        path: '{{file.repo.path}}'
        helm:
          valueFiles:
          - values.yaml
      destination:
        server: "https://kubernetes.default.svc"
        # Default to app name as namespace unless specified in repo.yaml
        namespace: '{{file.repo.namespace | default path.basename}}'
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
