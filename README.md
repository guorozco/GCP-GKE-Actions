#  Complete Deployment Guide - GKE + Artifact Registry

This guide covers deploying both GKE clusters and Artifact Registry using Terragrunt.

##  Prerequisites

1. **Google Cloud SDK** installed and configured
2. **Terraform** >= 1.0 installed
3. **Terragrunt** installed
4. **Docker** installed (for container operations)
5. **GCP Project** with billing enabled

##  Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Free Tier GKE + Registry                 │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────┐    ┌──────────────────────────────────┐ │
│  │   Staging       │    │        Production                │ │
│  │   us-central1   │    │        us-east1                  │ │
│  │                 │    │                                  │ │
│  │ ┌─────────────┐ │    │ ┌─────────────┐                  │ │
│  │ │GKE Autopilot│ │    │ │GKE Standard │                  │ │
│  │ │e2-micro     │ │    │ │e2-small     │                  │ │
│  │ │Spot Nodes   │ │    │ │Spot Nodes   │                  │ │
│  │ └─────────────┘ │    │ └─────────────┘                  │ │
│  │       ↓         │    │       ↓                          │ │
│  │ ┌─────────────┐ │    │ ┌─────────────┐                  │ │
│  │ │ Artifact    │ │    │ │ Artifact    │                  │ │
│  │ │ Registry    │ │    │ │ Registry    │                  │ │
│  │ │ (staging)   │ │    │ │ (prod)      │                  │ │
│  │ └─────────────┘ │    │ └─────────────┘                  │ │
│  └─────────────────┘    └──────────────────────────────────┘ │
│                                                             │
│           ┌─────────────────────────────────────┐           │
│           │         Shared Registry             │           │
│           │         us-central1                 │           │
│           │    (Base images, shared libs)       │           │
│           └─────────────────────────────────────┘           │
└─────────────────────────────────────────────────────────────┘
```

##  Complete Deployment

### Step 1: Initial Setup

```bash
# Clone and navigate to project
cd GCP-GKE-Actions

# Set project ID
export TF_VAR_project_id="your-project-id"

# Run setup script
./scripts/setup.sh
```

### Step 2: Deploy Infrastructure

```bash
# Navigate to infrastructure directory
cd infra

# Option A: Deploy everything for staging
make deploy-staging              # GKE cluster
make deploy-registry-staging     # Artifact Registry

# Option B: Deploy everything for production  
make deploy-production           # GKE cluster
make deploy-registry-production  # Artifact Registry

# Option C: Deploy shared registry
make deploy-registry-shared      # Shared Artifact Registry
```

### Step 3: Configure Docker

```bash
# Configure Docker for all registries
make configure-docker-all

# Or configure individually
make configure-docker-staging
make configure-docker-production
```

### Step 4: Verify Deployment

```bash
# Check cluster status
make status-staging
make status-production

# Check registries
make list-registries

# Get cluster credentials
make kubeconfig-staging
make kubeconfig-production
```

##  Environment-Specific Deployments

### Staging Environment

```bash
# Deploy staging infrastructure
cd infra/environments/staging
terragrunt init
terragrunt apply

# Deploy staging registry
cd artifact-registry
terragrunt init
terragrunt apply

# Connect to staging
gcloud container clusters get-credentials gke-staging \
  --region=us-central1 --project=$TF_VAR_project_id
```

### Production Environment

```bash
# Deploy production infrastructure
cd infra/environments/production
terragrunt init
terragrunt apply

# Deploy production registry
cd artifact-registry
terragrunt init
terragrunt apply

# Connect to production
gcloud container clusters get-credentials gke-production \
  --region=us-east1 --project=$TF_VAR_project_id
```

##  Container Workflow

### 1. Build and Push Images

```bash
# Build your application
docker build -t my-app:latest .

# Tag for staging
docker tag my-app:latest \
  us-central1-docker.pkg.dev/$TF_VAR_project_id/staging-docker/my-app:v1.0

# Push to staging registry
docker push \
  us-central1-docker.pkg.dev/$TF_VAR_project_id/staging-docker/my-app:v1.0
```

### 2. Deploy to Kubernetes

```bash
# Connect to staging cluster
make kubeconfig-staging

# Create deployment
kubectl create deployment my-app \
  --image=us-central1-docker.pkg.dev/$TF_VAR_project_id/staging-docker/my-app:v1.0

# Expose service
kubectl expose deployment my-app --port=80 --type=LoadBalancer

