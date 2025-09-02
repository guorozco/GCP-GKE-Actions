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
