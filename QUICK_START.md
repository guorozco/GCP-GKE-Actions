# 🚀 Quick Start Guide - GKE Free Tier

This is a streamlined guide to get your GKE cluster running on the free tier as quickly as possible.

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

## 🎯 What You Get

- **GKE Autopilot cluster** (most cost-effective)
- **Free tier optimized** (e2-micro instances)
- **Preemptible nodes** for cost savings
- **Private cluster** with security best practices
- **Workload Identity** for secure GCP access

## 💰 Cost Estimate

- **Staging**: ~$0-10/month (with free tier credits)
- Uses GKE Autopilot for optimal cost management

## 🛠️ Optional: Production Deployment

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

## 🧹 Cleanup

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
   - Fixed in this version ✅

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

## 📞 Need Help?

- Check the full [DEPLOYMENT.md](DEPLOYMENT.md) guide
- Use the Makefile: `make help`
- Run the setup script: `./scripts/setup.sh`

---

**Ready to deploy? Run the commands above and you'll have a GKE cluster in minutes! 🚀**