# Check status
kubectl get pods
kubectl get services
```

### 3. Promote to Production

```bash
# Pull from staging
docker pull us-central1-docker.pkg.dev/$TF_VAR_project_id/staging-docker/my-app:v1.0

# Tag for production
docker tag \
  us-central1-docker.pkg.dev/$TF_VAR_project_id/staging-docker/my-app:v1.0 \
  us-east1-docker.pkg.dev/$TF_VAR_project_id/production-docker/my-app:v1.0

# Push to production registry
docker push \
  us-east1-docker.pkg.dev/$TF_VAR_project_id/production-docker/my-app:v1.0

# Deploy to production cluster
make kubeconfig-production
kubectl create deployment my-app \
  --image=us-east1-docker.pkg.dev/$TF_VAR_project_id/production-docker/my-app:v1.0
```

##  Monitoring and Management

### Check Resource Usage

```bash
# Cluster resource usage
make monitor

# Registry storage usage
gcloud artifacts repositories list --project=$TF_VAR_project_id

# Cost monitoring
make cost-estimate
```

### View Images and Deployments

```bash
# List all images
make list-images

# Check running pods
kubectl get pods --all-namespaces

# View services
kubectl get services --all-namespaces
```

##  Security Configuration

### Service Account Setup

```bash
# The deployment automatically creates service accounts:
# - gke-staging-gke-sa@PROJECT_ID.iam.gserviceaccount.com
# - gke-production-gke-sa@PROJECT_ID.iam.gserviceaccount.com
# - staging-docker-ar-sa@PROJECT_ID.iam.gserviceaccount.com
# - production-docker-ar-sa@PROJECT_ID.iam.gserviceaccount.com

# Check service accounts
gcloud iam service-accounts list --project=$TF_VAR_project_id
```

### IAM Permissions

```bash
# Check your permissions
gcloud projects get-iam-policy $TF_VAR_project_id \
  --flatten="bindings[].members" \
  --filter="bindings.members:$(gcloud config get-value account)"
```

##  Cost Optimization

### Free Tier Optimizations

- **GKE Autopilot** in staging (most cost-effective)
- **Spot instances** for significant savings
- **e2-micro/e2-small** instances (free tier eligible)
- **Automatic cleanup policies** for old images
- **Regional deployment** in free tier regions

### Cost Monitoring

```bash
# Set up billing alerts
make billing-alerts

# Monitor current costs
gcloud billing budgets list

# Check resource usage
make monitor
```

##  Cleanup and Maintenance

### Clean Up Test Resources

```bash
# Remove test deployments
kubectl delete deployment my-app
kubectl delete service my-app

# Clean up old images
gcloud artifacts docker images list \
  us-central1-docker.pkg.dev/$TF_VAR_project_id/staging-docker \
  --filter="createTime<'2024-01-01'" \
  --format="value(name)" | \
  xargs -I {} gcloud artifacts docker images delete {} --quiet
```

### Destroy Infrastructure

```bash
# Destroy staging
make destroy-staging
cd environments/staging/artifact-registry && terragrunt destroy

# Destroy production
make destroy-production
cd environments/production/artifact-registry && terragrunt destroy

# Clean up shared registry
cd environments/common/artifact-registry && terragrunt destroy
```

## Troubleshooting

### Common Issues

1. **Authentication Errors**:
   ```bash
   gcloud auth login
   gcloud auth application-default login
   make configure-docker-all
   ```

2. **Permission Denied**:
   ```bash
   # Check IAM roles
   gcloud projects get-iam-policy $TF_VAR_project_id
   ```

3. **Registry Not Found**:
   ```bash
   # Verify deployment
   make list-registries
   ```

4. **Pod ImagePullBackOff**:
   ```bash
   # Check image exists
   gcloud artifacts docker images list \
     us-central1-docker.pkg.dev/$TF_VAR_project_id/staging-docker
   
   # Check GKE permissions
   kubectl describe pod POD_NAME
   ```

### Health Checks

```bash
# Complete health check
./scripts/health-check.sh

