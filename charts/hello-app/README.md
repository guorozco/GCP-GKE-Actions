# Hello World Flask App - Helm Chart


A production-ready Helm chart for deploying the Hello World Flask application to Kubernetes/GKE.

## Chart Information

- **Chart Version**: 1.0.0
- **App Version**: 1.0.0
- **Kubernetes**: Compatible with 1.19+
- **Helm**: Compatible with 3.0+

## Features

- **Environment-aware deployments** (staging/production)
- **Horizontal Pod Autoscaling** (HPA)
- **Pod Disruption Budget** (PDB) for high availability
- **Configurable service types** (ClusterIP/LoadBalancer)
- **Resource optimization** per environment
- **Health checks** and readiness probes
- **Security contexts** and non-root containers
- **Ingress support** (optional)

## Chart Structure

```
charts/hello-app/
├── Chart.yaml                 # Chart metadata
├── values.yaml               # Default values
├── values-staging.yaml       # Staging overrides
├── values-production.yaml    # Production overrides
├── templates/
│   ├── _helpers.tpl          # Template helpers
│   ├── deployment.yaml       # Deployment template
│   ├── service.yaml         # Service template
│   ├── hpa.yaml             # HorizontalPodAutoscaler
│   ├── ingress.yaml         # Ingress template
│   ├── pdb.yaml             # PodDisruptionBudget
│   ├── serviceaccount.yaml  # ServiceAccount
│   └── NOTES.txt           # Post-install notes
└── README.md               # This file
```

## Quick Start

### Prerequisites

- Helm 3.0+
- Kubernetes 1.19+
- GKE cluster with Artifact Registry access

### Basic Installation

```bash
# Install with default values
helm install hello-app ./charts/hello-app

# Install for staging
helm install hello-app-staging ./charts/hello-app \
  -f ./charts/hello-app/values-staging.yaml

# Install for production
helm install hello-app-production ./charts/hello-app \
  -f ./charts/hello-app/values-production.yaml
```

### Advanced Installation

```bash
# Install with custom image tag
helm install hello-app-staging ./charts/hello-app \
  -f ./charts/hello-app/values-staging.yaml \
  --set image.tag=v1.2.0

# Install with custom replica count
helm install hello-app-staging ./charts/hello-app \
  -f ./charts/hello-app/values-staging.yaml \
  --set replicaCount=3

# Install in a specific namespace
helm install hello-app-staging ./charts/hello-app \
  -f ./charts/hello-app/values-staging.yaml \
  --namespace my-namespace --create-namespace
```

## Configuration

### Key Configurable Parameters

| Parameter | Description | Default | Staging | Production |
|-----------|-------------|---------|---------|------------|
| `replicaCount` | Number of replicas | `2` | `2` | `4` |
| `image.repository` | Image repository | `us-central1-docker.pkg.dev/...` | staging registry | production registry |
| `image.tag` | Image tag | `latest` | `latest` | `v1.0.0` |
| `service.type` | Service type | `ClusterIP` | `ClusterIP` | `LoadBalancer` |
| `service.port` | Service port | `80` | `80` | `80` |
| `resources.requests.memory` | Memory request | `64Mi` | `64Mi` | `128Mi` |
| `resources.limits.memory` | Memory limit | `128Mi` | `128Mi` | `256Mi` |
| `autoscaling.minReplicas` | Min HPA replicas | `1` | `1` | `2` |
| `autoscaling.maxReplicas` | Max HPA replicas | `5` | `5` | `10` |

### Environment Configurations

#### Staging Environment
- **Purpose**: Testing and validation
- **Replicas**: 2 (1-5 with HPA)
- **Service**: ClusterIP (internal access)
- **Resources**: Conservative (64Mi/128Mi memory)
- **Registry**: Staging Artifact Registry

#### Production Environment
- **Purpose**: Live user traffic
- **Replicas**: 4 (2-10 with HPA)
- **Service**: LoadBalancer (external access)
- **Resources**: Higher performance (128Mi/256Mi memory)
- **Registry**: Production Artifact Registry
- **PDB**: Ensures 2 pods always available

## Environment Comparison

