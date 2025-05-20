# GitOps Starter for k3s (Terraform Edition)

## Requirements
- Terraform 1.5+
- Helm
- kubeseal CLI
- kubectl configured for your local k3s cluster

## Instructions

1. Navigate to the Terraform directory and initialize:
   ```bash
   cd terraform
   terraform init
   terraform apply
   ```

This will:
- Install Argo CD into `kube-system`
- Install sealed-secrets-controller into `kube-system`
- Apply ApplicationSet to detect your apps automatically

2. Create a secret YAML file in your app directory (e.g., `apps/openwebui/secret.yaml`):
   ```yaml
   apiVersion: v1
   kind: Secret
   metadata:
     name: your-secret-name
     namespace: your-namespace
   data:
     username: YWRtaW4=  # base64 encoded values
     password: cGFzc3dvcmQ=
   ```

3. Seal the secret using kubeseal:
   ```bash
   kubeseal --controller-name=sealed-secrets-controller --controller-namespace=kube-system --format yaml < apps/openwebui/secret.yaml > apps/openwebui/sealedsecret.yaml
   ```

4. Commit only the sealed secret to git (the pre-commit hook will validate it's properly sealed):
   ```bash
   git add apps/openwebui/sealedsecret.yaml
   git commit -m "Add sealed secret for OpenWebUI"
   ```

## Using Helm Charts

This repository supports both local and remote Helm charts using two separate approaches:

### Simple Approach for Remote Charts Only

For a simpler setup dedicated to remote Helm charts:

1. Create a directory for your app in the remote apps directory (e.g., `apps/remote/myapp/`)  
2. Create a `repo.yaml` with your Helm chart details:
   ```yaml
   # Helm chart details
   url: "https://charts.bitnami.com/bitnami"
   chart: "nginx"
   version: "13.2.0"
   
   # ArgoCD application details
   namespace: "myapp"
   project: "default"  # Optional - defaults to "default"
   ```
3. Add your `values.yaml` with custom configuration
4. Create and seal your secrets as described above

### Advanced Approach (Supporting Both Local and Remote Charts)

1. Create a directory for your app (e.g., `apps/myapp/`)  
2. Create a `chart-config.yaml` with remote chart details:
   ```yaml
   # Chart configuration for remote chart
   remote: true
   repoURL: https://charts.bitnami.com/bitnami
   chart: nginx
   version: 13.2.0
   
   # ArgoCD application configuration
   repo:
     name: myapp
     namespace: myapp
     project: default
   ```
3. Add your `values.yaml` with custom configuration
4. Create and seal your secrets as described above

### For Local Helm Charts

1. Create a directory for your app (e.g., `apps/mylocalapp/`)
2. Include all required Helm chart files (Chart.yaml, templates/, etc.)
3. Create a `chart-config.yaml` (optional - for local charts):
   ```yaml
   # Chart configuration for local chart
   remote: false
   
   # ArgoCD application configuration  
   repo:
     name: mylocalapp
     namespace: mylocalapp-namespace
     project: default
   ```
4. Add your `values.yaml` and sealed secrets

## Directory Structure

- `apps/openwebui`: Sample app with configuration and sealed secrets
- `terraform/`: Manages the cluster setup via Terraform
- `scripts/`: Contains pre-commit hooks for sealed secrets validation
- `examples/`: Contains example configurations