# Or manual checks
make status
make list-registries
kubectl cluster-info
kubectl get nodes
```

##  Next Steps

1. **Set up CI/CD** pipelines for automated deployments
2. **Configure monitoring** and alerting
3. **Implement backup** strategies
4. **Set up staging/production** promotion workflows
5. **Add custom applications** to your clusters

##  Additional Resources

- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [Artifact Registry Documentation](https://cloud.google.com/artifact-registry/docs)
- [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Terragrunt Documentation](https://terragrunt.gruntwork.io/)

---

**You now have a complete, production-ready GKE + Artifact Registry setup! **

*Cost-optimized, secure, and ready for your applications!*


## ⚡ 5-Minute Setup

### 1. Prerequisites Check
```bash
# Check if you have the required tools
gcloud --version
terraform --version
terragrunt --version
```

If any are missing, install them:
```bash
# macOS with Homebrew
brew install google-cloud-sdk terraform terragrunt

# Or follow platform-specific instructions in DEPLOYMENT.md
```

### 2. GCP Setup
```bash
# Login to GCP
gcloud auth login

# Set your project (replace with your project ID)
export TF_VAR_project_id="your-actual-project-id"
gcloud config set project $TF_VAR_project_id

# Enable required APIs
gcloud services enable container.googleapis.com compute.googleapis.com
```

### 3. Create State Buckets
```bash
# Create GCS buckets for Terraform state
gsutil mb gs://${TF_VAR_project_id}-tfstate-staging
gsutil mb gs://${TF_VAR_project_id}-tfstate-production

# Enable versioning
gsutil versioning set on gs://${TF_VAR_project_id}-tfstate-staging
gsutil versioning set on gs://${TF_VAR_project_id}-tfstate-production
```

### 4. Deploy Staging (Free Tier)
```bash
# Navigate to project
cd GCP-GKE-Actions/infra/environments/staging

# Initialize and deploy
terragrunt init
terragrunt plan
terragrunt apply
```

### 5. Connect to Your Cluster
```bash
# Get cluster credentials
gcloud container clusters get-credentials gke-staging \
  --region=us-central1 \
  --project=$TF_VAR_project_id

# Verify connection
kubectl cluster-info
kubectl get nodes
```

##  What You Get

- **GKE Autopilot cluster** (most cost-effective)
- **Free tier optimized** (e2-micro instances)
- **Preemptible nodes** for cost savings
- **Private cluster** with security best practices
- **Workload Identity** for secure GCP access

##  Cost Estimate

- **Staging**: ~$0-10/month (with free tier credits)
- Uses GKE Autopilot for optimal cost management

##  Optional: Production Deployment

```bash
# Navigate to production
cd ../production

# Deploy production cluster
terragrunt init
terragrunt plan
terragrunt apply

# Connect to production
gcloud container clusters get-credentials gke-production \
  --region=us-east1 \
  --project=$TF_VAR_project_id
```

##  Cleanup

When you're done testing:
```bash
# Destroy staging
cd infra/environments/staging
terragrunt destroy

# Destroy production (if created)
cd ../production
terragrunt destroy
```

## 🆘 Troubleshooting

### Common Issues

1. **"Duplicate required providers"**
   - Fixed in this version 

2. **"Project not found"**
   ```bash
   # Verify project ID
   gcloud projects list
   export TF_VAR_project_id="correct-project-id"
   ```

3. **"Permission denied"**
   ```bash
   # Re-authenticate
   gcloud auth login
   gcloud auth application-default login
   ```

4. **"Bucket already exists"**
   - Normal if bucket exists, just continue



#  GKE Infrastructure Deployment Guide - Free Tier Optimized

This guide will help you deploy a cost-optimized GKE cluster using Terraform and Terragrunt on Google Cloud Platform's free tier.

##  Free Tier Optimizations

This infrastructure is specifically optimized for GCP's Always Free tier:

- **GKE Autopilot mode** for staging (most cost-effective)
- **e2-micro and e2-small instances** (free tier eligible)
- **Preemptible nodes** for significant cost savings
- **Minimal disk sizes** (32GB instead of 100GB)
- **Reduced resource limits** and scaling constraints
- **Free tier eligible regions**

##  Cost Estimates

- **Staging (Autopilot)**: ~$0-10/month
- **Production (Standard)**: ~$15-30/month

> **Note**: These estimates assume minimal usage. Monitor your billing closely and adjust resources as needed.

##  Prerequisites

### 1. Required Tools

```bash
# Install Google Cloud SDK
curl https://sdk.cloud.google.com | bash
exec -l $SHELL

# Install Terraform
brew install terraform  # macOS
# or download from https://terraform.io/downloads

