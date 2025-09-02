# GitHub Actions CI/CD Pipeline

This directory contains the GitHub Actions workflows for automated deployment of the Hello World Flask application to GKE.

## Workflows

### 1. Main Deployment Pipeline (`deploy.yml`)

A comprehensive 4-stage deployment pipeline:

**Stage 1: Build**
- Builds Docker image from Flask app
- Pushes to Artifact Registry (staging and production)
- Includes security scanning with Trivy
- Generates image metadata and labels

**Stage 2: Deploy to Staging**
- Deploys to staging GKE cluster using Helm
- Runs health checks and validation
- Automatic deployment on main/develop branch pushes

**Stage 3: Manual Approval**
- Requires manual approval for production deployments
- Only triggered for version tags (v*)
- Uses GitHub Environments for approval controls

**Stage 4: Deploy to Production**
- Deploys to production GKE cluster
- Enhanced health checks with external IP testing
- Only runs after successful approval

### 2. Pull Request Checks (`pr-checks.yml`)

Quality gates for pull requests:
- Code linting (Python, Helm, Terraform)
- Docker build testing
- Security vulnerability scanning
- Helm template validation

## Environment Setup

### Required Secrets

Add these secrets in your GitHub repository:

**`GCP_SA_KEY`**
```json
{
  "type": "service_account",
  "project_id": "your-project-id",
  "private_key_id": "...",
  "private_key": "...",
  "client_email": "...",
  "client_id": "...",
  "auth_uri": "...",
  "token_uri": "...",
  "auth_provider_x509_cert_url": "...",
  "client_x509_cert_url": "..."
}
```

### Required Environments

Create these environments in GitHub repository settings:

1. **staging**
   - No protection rules
   - Allow any branch to deploy

2. **production**
   - Restrict to tags matching `v*`
   - Required reviewers: Add your senior team members

3. **production-approval**
   - Restrict to tags matching `v*`
   - Required reviewers: Add approvers for production deployments

## Service Account Permissions

The GCP service account needs these IAM roles:

```bash
# Core permissions
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/container.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/artifactregistry.writer"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/storage.admin"
```

## Workflow Triggers

### Automatic Triggers

- **Push to main/develop**: Builds and deploys to staging
- **Pull requests**: Runs quality checks only
- **Version tags (v*)**: Full pipeline with production deployment

### Manual Triggers

- **workflow_dispatch**: Manual deployment with environment selection
- **Skip approval option**: Emergency deployments (use with caution)

## Deployment Process

### Normal Release Flow

1. **Create release tag:**
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. **Monitor pipeline:**
   - Build stage runs automatically
   - Staging deployment happens automatically
   - Manual approval required for production
   - Production deployment after approval

### Hotfix Flow

1. **Push to main branch:**
   ```bash
   git push origin main
   ```

2. **Deploy to staging automatically**

3. **Manual production deployment:**
   - Use workflow_dispatch with production environment
   - Skip approval if necessary (emergency only)

## Monitoring Deployments

### GitHub Actions UI

- View workflow runs in the Actions tab
- Monitor deployment status and logs
- Review approval requests

### Command Line Monitoring

```bash
# Check staging deployment
kubectl --context=gke_PROJECT_ID_us-central1_gke-staging get pods -l app=hello-world-flask

# Check production deployment
kubectl --context=gke_PROJECT_ID_us-east1_gke-production get pods -l app=hello-world-flask

# Get service URLs
kubectl --context=gke_PROJECT_ID_us-central1_gke-staging get service hello-app-staging-service
kubectl --context=gke_PROJECT_ID_us-east1_gke-production get service hello-app-production-service
```

## Security Features

- **Container scanning** with Trivy
- **SARIF upload** for vulnerability tracking
- **Environment protection** with required reviewers
- **Least privilege** service account permissions
- **Signed container images** with metadata labels

## Troubleshooting

### Common Issues

1. **Authentication Failures**
   - Verify GCP_SA_KEY secret is correctly formatted
   - Check service account permissions

2. **Build Failures**
   - Check Dockerfile syntax
   - Verify requirements.txt dependencies

3. **Deployment Failures**
   - Check Helm chart values
   - Verify GKE cluster connectivity
   - Review resource quotas

4. **Approval Issues**
   - Verify environment protection rules
   - Check required reviewer permissions

### Debug Commands

```bash
# Local testing
helm template hello-app ./charts/hello-app --values ./charts/hello-app/values-staging.yaml --dry-run

# Test Docker build
cd app && docker build -t test .

# Validate workflow
act -j build  # If using act for local testing
```

## Best Practices

1. **Use semantic versioning** for releases (v1.0.0, v1.0.1, etc.)
2. **Test in staging** before production deployments
3. **Monitor deployments** and set up alerts
4. **Review approval requests** carefully
5. **Keep secrets secure** and rotate regularly
6. **Document changes** in release notes

## Configuration

### Customizing the Pipeline

Update these files to customize the pipeline:

- **`.github/workflows/deploy.yml`** - Main pipeline configuration
- **`.github/workflows/pr-checks.yml`** - Quality gate configuration
- **`.github/CODEOWNERS`** - Code review requirements
- **Environment files** - Protection rules documentation

### Environment Variables

Key variables in the workflow:

```yaml
env:
  PROJECT_ID: test-demo-123456-guillermo
  STAGING_REGISTRY: us-central1-docker.pkg.dev/test-demo-123456-guillermo/staging-docker
  PRODUCTION_REGISTRY: us-east1-docker.pkg.dev/test-demo-123456-guillermo/production-docker
  IMAGE_NAME: hello-world-flask
```

Update these values to match your project configuration.
