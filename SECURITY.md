# 🔐 Security Guidelines

This document outlines security best practices for this GKE infrastructure project.

## 🚨 Never Commit These Files

The following files contain sensitive information and should **NEVER** be committed to Git:

### 🔑 Credentials & Keys
- `*.json` - Service account keys
- `*-sa-key.json` - Terraform service account keys  
- `.env*` - Environment files with secrets
- `kubeconfig*` - Kubernetes configuration files
- `*.pem`, `*.key` - SSH keys and certificates

### 🏗️ Terraform State
- `*.tfstate*` - Contains resource IDs and sensitive data
- `terraform.tfvars` - May contain sensitive variable values
- `.terraform/` - Local terraform cache

### 📝 Logs
- `*.log` - May contain sensitive output
- `terraform.log`, `terragrunt.log` - Deployment logs

## ✅ Safe to Commit

These files are safe to commit:
- `*.tf` - Terraform configuration (without hardcoded secrets)
- `*.hcl` - Terragrunt configuration
- `*.md` - Documentation
- `Makefile` - Build scripts
- `.gitignore` - This file itself

## 🛡️ Security Best Practices

### 1. Use Environment Variables
```bash
# Instead of hardcoding in files:
export TF_VAR_project_id="your-project-id"
export GOOGLE_APPLICATION_CREDENTIALS="./sa-key.json"
```

### 2. Use GCP Secret Manager
Store sensitive configuration in GCP Secret Manager:
```bash
# Store secrets
gcloud secrets create db-password --data-file=password.txt

# Access in Terraform
data "google_secret_manager_secret_version" "db_password" {
  secret = "db-password"
}
```

### 3. Use Workload Identity
Instead of service account keys, use Workload Identity for pods:
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: workload-sa
  annotations:
    iam.gke.io/gcp-service-account: gsa-name@project.iam.gserviceaccount.com
```

### 4. Rotate Credentials Regularly
- Service account keys: Every 90 days
- Database passwords: Every 60 days
- API keys: Every 30 days

### 5. Use Least Privilege Access
Grant minimum required permissions:
```bash
# Instead of roles/owner, use specific roles:
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:SA_EMAIL" \
  --role="roles/container.developer"
```

## 🔍 Monitoring Security

### 1. Enable Audit Logging
```yaml
auditConfigs:
- service: allServices
  auditLogConfigs:
  - logType: ADMIN_READ
  - logType: DATA_READ
  - logType: DATA_WRITE
```

### 2. Set Up Alerts
```bash
# Create billing alerts
gcloud alpha billing budgets create \
  --billing-account=BILLING_ACCOUNT_ID \
  --display-name="GKE Security Budget" \
  --budget-amount=100USD
```

### 3. Regular Security Scans
```bash
# Scan for vulnerabilities
gcloud container images scan IMAGE_URL

# Check for exposed secrets
git secrets --scan
```

## 🚨 Incident Response

### If Credentials Are Compromised:

1. **Immediate Actions:**
   ```bash
   # Disable the compromised service account
   gcloud iam service-accounts disable SA_EMAIL
   
   # Delete the compromised key
   gcloud iam service-accounts keys delete KEY_ID --iam-account=SA_EMAIL
   ```

2. **Investigate:**
   ```bash
   # Check audit logs
   gcloud logging read "resource.type=gce_instance" --limit=50
   
   # Check for unauthorized access
   gcloud logging read 'resource.type="gke_cluster"' --limit=50
   ```

3. **Recovery:**
   ```bash
   # Create new service account
   gcloud iam service-accounts create new-sa-name
   
   # Generate new key
   gcloud iam service-accounts keys create new-key.json \
     --iam-account=new-sa-name@PROJECT_ID.iam.gserviceaccount.com
   ```

### If Repository is Compromised:

1. **Remove sensitive data:**
   ```bash
   # Use BFG Repo-Cleaner
   git clone --mirror git://example.com/repo.git
   java -jar bfg.jar --delete-files id_rsa repo.git
   ```

2. **Rotate all credentials** that might have been exposed

3. **Review commit history** for unauthorized changes

## 📋 Security Checklist

Before deployment, ensure:

- [ ] No hardcoded credentials in code
- [ ] All sensitive files in `.gitignore`
- [ ] Service accounts follow least privilege
- [ ] Workload Identity is enabled
- [ ] Audit logging is configured
- [ ] Billing alerts are set up
- [ ] Network policies are in place
- [ ] Private clusters are used
- [ ] Node auto-upgrade is enabled
- [ ] Security patches are applied

## 🔗 Additional Resources

- [GKE Security Best Practices](https://cloud.google.com/kubernetes-engine/docs/how-to/hardening-your-cluster)
- [Terraform Security](https://learn.hashicorp.com/tutorials/terraform/sensitive-variables)
- [Google Cloud Security Command Center](https://cloud.google.com/security-command-center)
- [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes)

## 📞 Reporting Security Issues

If you discover a security vulnerability:
1. **Do NOT** create a public issue
2. Contact the project maintainers directly
3. Provide detailed information about the vulnerability
4. Allow time for remediation before disclosure

---

**Remember: Security is everyone's responsibility! 🛡️**
