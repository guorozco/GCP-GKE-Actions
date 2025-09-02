# 🐳 Artifact Registry - Docker Container Management

This guide covers how to use Google Artifact Registry for Docker images with your GKE infrastructure.

## 🎯 Overview

Your infrastructure includes three Artifact Registry repositories:

- **Staging**: `us-central1-docker.pkg.dev/PROJECT_ID/staging-docker`
- **Production**: `us-east1-docker.pkg.dev/PROJECT_ID/production-docker`
- **Shared**: `us-central1-docker.pkg.dev/PROJECT_ID/shared-docker`

## 🚀 Quick Start

### 1. Deploy Artifact Registry

```bash
# Set your project ID
export TF_VAR_project_id="your-project-id"

# Deploy staging registry
make deploy-registry-staging

# Deploy production registry
make deploy-registry-production

# Optional: Deploy shared registry
make deploy-registry-shared
```

### 2. Configure Docker Authentication

```bash
# Configure Docker for all registries
make configure-docker-all

# Or configure individually
make configure-docker-staging
make configure-docker-production
```

### 3. Build and Push Your First Image

```bash
# Build a sample image
docker build -t my-app:latest .

# Tag for staging
docker tag my-app:latest us-central1-docker.pkg.dev/$TF_VAR_project_id/staging-docker/my-app:latest

# Push to staging
docker push us-central1-docker.pkg.dev/$TF_VAR_project_id/staging-docker/my-app:latest
```

## 📦 Repository Configuration

### Staging Repository
- **Location**: `us-central1` (same as GKE staging)
- **Cleanup**: Deletes untagged images after 30 days
- **Immutable tags**: Disabled (allows overwriting)
- **Purpose**: Development and testing

### Production Repository
- **Location**: `us-east1` (same as GKE production)
- **Cleanup**: Deletes untagged images after 90 days
- **Immutable tags**: Enabled (prevents overwriting)
- **Purpose**: Production deployments

### Shared Repository
- **Location**: `us-central1` (central location)
- **Cleanup**: Keeps stable/release tags indefinitely
- **Immutable tags**: Enabled
- **Purpose**: Base images, shared libraries

## 🔧 Common Commands

### Docker Operations

```bash
# List all repositories
make list-registries

# List images in repositories
make list-images

# Build and tag image for staging
docker build -t us-central1-docker.pkg.dev/$TF_VAR_project_id/staging-docker/my-app:v1.0 .

# Push to staging
docker push us-central1-docker.pkg.dev/$TF_VAR_project_id/staging-docker/my-app:v1.0

# Pull from production
docker pull us-east1-docker.pkg.dev/$TF_VAR_project_id/production-docker/my-app:v1.0

# Promote from staging to production
docker pull us-central1-docker.pkg.dev/$TF_VAR_project_id/staging-docker/my-app:v1.0
docker tag us-central1-docker.pkg.dev/$TF_VAR_project_id/staging-docker/my-app:v1.0 \
  us-east1-docker.pkg.dev/$TF_VAR_project_id/production-docker/my-app:v1.0
docker push us-east1-docker.pkg.dev/$TF_VAR_project_id/production-docker/my-app:v1.0
```

### Registry Management

```bash
# List repositories
gcloud artifacts repositories list --project=$TF_VAR_project_id

# List images in staging
gcloud artifacts docker images list \
  us-central1-docker.pkg.dev/$TF_VAR_project_id/staging-docker \
  --project=$TF_VAR_project_id

# Delete specific image
gcloud artifacts docker images delete \
  us-central1-docker.pkg.dev/$TF_VAR_project_id/staging-docker/my-app:old-tag \
  --project=$TF_VAR_project_id

# List tags for an image
gcloud artifacts docker tags list \
  us-central1-docker.pkg.dev/$TF_VAR_project_id/staging-docker/my-app \
  --project=$TF_VAR_project_id
```

## 🔐 Security & Access Control

### Service Accounts

Each repository has its own service account:
- `staging-docker-ar-sa@PROJECT_ID.iam.gserviceaccount.com`
- `production-docker-ar-sa@PROJECT_ID.iam.gserviceaccount.com`
- `shared-docker-ar-sa@PROJECT_ID.iam.gserviceaccount.com`

### IAM Roles

- **Reader**: `roles/artifactregistry.reader` - Pull images
- **Writer**: `roles/artifactregistry.writer` - Push/pull images
- **Repository Admin**: `roles/artifactregistry.repoAdmin` - Full control

### GKE Integration

Your GKE clusters automatically have access to pull images:

```yaml
# In your Kubernetes deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    spec:
      containers:
      - name: my-app
        image: us-central1-docker.pkg.dev/PROJECT_ID/staging-docker/my-app:latest
```

## 🏗️ CI/CD Integration

### GitHub Actions Example

