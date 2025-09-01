# 🚀 GKE Infrastructure Deployment Guide - Free Tier Optimized

This guide will help you deploy a cost-optimized GKE cluster using Terraform and Terragrunt on Google Cloud Platform's free tier.

## 🎯 Free Tier Optimizations

This infrastructure is specifically optimized for GCP's Always Free tier:

- **GKE Autopilot mode** for staging (most cost-effective)
- **e2-micro and e2-small instances** (free tier eligible)
- **Preemptible nodes** for significant cost savings
- **Minimal disk sizes** (32GB instead of 100GB)
- **Reduced resource limits** and scaling constraints
- **Free tier eligible regions**

## 💰 Cost Estimates

- **Staging (Autopilot)**: ~$0-10/month
- **Production (Standard)**: ~$15-30/month

> **Note**: These estimates assume minimal usage. Monitor your billing closely and adjust resources as needed.

## 📋 Prerequisites

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

## 🚀 Quick Start

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
- ✅ Check prerequisites
- ✅ Enable required GCP APIs
- ✅ Create GCS buckets for Terraform state
- ✅ Optionally create a service account
- ✅ Generate environment configuration

### Step 2: Configure Environment

```bash
# Source the environment variables
source .env.local

# Verify your project ID is set
echo $TF_VAR_project_id
```

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

## 🛠️ Advanced Setup

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

## 🎛️ Configuration Options

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

## 🔐 Authentication & Access

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

## 📊 Monitoring Costs

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

## 🔧 Customization

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

## 🧹 Cleanup

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

## 🐛 Troubleshooting

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

## 📚 Additional Resources

- [GCP Free Tier Documentation](https://cloud.google.com/free)
- [GKE Autopilot Pricing](https://cloud.google.com/kubernetes-engine/pricing#autopilot_mode)
- [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Terragrunt Documentation](https://terragrunt.gruntwork.io/)

## 🎉 Next Steps

After deployment:

1. **Deploy a sample application**
2. **Set up monitoring and logging**
3. **Configure CI/CD pipelines**
4. **Implement security best practices**
5. **Set up backup strategies**

---

**Happy deploying! 🚀**

*Remember to monitor your costs and adjust resources based on your actual usage patterns.*