| Feature | Default | Staging | Production |
|---------|---------|---------|------------|
| **Replicas** | 2 | 2 | 4 |
| **Service Type** | ClusterIP | ClusterIP | LoadBalancer |
| **Memory Request** | 64Mi | 64Mi | 128Mi |
| **Memory Limit** | 128Mi | 128Mi | 256Mi |
| **CPU Request** | 50m | 50m | 100m |
| **CPU Limit** | 100m | 100m | 200m |
| **HPA Min** | 1 | 1 | 2 |
| **HPA Max** | 5 | 5 | 10 |
| **PDB Min Available** | 1 | 1 | 2 |

## Customization Examples

### Custom Image and Resources

```yaml
# custom-values.yaml
image:
  repository: my-registry/hello-app
  tag: "v2.0.0"

replicaCount: 3

resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
  limits:
    memory: "256Mi"
    cpu: "200m"

service:
  type: LoadBalancer
  annotations:
    cloud.google.com/load-balancer-type: "Internal"
```

```bash
helm install my-app ./charts/hello-app -f custom-values.yaml
```

### Enable Ingress

```yaml
# ingress-values.yaml
service:
  type: ClusterIP

ingress:
  enabled: true
  className: "gce"
  annotations:
    kubernetes.io/ingress.global-static-ip-name: "my-static-ip"
  hosts:
    - host: my-app.example.com
      paths:
        - path: /
          pathType: Prefix
```

## Testing and Validation

### Validate Chart

```bash
# Lint the chart
helm lint ./charts/hello-app

# Test template rendering
helm template hello-app ./charts/hello-app --debug --dry-run

# Test with staging values
helm template hello-app-staging ./charts/hello-app \
  -f ./charts/hello-app/values-staging.yaml --debug --dry-run
```

### Deployment Testing

```bash
# Install in test mode
helm install hello-app-test ./charts/hello-app --dry-run

# Install and test
helm install hello-app-test ./charts/hello-app
kubectl get pods,svc,hpa

# Test application
kubectl port-forward svc/hello-app-test-service 8080:80
curl http://localhost:8080/api/health
```

## Monitoring

### Health Checks

The application includes built-in health checks:

- **Liveness Probe**: `/api/health` (ensures container is running)
- **Readiness Probe**: `/api/health` (ensures container is ready for traffic)

### Useful Commands

```bash
# Check deployment status
kubectl get deployments
kubectl get pods -l app=hello-world-flask

# Check service and external IP
kubectl get services
kubectl get ingress

# Check horizontal pod autoscaler
kubectl get hpa

# View application logs
kubectl logs -l app=hello-world-flask --tail=100

# Scale manually
kubectl scale deployment/hello-app --replicas=5
```

## Upgrades

### Upgrade to New Version

```bash
# Upgrade staging with new image
helm upgrade hello-app-staging ./charts/hello-app \
  -f ./charts/hello-app/values-staging.yaml \
  --set image.tag=v1.1.0

# Upgrade production
helm upgrade hello-app-production ./charts/hello-app \
  -f ./charts/hello-app/values-production.yaml \
  --set image.tag=v1.1.0
```

### Rollback

```bash
# Rollback to previous version
helm rollback hello-app-staging 1

# Check rollback history
helm history hello-app-staging
```

## Cleanup

```bash
# Uninstall release
helm uninstall hello-app-staging

# Delete namespace (if created)
kubectl delete namespace my-namespace
```

## Troubleshooting

### Common Issues

1. **Image Pull Errors**
   - Ensure Artifact Registry authentication is configured
   - Check image repository and tag values

2. **LoadBalancer Pending**
   - External IP assignment may take 2-5 minutes
   - Check GCP quotas and permissions

3. **Pod Not Ready**
   - Check health check endpoints are working
   - Verify resource limits are sufficient

4. **HPA Not Scaling**
   - Ensure metrics-server is installed
   - Check resource requests are defined

### Debug Commands

```bash
# Describe deployment
kubectl describe deployment hello-app

# Check pod events
kubectl describe pod <pod-name>

# View detailed logs
kubectl logs <pod-name> --previous

# Check HPA status
kubectl describe hpa hello-app-hpa
```

## Additional Resources

- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [Flask Application Code](../../app/)

## Contributing

1. Fork the repository
2. Make changes to the chart
3. Test with `helm lint` and `helm template`
4. Submit a pull request

## License

MIT License - see LICENSE file for details.
