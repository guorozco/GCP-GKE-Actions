#  Repository Cleanup Guide

This guide helps you clean up sensitive files and maintain repository security.

##  Sensitive Files Removed from Staging

The following sensitive files were unstaged and will not be committed:

-  `.env.local` - Environment variables (may contain secrets)
-  `terraform-sa-key.json` - Service account key file
-  `infra/environments/staging/terraform-sa-key.json` - Service account key
-  `infra/environments/staging/terraform.log` - Deployment logs

##  Clean Up Sensitive Files

**IMPORTANT**: These files are still in your working directory. Remove them to prevent accidental exposure:

```bash
# Remove service account keys
rm -f terraform-sa-key.json
rm -f infra/environments/staging/terraform-sa-key.json
rm -f infra/environments/production/terraform-sa-key.json

# Remove environment files with secrets
rm -f .env.local
rm -f .env

# Remove log files
rm -f infra/environments/staging/terraform.log
rm -f infra/environments/production/terraform.log
rm -f *.log

# Remove any terraform state files (if any exist)
find . -name "*.tfstate*" -delete

# Remove terraform cache directories
find . -name ".terragrunt-cache" -type d -exec rm -rf {} +
find . -name ".terraform" -type d -exec rm -rf {} +
```

##  Safe Files to Commit

These files are now staged and safe to commit:

-  Documentation files (`*.md`)
-  Infrastructure code (`*.tf`, `*.hcl`)
-  Build scripts (`Makefile`)
-  Security files (`.gitignore`, `SECURITY.md`)
-  Terraform lock files (`.terraform.lock.hcl`)

##  Verify Protection

Check what files are now ignored:

```bash
# See which files are ignored
git status --ignored

# Test if sensitive files would be ignored
touch test-sa-key.json
git status  # Should not show the file
rm test-sa-key.json
```

##  Security Checklist

Before committing, ensure:

- [ ] No `*.json` files containing credentials
- [ ] No `*.log` files with sensitive output  
- [ ] No `.env*` files with secrets
- [ ] No `*.tfstate*` files with infrastructure state
- [ ] No SSH keys (`*.pem`, `*.key`)
- [ ] No kubeconfig files

##  Next Steps

1. **Clean up sensitive files** using the commands above
2. **Commit the changes**:
   ```bash
   git commit -m "feat: add comprehensive security configuration
   
   - Add comprehensive .gitignore for Terraform/GKE project
   - Add security guidelines and best practices
   - Prevent sensitive files from being committed
   - Include documentation for safe repository management"
   ```

3. **Set up environment variables** for sensitive data:
   ```bash
   export TF_VAR_project_id="your-project-id"
   export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account-key.json"
   ```

4. **Use Secret Manager** for application secrets:
   ```bash
   gcloud secrets create app-secret --data-file=secret.txt
   ```

## ⚠ If You Already Committed Sensitive Data

If sensitive files were already committed to Git history:

1. **Use BFG Repo-Cleaner**:
   ```bash
   git clone --mirror https://github.com/your-repo.git
   java -jar bfg.jar --delete-files "*.json" your-repo.git
   cd your-repo.git
   git reflog expire --expire=now --all && git gc --prune=now --aggressive
   git push --force
   ```

2. **Or use git filter-branch**:
   ```bash
   git filter-branch --force --index-filter \
     'git rm --cached --ignore-unmatch terraform-sa-key.json' \
     --prune-empty --tag-name-filter cat -- --all
   ```

3. **Rotate all compromised credentials** immediately

## 📞 Questions?

- Check `SECURITY.md` for detailed security guidelines
- Review `PERMISSION_FIX.md` for authentication issues
- Use `QUICK_START.md` for deployment guidance

---

**Your repository is now properly secured! **
