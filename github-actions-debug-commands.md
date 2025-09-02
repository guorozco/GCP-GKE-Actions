# GitHub Actions Debugging Commands

## When Pods Are Not Ready

### 1. Check All Deployments
```bash
kubectl get deployments -o wide
```

### 2. Check Pod Status
```bash
kubectl get pods -o wide
```

### 3. Check Pod Labels
```bash
kubectl get pods --show-labels
```

### 4. Check Specific Helm Deployment Pods
```bash
# For staging
kubectl get pods -l app.kubernetes.io/instance=hello-app-staging

# For production  
kubectl get pods -l app.kubernetes.io/instance=hello-app-production
```

### 5. Describe Problematic Pods
```bash
kubectl describe pod <pod-name>
```

### 6. Check Pod Logs
```bash
kubectl logs <pod-name>
```

### 7. Check Services
```bash
kubectl get services
```

### 8. Check Helm Releases
```bash
helm list
```

### 9. Clean Up Old Deployments Manually
```bash
# Remove old deployments that might conflict
kubectl delete deployment hello-world-flask --ignore-not-found=true
kubectl delete service hello-world-flask-service --ignore-not-found=true
kubectl delete hpa hello-world-flask-hpa --ignore-not-found=true

# Check what's left
kubectl get all
```

### 10. Verify Helm Service Names
```bash
# Helm creates services with this pattern: <release-name>-<chart-name>
# For staging: hello-app-staging-hello-app
# For production: hello-app-production-hello-app

kubectl get service hello-app-staging-hello-app
kubectl get service hello-app-production-hello-app
```

## Common Issues and Solutions

### Issue: Multiple Deployments Running
**Symptoms:** Old pods timing out, new pods ready
**Solution:** Clean up old deployments before running new ones

### Issue: Wrong Service Name in Port-Forward
**Symptoms:** "service not found" errors
**Solution:** Use Helm-generated service names: `<release-name>-<chart-name>`

### Issue: Pods Not Ready Due to Health Checks
**Symptoms:** Pods stuck in "Not Ready" state
**Solution:** Check readiness probe configuration and app health endpoint

### Issue: Resource Constraints
**Symptoms:** Pods pending or crashing
**Solution:** Check resource limits and cluster capacity

## GitHub Actions Specific Debugging

### In GitHub Actions Runner
```bash
# List all resources
kubectl get all

# Check events for errors
kubectl get events --sort-by=.metadata.creationTimestamp

# Check if service account has permissions
kubectl auth can-i get pods
kubectl auth can-i create deployments
```

### Test Connectivity Locally
```bash
# Port forward to test app
kubectl port-forward service/hello-app-staging-hello-app 8080:80

# Test health endpoint
curl http://localhost:8080/api/health
```

## Prevention

1. **Always clean up old deployments** before deploying new ones
2. **Use consistent labeling** between deploy methods (Helm vs kubectl)
3. **Test service names** before using in port-forward commands
4. **Monitor resource usage** to prevent capacity issues
5. **Use proper readiness probes** to ensure pods are actually ready
