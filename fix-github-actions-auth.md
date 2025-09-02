# Fix GitHub Actions Authentication Error

## Problem
```
Error: google-github-actions/auth failed with: the GitHub Action workflow must specify exactly one of "workload_identity_provider" or "credentials_json"!
```

## Root Cause
The Google GitHub Actions auth action is not receiving the `credentials_json` parameter correctly, likely because:
1. The `GCP_SA_KEY` secret is not set in GitHub repository
2. The secret is empty or malformed
3. The workflow is running from a fork (secrets are not passed to forks)

## Solution Options

### Option 1: Fix Service Account Key Method (Immediate)

**Step 1: Verify GitHub Secret**
1. Go to your GitHub repository
2. Navigate to Settings > Secrets and variables > Actions
3. Ensure `GCP_SA_KEY` secret exists and contains valid JSON

**Step 2: Create Service Account Key (if needed)**
```bash
# Create a new service account
export PROJECT_ID="test-demo-123456-guillermo"
export SA_NAME="github-actions-deploy"
export SA_EMAIL="$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com"

gcloud iam service-accounts create $SA_NAME \
  --description="GitHub Actions deployment service account" \
  --display-name="GitHub Actions Deploy SA"

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

echo "Copy the content of github-actions-key.json to GitHub secret GCP_SA_KEY"
cat github-actions-key.json
```

**Step 3: Add Secret to GitHub**
1. Copy the entire JSON content from the key file
2. In GitHub: Settings > Secrets and variables > Actions
3. Add new secret named `GCP_SA_KEY`
4. Paste the JSON content

### Option 2: Use Workload Identity (Recommended - More Secure)

**Step 1: Setup Workload Identity Pool**
```bash
export PROJECT_ID="test-demo-123456-guillermo"
export POOL_ID="github-actions-pool"
export PROVIDER_ID="github-actions-provider"
export REPO="your-username/GCP-GKE-Actions"

# Create workload identity pool
gcloud iam workload-identity-pools create $POOL_ID \
  --project=$PROJECT_ID \
  --location="global" \
  --display-name="GitHub Actions Pool"

# Create workload identity provider
gcloud iam workload-identity-pools providers create-oidc $PROVIDER_ID \
  --project=$PROJECT_ID \
  --location="global" \
  --workload-identity-pool=$POOL_ID \
  --display-name="GitHub Actions Provider" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository" \
  --issuer-uri="https://token.actions.githubusercontent.com"

# Create service account
gcloud iam service-accounts create github-actions-wi \
  --project=$PROJECT_ID \
  --description="GitHub Actions with Workload Identity" \
  --display-name="GitHub Actions WI"

# Grant permissions to service account
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:github-actions-wi@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/container.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:github-actions-wi@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.writer"

# Allow GitHub Actions to impersonate the service account
gcloud iam service-accounts add-iam-policy-binding \
  --project=$PROJECT_ID \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')/locations/global/workloadIdentityPools/$POOL_ID/attribute.repository/$REPO" \
  github-actions-wi@$PROJECT_ID.iam.gserviceaccount.com
```

**Step 2: Update GitHub Actions Workflow**
```yaml
      - name: Authenticate to Google Cloud
        uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-actions-pool/providers/github-actions-provider
          service_account: github-actions-wi@test-demo-123456-guillermo.iam.gserviceaccount.com
          project_id: ${{ env.PROJECT_ID }}
```

## Quick Fix (Current Workflow)

For immediate resolution, update the workflow authentication blocks to include explicit project_id:

```yaml
      - name: Authenticate to Google Cloud
        uses: google-github-actions/auth@v2
        with:
          credentials_json: ${{ secrets.GCP_SA_KEY }}
          project_id: ${{ env.PROJECT_ID }}
```

## Debug Steps

**Check if secret exists:**
```yaml
      - name: Debug - Check secret
        run: |
          if [ -z "${{ secrets.GCP_SA_KEY }}" ]; then
            echo "GCP_SA_KEY secret is empty or not set"
            exit 1
          else
            echo "GCP_SA_KEY secret is set (length: ${#GCP_SA_KEY})"
          fi
        env:
          GCP_SA_KEY: ${{ secrets.GCP_SA_KEY }}
```

**Validate JSON format:**
```yaml
      - name: Debug - Validate JSON
        run: |
          echo "${{ secrets.GCP_SA_KEY }}" | jq . > /dev/null && echo "Valid JSON" || echo "Invalid JSON"
```

## Security Best Practices

1. **Use Workload Identity** (no long-lived keys)
2. **Principle of least privilege** (minimal IAM roles)
3. **Rotate service account keys** regularly
4. **Monitor access logs** for unusual activity
5. **Never commit credentials** to repository

## Testing the Fix

After implementing the fix:

```bash
# Test the workflow
git add .github/workflows/deploy.yml
git commit -m "fix: GitHub Actions authentication"
git push origin main

# Monitor the workflow execution in GitHub Actions tab
```

## Common Issues

1. **Fork workflows**: Secrets are not passed to workflows triggered from forks
2. **Branch restrictions**: Some secrets may be restricted to specific branches
3. **JSON formatting**: Ensure the service account key is valid JSON
4. **Permissions**: Verify the service account has required IAM roles

Choose Option 1 for immediate fix, then migrate to Option 2 (Workload Identity) for better security.
