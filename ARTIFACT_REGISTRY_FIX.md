#  Artifact Registry Permission Fix

##  Error Analysis

**Error**: `Permission 'artifactregistry.repositories.create' denied`

**Root Cause**: Your user account doesn't have the required IAM permissions to create Artifact Registry repositories.

##  Quick Fix

### Step 1: Enable Artifact Registry API

```bash
# Set your project ID
export TF_VAR_project_id="test-demo-123456-guillermo"

# Enable the Artifact Registry API
gcloud services enable artifactregistry.googleapis.com --project=$TF_VAR_project_id
```

### Step 2: Grant Required IAM Roles

```bash
# Get your current user email
USER_EMAIL=$(gcloud config get-value account)
echo "Current user: $USER_EMAIL"

# Grant Artifact Registry Admin role
gcloud projects add-iam-policy-binding $TF_VAR_project_id \
    --member="user:$USER_EMAIL" \
    --role="roles/artifactregistry.admin"

# Grant additional required roles if not already present
gcloud projects add-iam-policy-binding $TF_VAR_project_id \
    --member="user:$USER_EMAIL" \
    --role="roles/storage.admin"
```

### Step 3: Verify Permissions

```bash
# Check your current permissions
gcloud projects get-iam-policy $TF_VAR_project_id \
    --flatten="bindings[].members" \
    --format="table(bindings.role)" \
    --filter="bindings.members:$USER_EMAIL"
```

### Step 4: Retry the Deployment

```bash
# Clean cache and retry
cd infra/environments/staging/artifact-registry
rm -rf .terragrunt-cache
terragrunt init
terragrunt apply
```

##  Alternative Solutions

### Option A: Use Service Account (Recommended for CI/CD)

```bash
# Create a dedicated service account for Terraform
gcloud iam service-accounts create terraform-artifact-registry \
    --display-name="Terraform Artifact Registry Admin" \
    --description="Service account for Terraform Artifact Registry operations"

# Grant required roles to the service account
SA_EMAIL="terraform-artifact-registry@$TF_VAR_project_id.iam.gserviceaccount.com"

gcloud projects add-iam-policy-binding $TF_VAR_project_id \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/artifactregistry.admin"

gcloud projects add-iam-policy-binding $TF_VAR_project_id \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/storage.admin"

gcloud projects add-iam-policy-binding $TF_VAR_project_id \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/iam.serviceAccountUser"

# Create and use the key
gcloud iam service-accounts keys create terraform-ar-sa-key.json \
    --iam-account="$SA_EMAIL"

export GOOGLE_APPLICATION_CREDENTIALS="$(pwd)/terraform-ar-sa-key.json"
```

### Option B: Enable Additional APIs

```bash
# Enable all required APIs
gcloud services enable \
    artifactregistry.googleapis.com \
    storage.googleapis.com \
    cloudresourcemanager.googleapis.com \
    iam.googleapis.com \
    --project=$TF_VAR_project_id
```

##  Required IAM Roles Summary

For Artifact Registry operations, you need:

- **`roles/artifactregistry.admin`** - Create/manage repositories
- **`roles/storage.admin`** - Access to underlying storage
- **`roles/iam.serviceAccountUser`** - Use service accounts (if applicable)

##  Troubleshooting Commands

### Check API Status
```bash
# List enabled APIs
gcloud services list --enabled --project=$TF_VAR_project_id | grep artifact

# Check API quota
gcloud services list --available --project=$TF_VAR_project_id | grep artifact
```

### Check Permissions
```bash
# Test specific permission
gcloud auth list
gcloud config get-value account

# Check if you can list repositories (test permission)
gcloud artifacts repositories list --project=$TF_VAR_project_id
```

### Check Project Settings
```bash
# Verify project
gcloud projects describe $TF_VAR_project_id

# Check billing
gcloud beta billing projects describe $TF_VAR_project_id
```

## ⚠ Common Issues

1. **API Not Enabled**: Most common cause
2. **Insufficient Permissions**: User doesn't have admin rights
3. **Project Billing**: Billing must be enabled
4. **Quota Limits**: Check if you've hit any quotas

##  Quick Test

After applying the fix, test with:

```bash
# Test creating a repository manually
gcloud artifacts repositories create test-repo \
    --repository-format=docker \
    --location=us-central1 \
    --description="Test repository" \
    --project=$TF_VAR_project_id

# If successful, delete it
gcloud artifacts repositories delete test-repo \
    --location=us-central1 \
    --project=$TF_VAR_project_id \
    --quiet
```
