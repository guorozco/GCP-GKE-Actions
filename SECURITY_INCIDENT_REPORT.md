# CRITICAL SECURITY INCIDENT REPORT

**Date**: $(date)
**Severity**: CRITICAL
**Issue**: Hardcoded Service Account Keys in Repository

## Executive Summary

**CRITICAL SECURITY VULNERABILITY DETECTED**: Service account JSON files containing private keys have been found hardcoded in the repository. This represents a severe security risk as these credentials could be used to access GCP resources.

## Affected Files

1. `./terraform-sa-key.json`
2. `./infra/environments/staging/terraform-sa-key.json`

Both files contain:
- Service account email addresses
- Private key IDs  
- Full RSA private keys
- Project ID information

## Risk Assessment

**RISK LEVEL: CRITICAL**

- **Confidentiality**: HIGH RISK - Private keys exposed
- **Integrity**: HIGH RISK - Unauthorized access to GCP resources possible
- **Availability**: MEDIUM RISK - Resources could be modified/deleted

## Immediate Actions Required

### 1. STOP ALL OPERATIONS
- Do not push any changes to remote repository
- Do not share repository until remediated

### 2. REVOKE COMPROMISED CREDENTIALS
```bash
# Find and delete the service accounts (if still exist)
gcloud iam service-accounts list --filter="email:*terraform*"
gcloud iam service-accounts delete SA_EMAIL --quiet

# Or disable the keys
gcloud iam service-accounts keys list --iam-account=SA_EMAIL
gcloud iam service-accounts keys delete KEY_ID --iam-account=SA_EMAIL
```

### 3. REMOVE FILES IMMEDIATELY
```bash
# Delete the files
rm -f terraform-sa-key.json
rm -f infra/environments/staging/terraform-sa-key.json

# Add to .gitignore
echo "*.json" >> .gitignore
echo "*-key.json" >> .gitignore
echo "*service-account*.json" >> .gitignore
```

### 4. CLEAN GIT HISTORY
```bash
# Remove from git history (DANGEROUS - creates new commit hashes)
git filter-branch --tree-filter 'rm -f terraform-sa-key.json infra/environments/staging/terraform-sa-key.json' HEAD
git push --force-with-lease origin main

# Alternative using BFG Repo-Cleaner (recommended)
bfg --delete-files "*.json" --delete-files "*-key.json"
git reflog expire --expire=now --all && git gc --prune=now --aggressive
```

## Root Cause Analysis

### How This Happened
1. Service account keys were generated during initial setup
2. Keys were committed to repository (likely accidentally)
3. No pre-commit hooks to prevent credential commits
4. No credential scanning in CI/CD pipeline

### Why It Wasn't Caught Earlier
- No automated credential scanning
- No .gitignore rules for sensitive files
- No pre-commit security checks

## Remediation Steps

### Immediate (0-2 hours)
- [ ] Delete credential files from filesystem
- [ ] Revoke/rotate all affected service account keys
- [ ] Update .gitignore
- [ ] Clean git history
- [ ] Force push clean history

### Short-term (2-24 hours)
- [ ] Audit all GCP IAM roles and permissions
- [ ] Review access logs for suspicious activity
- [ ] Create new service accounts with minimal permissions
- [ ] Update all documentation to remove credential references
- [ ] Implement proper secret management

### Long-term (1-4 weeks)
- [ ] Implement pre-commit hooks for credential detection
- [ ] Add credential scanning to CI/CD pipeline
- [ ] Security training for development team
- [ ] Regular security audits
- [ ] Implement proper secret management (e.g., Google Secret Manager)

## Security Best Practices Going Forward

### 1. Secret Management
```bash
# Use environment variables instead of files
export GOOGLE_APPLICATION_CREDENTIALS="/secure/path/to/key.json"

# Or use Google Secret Manager
gcloud secrets create terraform-sa-key --data-file=key.json
```

### 2. .gitignore Rules
```
# Credentials and secrets
*.json
*-key.json
*service-account*.json
*.pem
*.key
*.p12
.env*
secret*
credential*
```

### 3. Pre-commit Hooks
```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/Yelp/detect-secrets
    rev: v1.4.0
    hooks:
      - id: detect-secrets
```

### 4. CI/CD Security Scanning
```yaml
# Add to GitHub Actions
- name: Credential Scan
  uses: trufflesecurity/trufflehog@main
  with:
    path: ./
```

## Lessons Learned

1. **Never commit credentials**: Use environment variables or secret management
2. **Implement scanning**: Both local and CI/CD credential scanning
3. **Regular audits**: Periodic security reviews of repositories
4. **Team training**: Ensure all team members understand security practices

## Verification

After remediation, verify security:

```bash
# Check no credentials remain
grep -r "private_key\|BEGIN.*KEY" . --exclude-dir=.git
find . -name "*.json" -exec grep -l "private_key" {} \;

# Verify .gitignore
git check-ignore test-key.json

# Test pre-commit hooks
echo '{"private_key": "test"}' > test.json
git add test.json  # Should be blocked
```

## Contact Information

- **Security Team**: security@company.com
- **Incident Commander**: [Name]
- **GCP Admin**: [Name]

---

**This incident must be treated with highest priority until fully resolved.**
