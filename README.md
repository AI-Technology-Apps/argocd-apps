# GitOps Starter for k3s (Terraform Edition)

## Requirements
- Terraform 1.5+
- Helm
- SOPS
- GPG Key (imported or generated)
- kubectl configured for your local k3s cluster

## Instructions

1. Generate or import a GPG key:
   ```bash
   gpg --full-generate-key
   gpg --list-keys
   ```

2. Export the private key:
   ```bash
   gpg --export-secret-keys --armor "<your-key-id>" > terraform/gpg-private.asc
   ```

3. Update `.sops.yaml` with your GPG fingerprint.

4. Navigate to the Terraform directory and initialize:
   ```bash
   cd terraform
   terraform init
   terraform apply
   ```

This will:
- Install Argo CD into `kube-system`
- Install External Secrets Operator
- Create SecretStore + ExternalSecret
- Register your GPG key into the cluster
- Apply ApplicationSet to detect your app automatically

## Directory Structure

- `apps/app1`: Your sample Helm app and secret
- `terraform/`: Manages the cluster setup via Terraform
- `clusters/production`: Argo CD ApplicationSet manifest

