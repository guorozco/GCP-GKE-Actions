#  Test Your Deployment

This guide helps you verify that your GKE deployment is working correctly.

##  Deployment Verification

### 1. Check Cluster Status
```bash
# Set your project ID
export TF_VAR_project_id="your-actual-project-id"

# Check staging cluster
gcloud container clusters describe gke-staging \
  --region=us-central1-a \
  --project=$TF_VAR_project_id

# Check production cluster (if deployed)
gcloud container clusters describe gke-production \
  --region=us-east1-b \
  --project=$TF_VAR_project_id
```

### 2. Connect to Cluster
```bash
# Get credentials for staging
gcloud container clusters get-credentials gke-staging \
  --region=us-central1-a \
  --project=$TF_VAR_project_id

# Verify connection
kubectl cluster-info
kubectl get nodes
kubectl get namespaces
```

### 3. Test Basic Functionality
```bash
# Check cluster info
kubectl cluster-info

# View system pods
kubectl get pods -n kube-system

# Check node status
kubectl get nodes -o wide

# Check cluster version
kubectl version
```

##  Deploy Test Application

### 1. Create Test Namespace
```bash
kubectl create namespace test-app
```

### 2. Deploy Nginx Test App
```bash
# Create deployment
cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-test
  namespace: test-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx-test
  template:
    metadata:
      labels:
        app: nginx-test
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
EOF
```

### 3. Expose the Application
```bash
# Create service
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
  namespace: test-app
spec:
  selector:
    app: nginx-test
  ports:
  - port: 80
    targetPort: 80
  type: LoadBalancer
EOF
```

### 4. Test the Application
```bash
# Wait for deployment
kubectl wait --for=condition=available --timeout=300s deployment/nginx-test -n test-app

# Check pods
kubectl get pods -n test-app

# Get service info
kubectl get service nginx-service -n test-app

# Get external IP (may take a few minutes)
kubectl get service nginx-service -n test-app -w
```

### 5. Access the Application
```bash
# Get the external IP
EXTERNAL_IP=$(kubectl get service nginx-service -n test-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Test the application
curl http://$EXTERNAL_IP

# Or open in browser
echo "Open http://$EXTERNAL_IP in your browser"
```

##  Resource Monitoring

### 1. Check Resource Usage
```bash
# Node resource usage
kubectl top nodes

# Pod resource usage
kubectl top pods -n test-app

# Cluster resource usage
kubectl describe nodes
```

### 2. Check Free Tier Compliance
```bash
# Check node types
kubectl get nodes -o wide

# Check resource requests/limits
kubectl describe pods -n test-app

# Verify preemptible instances (for production)
gcloud compute instances list --filter="name~gke-production"
```

##  Troubleshooting Tests

### Common Issues

1. **Pods stuck in Pending**
   ```bash
   kubectl describe pod -n test-app
   kubectl get events -n test-app --sort-by='.lastTimestamp'
   ```

2. **Service has no external IP**
   ```bash
   # Check service status
   kubectl describe service nginx-service -n test-app
   
   # LoadBalancer may take 5-10 minutes to provision
   kubectl get service nginx-service -n test-app -w
   ```

3. **Resource limits exceeded**
   ```bash
   # Check cluster capacity
   kubectl describe nodes
   
   # Check resource quotas
   kubectl describe quota -n test-app
   ```

### Useful Commands
```bash
# Check all resources in namespace
kubectl get all -n test-app

# View logs
kubectl logs deployment/nginx-test -n test-app

# Delete test resources
kubectl delete namespace test-app

# Check cluster events
kubectl get events --sort-by='.lastTimestamp'
```

##  Cost Monitoring

### 1. Check Billing
```bash
# Open billing dashboard
echo "Visit: https://console.cloud.google.com/billing/projects/$TF_VAR_project_id"

# Check current usage
gcloud billing budgets list
```

### 2. Monitor Resource Costs
```bash
# Check compute instances
gcloud compute instances list

# Check persistent disks
gcloud compute disks list

# Check load balancers
gcloud compute forwarding-rules list
```

##  Cleanup Test Resources

### Remove Test Application
```bash
# Delete test namespace
kubectl delete namespace test-app

# Verify cleanup
kubectl get all -n test-app
```

### Scale Down for Cost Savings
```bash
# Scale down test deployments
kubectl scale deployment nginx-test --replicas=0 -n test-app

# Or delete specific resources
kubectl delete deployment nginx-test -n test-app
kubectl delete service nginx-service -n test-app
```

##  Success Checklist

- [ ] Cluster is running and accessible
- [ ] Nodes are in Ready state
- [ ] Can deploy applications
- [ ] LoadBalancer service works
- [ ] Resource usage is within free tier limits
- [ ] Billing shows expected costs
- [ ] Can scale applications up/down
- [ ] Logs are accessible
- [ ] Monitoring is working

##  Next Steps

If all tests pass:

1. **Deploy your real applications**
2. **Set up CI/CD pipelines**
3. **Configure monitoring and alerting**
4. **Implement backup strategies**
5. **Set up proper RBAC**

## 📞 Support

If tests fail:
- Check the [DEPLOYMENT.md](DEPLOYMENT.md) troubleshooting section
- Review the [QUICK_START.md](QUICK_START.md) guide
- Use `make help` for available commands
- Check GCP Console for additional logs and monitoring

---

**Great job testing your deployment! 🎊**

