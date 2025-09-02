# Hello World Flask App

A simple Flask web application demonstrating deployment to Google Kubernetes Engine (GKE) via Google Artifact Registry.

## Features

- **Beautiful Web Interface** with responsive design
- **Health Check Endpoints** for Kubernetes monitoring
- **Environment Awareness** (development/staging/production)
- **JSON API Endpoints** for programmatic access
- **Docker Optimized** with security best practices
- **Kubernetes Ready** with health checks and resource limits

## Prerequisites

- Docker installed and running
- Google Cloud SDK (`gcloud`) configured
- `kubectl` installed
- Artifact Registry authentication configured

## Quick Start

### 1. Test Locally

```bash
# Run locally (without Docker)
python3 app.py

# Or with Docker
docker build -t hello-world-flask .
docker run -p 5000:5000 hello-world-flask
```

Visit `http://localhost:5000` to see the app.

### 2. Deploy to GKE

```bash
# Deploy to staging
./deploy.sh

# Deploy specific version to staging
./deploy.sh v1.0.0

# Deploy to production
./deploy.sh v1.0.0 production
```

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | Main web interface |
| `/api/health` | GET | Health check for Kubernetes |
| `/api/info` | GET | Application information (JSON) |
| `/api/version` | GET | Version information |
| `/api/hello/<name>` | GET | Personalized greeting |

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Developer     │───▶│ Artifact Registry │───▶│   GKE Cluster   │
│                 │    │                  │    │                 │
│ 1. Build Image  │    │ 2. Store Image   │    │ 3. Deploy Pod   │
│ 2. Push Image   │    │ 3. Security Scan │    │ 4. Load Balance │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## Security Features

- **Non-root user** for container security
- **Resource limits** to prevent resource abuse
- **Health checks** for automatic recovery
- **Environment isolation** between staging/production
- **Vulnerability scanning** via Artifact Registry

## Deployment Environments

### Staging
- **Registry**: `us-central1-docker.pkg.dev/PROJECT_ID/staging-docker`
- **Cluster**: `gke-staging` (us-central1)
- **Replicas**: 2
- **Resources**: 64Mi memory, 50m CPU

### Production
- **Registry**: `us-east1-docker.pkg.dev/PROJECT_ID/production-docker`
- **Cluster**: `gke-production` (us-east1)
- **Replicas**: 3
- **Resources**: 128Mi memory, 100m CPU

## Monitoring

### Health Checks
```bash
# Check application health
curl http://YOUR_EXTERNAL_IP/api/health

# Get detailed application info
curl http://YOUR_EXTERNAL_IP/api/info
```

### Kubernetes Commands
```bash
# Check pod status
kubectl get pods

# View application logs
kubectl logs deployment/hello-world-flask

# Check service status
kubectl get service hello-world-flask-service

# Scale the application
kubectl scale deployment hello-world-flask --replicas=5

# Check horizontal pod autoscaler
kubectl get hpa
```

## CI/CD Integration

This app is designed to work with CI/CD pipelines:

### GitHub Actions Example
```yaml
name: Deploy to GKE
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - uses: google-github-actions/auth@v1
      with:
        credentials_json: ${{ secrets.GCP_SA_KEY }}
    - name: Deploy to staging
      run: |
        cd app
        ./deploy.sh ${{ github.sha }} staging
```

## Dynamic Deployment Architecture

This app uses **dynamic Kubernetes manifest generation** instead of static YAML files:

- **Environment-aware**: Automatically configures resources based on staging/production
- **Flexible**: Easy to modify configurations without editing multiple files  
- **Version-aware**: Dynamically injects the correct image tags and versions
- **Resource-optimized**: Different CPU/memory limits per environment

### Environment Configurations

| Environment | Replicas | Memory | CPU | HPA Range |
|-------------|----------|---------|-----|-----------|
| **Staging** | 2 | 64Mi/128Mi | 50m/100m | 1-5 |
| **Production** | 3 | 128Mi/256Mi | 100m/200m | 2-10 |

## Troubleshooting

### Common Issues

1. **Image pull errors**:
   ```bash
   # Check Artifact Registry authentication
   gcloud auth configure-docker us-central1-docker.pkg.dev
   ```

2. **Pod not starting**:
   ```bash
   # Check pod events
   kubectl describe pod $(kubectl get pods -l app=hello-world-flask -o name | head -1)
   ```

3. **Service not accessible**:
   ```bash
   # Check if external IP is assigned
   kubectl get service hello-world-flask-service
   
   # If pending, wait a few minutes for GCP to assign IP
   ```

4. **Health check failures**:
   ```bash
   # Check application logs
   kubectl logs deployment/hello-world-flask --tail=50
   ```

5. **Cleanup/Deletion**:
   ```bash
   # Delete all app resources using labels
   kubectl delete deployment,service,hpa -l app=hello-world-flask
   ```

## Scaling

The application includes horizontal pod autoscaling (HPA):

- **Staging**: 1-5 replicas based on CPU/memory usage
- **Production**: 2-10 replicas based on CPU/memory usage
- **Metrics**: CPU > 70%, Memory > 80% triggers scaling

```bash
# Check current scaling status
kubectl get hpa

# Manual scaling
kubectl scale deployment hello-world-flask --replicas=3
```

## Development

### Local Development
```bash
# Install dependencies
pip install -r requirements.txt

# Run in development mode
export ENVIRONMENT=development
python app.py
```

### Building Images
```bash
# Build for testing
docker build -t hello-world-flask:test .

# Test the container
docker run -p 5000:5000 -e ENVIRONMENT=test hello-world-flask:test
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `ENVIRONMENT` | `development` | Application environment |
| `APP_VERSION` | `1.0.0` | Application version |
| `PORT` | `5000` | HTTP port |

## Next Steps

1. **Add a database** (Cloud SQL)
2. **Implement authentication** (Google IAM)
3. **Add monitoring** (Cloud Monitoring)
4. **Set up logging** (Cloud Logging)
5. **Add TLS/SSL** (Google-managed certificates)

## License

MIT License - feel free to use this as a starting point for your own applications!

---

**Happy coding!**
