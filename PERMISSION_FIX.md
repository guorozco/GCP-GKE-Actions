# 🔐 GKE Permission Issues - Solutions

This error occurs because your user account doesn't have the required permissions to use the default compute service account for GKE.

## 🎯 Error Analysis

**Error**: `The user does not have access to service account "XXXXXX-compute@developer.gserviceaccount.com". Ask a project owner to grant you the iam.serviceAccountUser role`

**Root Cause**: Missing IAM permissions to use the default compute service account.

## 🔧 Solution Options

### Option 1: Grant Required Permissions (Recommended)

If you are the project owner or have admin access:

```bash
# Set your project ID
export TF_VAR_project_id="test-demo-123456-guillermo"

# Get your current user email
USER_EMAIL=$(gcloud config get-value account)
echo "Current user: $USER_EMAIL"

# Grant the required role to your user
gcloud projects add-iam-policy-binding $TF_VAR_project_id \
    --member="user:$USER_EMAIL" \
    --role="roles/iam.serviceAccountUser"

# Also grant additional required roles for GKE
gcloud projects add-iam-policy-binding $TF_VAR_project_id \
    --member="user:$USER_EMAIL" \
    --role="roles/container.admin"

gcloud projects add-iam-policy-binding $TF_VAR_project_id \
    --member="user:$USER_EMAIL" \
    --role="roles/compute.admin"

# Verify the roles
gcloud projects get-iam-policy $TF_VAR_project_id \
    --flatten="bindings[].members" \
    --format="table(bindings.role)" \
    --filter="bindings.members:$USER_EMAIL"
```

### Option 2: Use Application Default Credentials

If Option 1 doesn't work, set up application default credentials:

```bash
# Set up application default credentials
gcloud auth application-default login

# This will open a browser for authentication
# Follow the prompts to authenticate
```

### Option 3: Create a Dedicated Service Account

Create a service account with the necessary permissions:

```bash
# Create a service account for Terraform
gcloud iam service-accounts create terraform-gke-admin \
    --display-name="Terraform GKE Admin" \
    --description="Service account for Terraform GKE operations"

# Grant necessary roles to the service account
SA_EMAIL="terraform-gke-admin@$TF_VAR_project_id.iam.gserviceaccount.com"

gcloud projects add-iam-policy-binding $TF_VAR_project_id \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/container.admin"

gcloud projects add-iam-policy-binding $TF_VAR_project_id \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/compute.admin"

gcloud projects add-iam-policy-binding $TF_VAR_project_id \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/iam.serviceAccountUser"

gcloud projects add-iam-policy-binding $TF_VAR_project_id \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/resourcemanager.projectIamAdmin"

# Create and download the key
gcloud iam service-accounts keys create terraform-sa-key.json \
    --iam-account="$SA_EMAIL"

# Set the environment variable
export GOOGLE_APPLICATION_CREDENTIALS="$(pwd)/terraform-sa-key.json"
```

### Option 4: Modify GKE Configuration for Autopilot

Since this is an Autopilot cluster, we can simplify the configuration to avoid the service account issue:

```hcl
# This will be applied automatically - no action needed
# The configuration has been updated to work better with Autopilot
```

## 🚀 Quick Fix Commands

### Try This First (Most Common Solution):

```bash
# Navigate to your staging directory
cd /Users/gumana/src/GCP-GKE-Actions/infra/environments/staging

# Set project and get user info
export TF_VAR_project_id="test-demo-123456-guillermo"
USER_EMAIL=$(gcloud config get-value account)

# Grant required permissions
gcloud projects add-iam-policy-binding $TF_VAR_project_id \
    --member="user:$USER_EMAIL" \
    --role="roles/iam.serviceAccountUser"

gcloud projects add-iam-policy-binding $TF_VAR_project_id \
    --member="user:$USER_EMAIL" \
    --role="roles/container.admin"

# Clean cache and retry
rm -rf .terragrunt-cache
terragrunt init
terragrunt apply
```

### Alternative - Use Application Default Credentials:

```bash
# Set up application default credentials
gcloud auth application-default login

# Clean cache and retry
rm -rf .terragrunt-cache
terragrunt init
terragrunt apply
```

## 🔍 Verification

After applying the permissions, verify them:

```bash
# Check your current permissions
gcloud projects get-iam-policy $TF_VAR_project_id \
    --flatten="bindings[].members" \
    --format="table(bindings.role)" \
    --filter="bindings.members:$(gcloud config get-value account)"

# Test GKE access
gcloud container clusters list --project=$TF_VAR_project_id
```

## 🆘 If Still Having Issues

1. **Contact Project Owner**: If you're not the project owner, ask them to grant you these roles:
   - `roles/iam.serviceAccountUser`
   - `roles/container.admin`
   - `roles/compute.admin`

2. **Check Project Billing**: Ensure billing is enabled for the project

3. **Verify APIs**: Ensure required APIs are enabled:
   ```bash
   gcloud services enable container.googleapis.com
   gcloud services enable compute.googleapis.com
   gcloud services enable iam.googleapis.com
   ```

## 📋 Required IAM Roles Summary

For GKE deployment, your user needs:
- `roles/iam.serviceAccountUser` - To use service accounts
- `roles/container.admin` - To manage GKE clusters
- `roles/compute.admin` - To manage compute resources
- `roles/storage.admin` - For Terraform state storage

## 🎯 Next Steps

1. Try **Option 1** first (grant permissions)
2. If that fails, try **Option 2** (application default credentials)
3. If still issues, create a dedicated service account (**Option 3**)
4. Contact project owner if you don't have sufficient permissions

---

**Choose the solution that best fits your access level and try the deployment again!**