# Install Terragrunt
brew install terragrunt  # macOS
# or download from https://terragrunt.gruntwork.io/docs/getting-started/install/
```

### 2. GCP Setup

1. **Create a GCP Project** (if you don't have one):
   ```bash
   gcloud projects create YOUR-PROJECT-ID --name="GKE Free Tier"
   ```

2. **Enable billing** for your project (required even for free tier)

3. **Set up authentication**:
   ```bash
   gcloud auth login
   gcloud config set project YOUR-PROJECT-ID
   ```

##  Quick Start

### Step 1: Clone and Setup

```bash
# Clone the repository
git clone <your-repo-url>
cd GCP-GKE-Actions

# Make setup script executable and run it
chmod +x scripts/setup.sh
./scripts/setup.sh
```

The setup script will:
-  Check prerequisites
-  Enable required GCP APIs
-  Create GCS buckets for Terraform state
-  Optionally create a service account
-  Generate environment configuration

### Step 2: Configure Environment

```bash
# Set your GCP project ID (replace with your actual project ID)
export TF_VAR_project_id="your-actual-project-id"

# Verify your project ID is set
echo $TF_VAR_project_id

# Optional: Source additional environment variables if you created .env.local
# source .env.local
```

**Important**: Replace `"your-actual-project-id"` with your actual GCP project ID.

### Step 3: Deploy Staging Environment

```bash
# Navigate to staging environment
cd infra/environments/staging

# Initialize Terragrunt
terragrunt init

# Review the deployment plan
terragrunt plan

# Deploy the infrastructure
terragrunt apply
```

### Step 4: Deploy Production Environment

```bash
# Navigate to production environment
cd ../production

# Initialize Terragrunt
terragrunt init

# Review the deployment plan
terragrunt plan

# Deploy the infrastructure
terragrunt apply
```

##  Advanced Setup

### Using Makefile Commands

This project includes a comprehensive Makefile for easier management:

```bash
# Navigate to the infra directory
cd infra

# View all available commands
make help

# Initialize staging
make init-staging

# Plan staging deployment
make plan-staging

# Apply staging changes
make apply-staging

# Get staging cluster credentials
make kubeconfig-staging

# Check cluster status
make status-staging
```

### Environment Variables

Create a `.env.local` file in the project root:

```bash
# Required
export TF_VAR_project_id="your-gcp-project-id"

# Optional - if using service account key
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account-key.json"

# Terraform settings
export TF_LOG=INFO
export TF_LOG_PATH=./terraform.log
```

## 🎛 Configuration Options

### Staging Environment (Autopilot)

The staging environment uses **GKE Autopilot** for maximum cost optimization:

```hcl
# infra/environments/staging/terragrunt.hcl
inputs = {
  environment       = "staging"
  cluster_name      = "gke-staging"
  region            = "us-central1-a"      # Free tier region
  enable_autopilot  = true                # Cost-optimized
  enable_preemptible = true               # Spot instances
  node_type         = "e2-micro"          # Free tier
  node_count        = 1
  max_node_count    = 3
  disk_size_gb      = 32
}
```

### Production Environment (Standard)

The production environment uses **Standard GKE** for more control:

```hcl
# infra/environments/production/terragrunt.hcl
inputs = {
  environment       = "production"
  cluster_name      = "gke-production"
  region            = "us-east1-b"         # Free tier region
  enable_autopilot  = false               # Standard mode
  enable_preemptible = true               # Cost savings
  node_type         = "e2-small"          # Slightly larger
  node_count        = 1
  max_node_count    = 3
  disk_size_gb      = 32
}
```

##  Authentication & Access

### Connect to Your Clusters

```bash
# Get staging cluster credentials
gcloud container clusters get-credentials gke-staging \
  --region=us-central1-a \
  --project=YOUR-PROJECT-ID

# Get production cluster credentials  
gcloud container clusters get-credentials gke-production \
  --region=us-east1-b \
  --project=YOUR-PROJECT-ID

# Verify connection
kubectl get nodes
kubectl get pods --all-namespaces
```

### Service Account Setup

For CI/CD or automated deployments, create a dedicated service account:

```bash
# Create service account
gcloud iam service-accounts create terraform-gke \
  --display-name="Terraform GKE" \
  --description="Service account for Terraform GKE operations"

# Assign required roles
gcloud projects add-iam-policy-binding YOUR-PROJECT-ID \
  --member="serviceAccount:terraform-gke@YOUR-PROJECT-ID.iam.gserviceaccount.com" \
  --role="roles/container.admin"

gcloud projects add-iam-policy-binding YOUR-PROJECT-ID \
  --member="serviceAccount:terraform-gke@YOUR-PROJECT-ID.iam.gserviceaccount.com" \
  --role="roles/compute.admin"

