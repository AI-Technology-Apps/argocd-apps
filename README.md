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

## Directory Structure

- `apps/openwebui`: Sample app with configuration and sealed secrets
- `terraform/`: Manages the cluster setup via Terraform
- `scripts/`: Contains pre-commit hooks for sealed secrets validation

