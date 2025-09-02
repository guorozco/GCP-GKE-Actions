# 🎯 Kubectl Commands for GKE Staging Cluster

## 🔗 Connect to Staging Cluster

```bash
# Set project ID
export TF_VAR_project_id="test-demo-123456-guillermo"

# Get cluster credentials
gcloud container clusters get-credentials gke-staging \
  --region=us-central1 \
  --project=$TF_VAR_project_id

# Verify connection
kubectl cluster-info
```

## 📊 Node Status Commands

### Basic Node Information
```bash
# List all nodes (may be empty in Autopilot if no workloads)
kubectl get nodes

# Detailed node information
kubectl get nodes -o wide

# Node resource usage (requires metrics-server)
kubectl top nodes

# Describe specific node
kubectl describe node NODE_NAME
```

### Autopilot-Specific Node Behavior
```bash
# Autopilot only creates nodes when pods need them
# To see node creation:

# 1. Deploy a test workload
kubectl create deployment test-nginx --image=nginx:alpine

# 2. Watch nodes being created (takes 1-3 minutes)
kubectl get nodes -w

# 3. Clean up
kubectl delete deployment test-nginx
```

## 🔍 Cluster Monitoring

### Cluster Status
```bash
# Cluster information
kubectl cluster-info

# All namespaces
kubectl get namespaces

# System pods status
kubectl get pods --all-namespaces

# Events (helpful for troubleshooting)
kubectl get events --sort-by='.lastTimestamp'
```

### Resource Usage
```bash
# Pod resource usage
kubectl top pods --all-namespaces

# Node capacity and allocatable resources
kubectl describe nodes

# Cluster resource quotas
kubectl describe quota --all-namespaces
```

## 🚀 Workload Management

### Deploy Applications
```bash
# Create a deployment
kubectl create deployment my-app --image=nginx:alpine

# Scale deployment
kubectl scale deployment my-app --replicas=3

# Expose deployment
kubectl expose deployment my-app --port=80 --type=LoadBalancer

# Check deployment status
kubectl get deployments
kubectl get pods
kubectl get services
```

### Monitor Applications
```bash
# Watch pods
kubectl get pods -w

# Pod logs
kubectl logs deployment/my-app

# Describe pods for troubleshooting
kubectl describe pod POD_NAME

# Execute commands in pod
kubectl exec -it POD_NAME -- /bin/bash
```

## 🔧 Troubleshooting

### Common Issues
```bash
# Check if nodes are available
kubectl get nodes

# Check pod events
kubectl describe pod POD_NAME

# Check cluster events
kubectl get events --sort-by='.lastTimestamp' | tail -20

# Check system pod status
kubectl get pods -n kube-system
```

### Autopilot Specific
```bash
# Check if Autopilot is enabled
gcloud container clusters describe gke-staging \
  --region=us-central1 \
  --project=$TF_VAR_project_id \
  --format="value(autopilot.enabled)"

# Check node pools (Autopilot manages these automatically)
gcloud container node-pools list \
  --cluster=gke-staging \
  --region=us-central1 \
  --project=$TF_VAR_project_id
```

## 🧹 Cleanup Commands

### Remove Workloads
```bash
# Delete deployment
kubectl delete deployment DEPLOYMENT_NAME

# Delete service
kubectl delete service SERVICE_NAME

# Delete all resources in namespace
kubectl delete all --all -n NAMESPACE_NAME

# Delete namespace
kubectl delete namespace NAMESPACE_NAME
```

### Force Node Scale Down
```bash
# In Autopilot, nodes automatically scale down when not needed
# You can speed this up by ensuring no pods are running:

# Check what's running
kubectl get pods --all-namespaces

# Delete unnecessary pods
kubectl delete deployment DEPLOYMENT_NAME
```

## 📊 Monitoring and Metrics

### Resource Monitoring
```bash
# Install metrics-server (if not available)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Check resource usage
kubectl top nodes
kubectl top pods --all-namespaces

# Check resource requests and limits
kubectl describe pods | grep -E "Requests|Limits"
```

### Cost Monitoring
```bash
# Check current node count
kubectl get nodes | wc -l

# Check pod distribution
kubectl get pods -o wide --all-namespaces

# Monitor via GCloud
gcloud container clusters describe gke-staging \
  --region=us-central1 \
  --project=$TF_VAR_project_id \
  --format="table(name,status,currentNodeCount,autopilot.enabled)"
```

## 🔐 Security Commands

### RBAC and Permissions
```bash
# Check current context
kubectl config current-context

# Check permissions
kubectl auth can-i --list

# Check service accounts
kubectl get serviceaccounts --all-namespaces

# Check cluster roles
kubectl get clusterroles
```

### Network Policies
```bash
# Check network policies
kubectl get networkpolicies --all-namespaces

# Test connectivity
kubectl exec -it POD_NAME -- nslookup kubernetes.default.svc.cluster.local
```

## 🆘 Emergency Commands

### Quick Health Check
```bash
#!/bin/bash
echo "=== GKE Staging Cluster Health Check ==="
echo "Cluster Info:"
kubectl cluster-info

echo -e "\nNodes:"
kubectl get nodes

echo -e "\nSystem Pods:"
kubectl get pods -n kube-system

echo -e "\nRecent Events:"
kubectl get events --sort-by='.lastTimestamp' | tail -10
```

### Debug Pod Not Starting
```bash
# Check pod status
kubectl get pods

# Describe problematic pod
kubectl describe pod POD_NAME

# Check events
kubectl get events --field-selector involvedObject.name=POD_NAME

# Check logs
kubectl logs POD_NAME

# Check node resources
kubectl describe nodes
```

## 💡 Tips for Autopilot

1. **Nodes appear only when needed** - Don't worry if `kubectl get nodes` shows nothing
2. **Node provisioning takes 1-3 minutes** - Be patient when deploying workloads
3. **Cost optimization** - Autopilot automatically scales down unused nodes
4. **Resource requests** - Always specify resource requests for better scheduling
5. **Monitoring** - Use `kubectl get events` to monitor node provisioning

---

**Remember**: GKE Autopilot manages nodes automatically, so you focus on applications! 🚀