# Create and download key
gcloud iam service-accounts keys create terraform-sa-key.json \
  --iam-account="terraform-gke@YOUR-PROJECT-ID.iam.gserviceaccount.com"
```

##  Monitoring Costs

### Set Up Billing Alerts

1. Go to [GCP Billing](https://console.cloud.google.com/billing)
2. Select your billing account
3. Click "Budgets & alerts"
4. Create budget alerts for:
   - $5/month (warning at 80%)
   - $10/month (critical at 90%)

### Monitor Resource Usage

```bash
# Check cluster costs
gcloud billing budgets list

# Monitor node usage
kubectl top nodes
kubectl top pods --all-namespaces

# Check cluster info
kubectl cluster-info
kubectl get nodes -o wide
```

### Free Tier Limits

Keep in mind these GCP free tier limits:
- **Compute Engine**: 1 f1-micro instance per month
- **Cloud Storage**: 5GB per month
- **Networking**: 1GB North America to all region destinations per month

##  Customization

### Switch Between Autopilot and Standard

To change from Autopilot to Standard mode:

1. Edit `infra/environments/staging/terragrunt.hcl`:
   ```hcl
   enable_autopilot = false  # Change to false
   ```

2. Apply changes:
   ```bash
   cd infra/environments/staging
   terragrunt apply
   ```

### Adjust Node Sizes

For slightly more resources (still free tier eligible):

```hcl
inputs = {
  node_type = "e2-small"      # Instead of e2-micro
  node_count = 2              # Instead of 1
  max_node_count = 5          # Instead of 3
  disk_size_gb = 64           # Instead of 32
}
```

### Enable Additional Features

```hcl
inputs = {
  # Enable network policies (adds cost)
  enable_network_policy = true
  
  # Enable workload identity
  enable_workload_identity = true
  
  # Enable private cluster
  enable_private_cluster = true
}
```

##  Cleanup

### Destroy Resources

To avoid ongoing charges, destroy resources when not needed:

```bash
# Destroy staging environment
cd infra/environments/staging
terragrunt destroy

# Destroy production environment
cd ../production
terragrunt destroy

# Or use Makefile
make destroy-staging
make destroy-production
```

### Clean Up State Files

```bash
# Remove local state and cache
make clean

# Delete GCS buckets (optional)
gsutil rm -r gs://YOUR-PROJECT-ID-tfstate-staging
gsutil rm -r gs://YOUR-PROJECT-ID-tfstate-production
```

##  Troubleshooting

### Common Issues

1. **API not enabled**:
   ```bash
   gcloud services enable container.googleapis.com
   gcloud services enable compute.googleapis.com
   ```

2. **Insufficient permissions**:
   ```bash
   gcloud auth application-default login
   gcloud config set project YOUR-PROJECT-ID
   ```

3. **Quota exceeded**:
   - Check your quotas in GCP Console
   - Request quota increases if needed
   - Reduce node counts/sizes

4. **State file locked**:
   ```bash
   terragrunt force-unlock LOCK-ID
   ```

### Useful Commands

```bash
# Check Terraform state
terragrunt state list
terragrunt state show google_container_cluster.gke_autopilot_cluster

# Import existing resources
terragrunt import google_container_cluster.gke_cluster projects/PROJECT/locations/REGION/clusters/CLUSTER

# Refresh state
terragrunt refresh

# Validate configuration
terragrunt validate
```

##  Additional Resources

- [GCP Free Tier Documentation](https://cloud.google.com/free)
- [GKE Autopilot Pricing](https://cloud.google.com/kubernetes-engine/pricing#autopilot_mode)
- [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Terragrunt Documentation](https://terragrunt.gruntwork.io/)

##  Next Steps

After deployment:

1. **Deploy a sample application**
2. **Set up monitoring and logging**
3. **Configure CI/CD pipelines**
4. **Implement security best practices**
5. **Set up backup strategies**

---

**Happy deploying! **

*Remember to monitor your costs and adjust resources based on your actual usage patterns.*


#  Security Guidelines

This document outlines security best practices for this GKE infrastructure project.

##  Never Commit These Files

The following files contain sensitive information and should **NEVER** be committed to Git:

### 🔑 Credentials & Keys
- `*.json` - Service account keys
- `*-sa-key.json` - Terraform service account keys  
- `.env*` - Environment files with secrets
- `kubeconfig*` - Kubernetes configuration files
- `*.pem`, `*.key` - SSH keys and certificates

###  Terraform State
- `*.tfstate*` - Contains resource IDs and sensitive data
- `terraform.tfvars` - May contain sensitive variable values
- `.terraform/` - Local terraform cache

###  Logs
- `*.log` - May contain sensitive output
- `terraform.log`, `terragrunt.log` - Deployment logs

##  Safe to Commit

These files are safe to commit:
- `*.tf` - Terraform configuration (without hardcoded secrets)
- `*.hcl` - Terragrunt configuration
- `*.md` - Documentation
- `Makefile` - Build scripts
- `.gitignore` - This file itself

##  Security Best Practices

### 1. Use Environment Variables
```bash
# Instead of hardcoding in files:
export TF_VAR_project_id="your-project-id"
export GOOGLE_APPLICATION_CREDENTIALS="./sa-key.json"
```

### 2. Use GCP Secret Manager
Store sensitive configuration in GCP Secret Manager:
```bash
# Store secrets
gcloud secrets create db-password --data-file=password.txt

