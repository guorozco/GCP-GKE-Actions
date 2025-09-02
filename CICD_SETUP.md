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
export PROJECT_ID="test-demo-123456-guillermo"
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