```yaml
name: Build and Deploy
on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - id: auth
      uses: google-github-actions/auth@v1
      with:
        credentials_json: ${{ secrets.GCP_SA_KEY }}
    
    - name: Configure Docker
      run: gcloud auth configure-docker us-central1-docker.pkg.dev
    
    - name: Build and Push
      run: |
        docker build -t us-central1-docker.pkg.dev/$PROJECT_ID/staging-docker/my-app:$GITHUB_SHA .
        docker push us-central1-docker.pkg.dev/$PROJECT_ID/staging-docker/my-app:$GITHUB_SHA
```

### GitLab CI Example

```yaml
stages:
  - build
  - deploy

build:
  stage: build
  image: google/cloud-sdk:alpine
  script:
    - gcloud auth activate-service-account --key-file $GOOGLE_APPLICATION_CREDENTIALS
    - gcloud auth configure-docker us-central1-docker.pkg.dev
    - docker build -t us-central1-docker.pkg.dev/$PROJECT_ID/staging-docker/my-app:$CI_COMMIT_SHA .
    - docker push us-central1-docker.pkg.dev/$PROJECT_ID/staging-docker/my-app:$CI_COMMIT_SHA
```

## 💰 Cost Optimization

### Cleanup Policies

Automatic cleanup policies are configured to minimize storage costs:

**Staging**:
- Untagged images deleted after 30 days
- Tagged images kept for minimum 1 day

**Production**:
- Untagged images deleted after 90 days
- Tagged images kept for minimum 7 days

**Shared**:
- Stable/release tags kept indefinitely
- Other untagged images deleted after 14 days

### Manual Cleanup

```bash
# Remove old images manually
gcloud artifacts docker images delete \
  us-central1-docker.pkg.dev/$TF_VAR_project_id/staging-docker/my-app:old-tag \
  --delete-tags --project=$TF_VAR_project_id

# Bulk cleanup (be careful!)
gcloud artifacts docker images list \
  us-central1-docker.pkg.dev/$TF_VAR_project_id/staging-docker \
  --filter="createTime<'2024-01-01'" \
  --format="value(name)" | \
  xargs -I {} gcloud artifacts docker images delete {} --quiet
```

## 🔍 Monitoring & Troubleshooting

### View Repository Details

```bash
# Repository information
gcloud artifacts repositories describe staging-docker \
  --location=us-central1 \
  --project=$TF_VAR_project_id

# Check vulnerability scanning
gcloud artifacts docker images scan \
  us-central1-docker.pkg.dev/$TF_VAR_project_id/staging-docker/my-app:latest \
  --project=$TF_VAR_project_id
```

### Common Issues

1. **Authentication Failed**:
   ```bash
   gcloud auth configure-docker us-central1-docker.pkg.dev
   gcloud auth application-default login
   ```

2. **Permission Denied**:
   ```bash
   # Check IAM permissions
   gcloud projects get-iam-policy $TF_VAR_project_id \
     --flatten="bindings[].members" \
     --filter="bindings.members:$(gcloud config get-value account)"
   ```

3. **Repository Not Found**:
   ```bash
   # Verify repository exists
   make list-registries
   ```

## 📊 Best Practices

### Tagging Strategy

```bash
# Use semantic versioning
docker tag my-app:latest us-central1-docker.pkg.dev/$TF_VAR_project_id/staging-docker/my-app:v1.2.3

# Include git commit SHA
docker tag my-app:latest us-central1-docker.pkg.dev/$TF_VAR_project_id/staging-docker/my-app:$(git rev-parse --short HEAD)

# Environment-specific tags
docker tag my-app:latest us-central1-docker.pkg.dev/$TF_VAR_project_id/staging-docker/my-app:staging-latest
```

### Security

1. **Use specific tags** instead of `latest` in production
2. **Enable vulnerability scanning** for all images
3. **Regularly update base images** to get security patches
4. **Use multi-stage builds** to minimize image size
5. **Store secrets in Secret Manager**, not in images

### Performance

1. **Use .dockerignore** to reduce build context
2. **Layer caching** - put frequently changing files last
3. **Use regional registries** close to your GKE clusters
4. **Consider using image streaming** for faster deployments

## 🆘 Support Commands

```bash
# Health check
make list-registries

# Test image push/pull
docker build -t test-image .
docker tag test-image us-central1-docker.pkg.dev/$TF_VAR_project_id/staging-docker/test:latest
docker push us-central1-docker.pkg.dev/$TF_VAR_project_id/staging-docker/test:latest
docker rmi test-image us-central1-docker.pkg.dev/$TF_VAR_project_id/staging-docker/test:latest
docker pull us-central1-docker.pkg.dev/$TF_VAR_project_id/staging-docker/test:latest

# Clean up test
gcloud artifacts docker images delete \
  us-central1-docker.pkg.dev/$TF_VAR_project_id/staging-docker/test:latest \
  --project=$TF_VAR_project_id
```

---

**Happy containerizing! 🐳**

*Your Docker images are now securely stored and ready for deployment to your GKE clusters!*