# Access in Terraform
data "google_secret_manager_secret_version" "db_password" {
  secret = "db-password"
}
```

### 3. Use Workload Identity
Instead of service account keys, use Workload Identity for pods:
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: workload-sa
  annotations:
    iam.gke.io/gcp-service-account: gsa-name@project.iam.gserviceaccount.com
```

### 4. Rotate Credentials Regularly
- Service account keys: Every 90 days
- Database passwords: Every 60 days
- API keys: Every 30 days

### 5. Use Least Privilege Access
Grant minimum required permissions:
```bash
# Instead of roles/owner, use specific roles:
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:SA_EMAIL" \
  --role="roles/container.developer"
```

##  Monitoring Security

### 1. Enable Audit Logging
```yaml
auditConfigs:
- service: allServices
  auditLogConfigs:
  - logType: ADMIN_READ
  - logType: DATA_READ
  - logType: DATA_WRITE
```

### 2. Set Up Alerts
```bash
# Create billing alerts
gcloud alpha billing budgets create \
  --billing-account=BILLING_ACCOUNT_ID \
  --display-name="GKE Security Budget" \
  --budget-amount=100USD
```

### 3. Regular Security Scans
```bash
# Scan for vulnerabilities
gcloud container images scan IMAGE_URL

# Check for exposed secrets
git secrets --scan
```

##  Incident Response

### If Credentials Are Compromised:

1. **Immediate Actions:**
   ```bash
   # Disable the compromised service account
   gcloud iam service-accounts disable SA_EMAIL
   
   # Delete the compromised key
   gcloud iam service-accounts keys delete KEY_ID --iam-account=SA_EMAIL
   ```

2. **Investigate:**
   ```bash
   # Check audit logs
   gcloud logging read "resource.type=gce_instance" --limit=50
   
   # Check for unauthorized access
   gcloud logging read 'resource.type="gke_cluster"' --limit=50
   ```

3. **Recovery:**
   ```bash
   # Create new service account
   gcloud iam service-accounts create new-sa-name
   
   # Generate new key
   gcloud iam service-accounts keys create new-key.json \
     --iam-account=new-sa-name@PROJECT_ID.iam.gserviceaccount.com
   ```

### If Repository is Compromised:

1. **Remove sensitive data:**
   ```bash
   # Use BFG Repo-Cleaner
   git clone --mirror git://example.com/repo.git
   java -jar bfg.jar --delete-files id_rsa repo.git
   ```

2. **Rotate all credentials** that might have been exposed

3. **Review commit history** for unauthorized changes

##  Security Checklist

Before deployment, ensure:

- [ ] No hardcoded credentials in code
- [ ] All sensitive files in `.gitignore`
- [ ] Service accounts follow least privilege
- [ ] Workload Identity is enabled
- [ ] Audit logging is configured
- [ ] Billing alerts are set up
- [ ] Network policies are in place
- [ ] Private clusters are used
- [ ] Node auto-upgrade is enabled
- [ ] Security patches are applied

##  Additional Resources

- [GKE Security Best Practices](https://cloud.google.com/kubernetes-engine/docs/how-to/hardening-your-cluster)
- [Terraform Security](https://learn.hashicorp.com/tutorials/terraform/sensitive-variables)
- [Google Cloud Security Command Center](https://cloud.google.com/security-command-center)
- [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes)

## 📞 Reporting Security Issues

If you discover a security vulnerability:
1. **Do NOT** create a public issue
2. Contact the project maintainers directly
3. Provide detailed information about the vulnerability
4. Allow time for remediation before disclosure

---

**Remember: Security is everyone's responsibility! **

# CI/CD Pipeline Setup Guide

Complete setup guide for the GitHub Actions CI/CD pipeline that automates deployment of the Hello World Flask app to GKE.

## Prerequisites

Before setting up the CI/CD pipeline, ensure you have:

- GKE clusters deployed (staging and production)
- Artifact Registry repositories created
- Helm chart configured
- GitHub repository with appropriate permissions

## Step-by-Step Setup

### 1. Create Service Account for GitHub Actions

```bash
# Set variables
export PROJECT_ID="ID_GOOOGLEEE"
export SA_NAME="github-actions-sa"
export SA_EMAIL="$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com"

# Create service account
gcloud iam service-accounts create $SA_NAME \
  --description="Service account for GitHub Actions CI/CD" \
  --display-name="GitHub Actions Service Account"

# Grant required permissions
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/container.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/artifactregistry.writer"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/storage.objectViewer"

# Create and download key
gcloud iam service-accounts keys create github-actions-key.json \
  --iam-account=$SA_EMAIL

echo "Service account key saved to: github-actions-key.json"
echo "Add this as GCP_SA_KEY secret in GitHub"
```

### 2. Configure GitHub Repository

#### Add Repository Secrets

1. Go to your GitHub repository
2. Navigate to Settings > Secrets and variables > Actions
3. Add the following secret:

**`GCP_SA_KEY`**
- Copy the entire content of `github-actions-key.json`
- Paste as the secret value

#### Set Up Environments

1. Go to Settings > Environments
2. Create three environments:

**staging**
- No protection rules
- No deployment branch restrictions

**production**
- Deployment protection rules:
  - Required reviewers: Add team members
  - Deployment branch rule: `v*` (tags only)

**production-approval**
- Deployment protection rules:
  - Required reviewers: Add senior team members
  - Deployment branch rule: `v*` (tags only)

### 3. Configure CODEOWNERS

Update `.github/CODEOWNERS` with your team members:

```
# Global owners
* @your-github-username

# Infrastructure requires approval
/infra/ @infrastructure-team

# Production deployments require senior approval
/.github/workflows/ @senior-team

# Helm charts require platform team
/charts/ @platform-team
```

### 4. Test the Pipeline

#### Test PR Checks

```bash
# Create a feature branch
git checkout -b feature/test-pipeline

# Make a small change
echo "# Test change" >> app/README.md

# Commit and push
git add app/README.md
git commit -m "Test: Add test change for pipeline"
git push origin feature/test-pipeline

# Create PR in GitHub UI
```

#### Test Staging Deployment

```bash
# Merge PR to main or push directly
git checkout main
git merge feature/test-pipeline
git push origin main

# Monitor workflow in GitHub Actions
```

#### Test Production Deployment

```bash
# Create and push a version tag
git tag v1.0.0
git push origin v1.0.0

# Monitor workflow and approve when prompted
```

## Workflow Configuration

### Environment Variables

Update these in `.github/workflows/deploy.yml` for your project:

```yaml
env:
  PROJECT_ID: your-project-id
  STAGING_REGISTRY: us-central1-docker.pkg.dev/your-project-id/staging-docker
  PRODUCTION_REGISTRY: us-east1-docker.pkg.dev/your-project-id/production-docker
  STAGING_CLUSTER: gke-staging
  PRODUCTION_CLUSTER: gke-production
```

### Customization Options

#### Skip Approval for Emergency Deployments

```bash
# Use workflow_dispatch with skip_approval: true
# Available in GitHub Actions UI under "Run workflow"
```

#### Deploy Specific Version

```bash
# Tag a specific commit
git checkout <commit-hash>
git tag v1.0.1
git push origin v1.0.1
```

#### Manual Staging Deployment

```bash
# Use workflow_dispatch
# Select "staging" environment
# Trigger from GitHub Actions UI
```

## Monitoring and Observability

### GitHub Actions Monitoring

```bash
# View workflow status via GitHub CLI
gh run list
gh run view <run-id>
```

### Application Monitoring

```bash
# Check staging deployment
kubectl --context=gke_${PROJECT_ID}_us-central1_gke-staging get all -l app=hello-world-flask

# Check production deployment
kubectl --context=gke_${PROJECT_ID}_us-east1_gke-production get all -l app=hello-world-flask

# Get application URLs
kubectl --context=gke_${PROJECT_ID}_us-central1_gke-staging get service hello-app-staging-service
kubectl --context=gke_${PROJECT_ID}_us-east1_gke-production get service hello-app-production-service
```

### Health Check Endpoints

```bash
# Test staging health
curl http://STAGING_EXTERNAL_IP/api/health

# Test production health
curl http://PRODUCTION_EXTERNAL_IP/api/health

# Get detailed info
curl http://EXTERNAL_IP/api/info
```

## Security Configuration

### Service Account Least Privilege

The GitHub Actions service account has minimal required permissions:

- **Container Admin**: Deploy to GKE clusters
- **Artifact Registry Writer**: Push container images
- **Storage Object Viewer**: Access Terraform state (if needed)

### Container Security

- **Trivy scanning**: Vulnerability scanning on every build
- **SARIF upload**: Security results uploaded to GitHub Security tab
- **Image signing**: Container images include metadata labels
- **Non-root containers**: Flask app runs as non-root user

### Branch Protection

Recommended branch protection rules for `main`:

- Require pull request reviews
- Require status checks (PR workflow)
- Require branches to be up to date
- Restrict pushes to administrators only

## Troubleshooting

### Common Issues and Solutions

#### 1. Authentication Errors

**Error**: `Error: google-github-actions/auth failed`

**Solution**:
```bash
# Verify service account key format
cat github-actions-key.json | jq .

# Ensure secret is properly set in GitHub
# Check service account permissions
gcloud projects get-iam-policy $PROJECT_ID --flatten="bindings[].members" --filter="bindings.members:$SA_EMAIL"
```

#### 2. Docker Build Failures

**Error**: `failed to solve: failed to load LLB definition`

**Solution**:
```bash
# Test build locally
cd app
docker build -t test .

# Check Dockerfile syntax
docker build --no-cache -t test .
```

#### 3. Helm Deployment Failures

**Error**: `Error: INSTALLATION FAILED`

**Solution**:
```bash
# Test Helm template locally
helm template hello-app ./charts/hello-app --values ./charts/hello-app/values-staging.yaml --dry-run

# Check cluster connectivity
kubectl cluster-info
kubectl get nodes
```

#### 4. Health Check Failures

**Error**: `curl: (7) Failed to connect`

**Solution**:
```bash
# Check pod status
kubectl get pods -l app=hello-world-flask

# Check service status
kubectl get service hello-app-staging-service

# Check pod logs
kubectl logs -l app=hello-world-flask
```

#### 5. Approval Issues

**Error**: Environment approval timeout

**Solution**:
- Verify required reviewers have repository access
- Check environment protection rules
- Ensure reviewers are notified (GitHub notifications)

## Advanced Configuration

### Custom Deployment Strategies

#### Blue-Green Deployment

Modify Helm values to support blue-green deployments:

```yaml
# values-production-blue.yaml
replicaCount: 4
service:
  name: hello-app-blue
```

#### Canary Deployment

Use Helm hooks for canary deployments:

```yaml
# Add to deployment template
metadata:
  annotations:
    helm.sh/hook: pre-upgrade
    helm.sh/hook-weight: "1"
```

### Integration with External Tools

#### Slack Notifications

Add Slack notification step:

```yaml
- name: Notify Slack
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

#### Datadog Metrics

Add deployment tracking:

```yaml
- name: Track deployment
  run: |
    curl -X POST "https://api.datadoghq.com/api/v1/events" \
    -H "DD-API-KEY: ${{ secrets.DATADOG_API_KEY }}" \
    -d '{
      "title": "Deployment Complete",
      "text": "Version ${{ needs.build.outputs.version }} deployed to ${{ env.ENVIRONMENT }}",
      "tags": ["deployment", "gke", "production"]
    }'
```

## Maintenance

### Regular Tasks

1. **Update GitHub Actions versions** monthly
2. **Rotate service account keys** quarterly
3. **Review and update approval teams** as needed
4. **Monitor workflow execution times** and optimize
5. **Update container base images** for security patches

### Backup and Recovery

```bash
# Backup workflow configurations
git archive --format=tar.gz HEAD:.github/ > github-workflows-backup.tar.gz

# Backup Helm charts
git archive --format=tar.gz HEAD:charts/ > helm-charts-backup.tar.gz
```

This completes the CI/CD pipeline setup. The workflow will now automatically build, test, and deploy your Flask application to GKE with proper approval controls for production deployments.
