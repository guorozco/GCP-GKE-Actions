#!/bin/bash

# Deploy Hello World Flask App to GKE via Artifact Registry
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ID="test-demo-123456-guillermo"
APP_NAME="hello-world-flask"
VERSION="${1:-latest}"
ENVIRONMENT="${2:-staging}"

# Registry URLs
STAGING_REGISTRY="us-central1-docker.pkg.dev/$PROJECT_ID/staging-docker"
PRODUCTION_REGISTRY="us-east1-docker.pkg.dev/$PROJECT_ID/production-docker"

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_header() {
    echo -e "${PURPLE}$1${NC}"
    echo -e "$(printf '%.0s=' {1..50})"
}

# Main deployment script
main() {
    log_header " Hello World Flask App Deployment"
    
    # Validate environment
    if [[ "$ENVIRONMENT" != "staging" && "$ENVIRONMENT" != "production" ]]; then
        log_error "Environment must be 'staging' or 'production'"
        exit 1
    fi
    
    # Set registry based on environment
    if [[ "$ENVIRONMENT" == "staging" ]]; then
        REGISTRY=$STAGING_REGISTRY
        CLUSTER_NAME="gke-staging"
        CLUSTER_REGION="us-central1"
    else
        REGISTRY=$PRODUCTION_REGISTRY
        CLUSTER_NAME="gke-production"
        CLUSTER_REGION="us-east1"
    fi
    
    IMAGE_TAG="$REGISTRY/$APP_NAME:$VERSION"
    
    log_info "Environment: $ENVIRONMENT"
    log_info "Registry: $REGISTRY"
    log_info "Image: $IMAGE_TAG"
    log_info "Cluster: $CLUSTER_NAME ($CLUSTER_REGION)"
    
    # Step 1: Build Docker image
    log_header " Building Docker Image"
    log_info "Building $APP_NAME:$VERSION..."
    
    if docker build -t "$APP_NAME:$VERSION" .; then
        log_success "Docker image built successfully"
    else
        log_error "Failed to build Docker image"
        exit 1
    fi
    
    # Step 2: Tag for registry
    log_header " Tagging for Artifact Registry"
    log_info "Tagging as $IMAGE_TAG..."
    
    if docker tag "$APP_NAME:$VERSION" "$IMAGE_TAG"; then
        log_success "Image tagged for registry"
    else
        log_error "Failed to tag image"
        exit 1
    fi
    
    # Step 3: Push to Artifact Registry
    log_header "⬆ Pushing to Artifact Registry"
    log_info "Pushing $IMAGE_TAG..."
    
    if docker push "$IMAGE_TAG"; then
        log_success "Image pushed to Artifact Registry"
    else
        log_error "Failed to push image"
        exit 1
    fi
    
    # Step 4: Get GKE credentials
    log_header " Connecting to GKE Cluster"
    log_info "Getting credentials for $CLUSTER_NAME..."
    
    if gcloud container clusters get-credentials "$CLUSTER_NAME" \
        --region="$CLUSTER_REGION" \
        --project="$PROJECT_ID"; then
        log_success "Connected to GKE cluster"
    else
        log_error "Failed to connect to GKE cluster"
        exit 1
    fi
    
    # Step 5: Generate Kubernetes manifests
    log_header " Generating Kubernetes Manifests"
    
    # Set environment-specific configuration
    if [[ "$ENVIRONMENT" == "staging" ]]; then
        REPLICAS=2
        MIN_REPLICAS=1
        MAX_REPLICAS=5
        MEMORY_REQUEST="64Mi"
        MEMORY_LIMIT="128Mi"
        CPU_REQUEST="50m"
        CPU_LIMIT="100m"
    else
        REPLICAS=3
        MIN_REPLICAS=2
        MAX_REPLICAS=10
        MEMORY_REQUEST="128Mi"
        MEMORY_LIMIT="256Mi"
        CPU_REQUEST="100m"
        CPU_LIMIT="200m"
    fi
    
    log_info "Generating manifests for environment: $ENVIRONMENT"
    log_info "Image: $IMAGE_TAG"
    log_info "Replicas: $REPLICAS"
    
    # Step 6: Create and apply Kubernetes manifests
    log_header " Deploying to Kubernetes"
    log_info "Creating and applying Kubernetes manifests..."
    
    # Generate and apply manifests inline
    if kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-world-flask
  namespace: default
  labels:
    app: hello-world-flask
    environment: $ENVIRONMENT
spec:
  replicas: $REPLICAS
  selector:
    matchLabels:
      app: hello-world-flask
  template:
    metadata:
      labels:
        app: hello-world-flask
        environment: $ENVIRONMENT
    spec:
      containers:
      - name: flask-app
        image: $IMAGE_TAG
        ports:
        - containerPort: 5000
          name: http
        env:
        - name: ENVIRONMENT
          value: "$ENVIRONMENT"
        - name: APP_VERSION
          value: "$VERSION"
        - name: PORT
          value: "5000"
        resources:
          requests:
            memory: "$MEMORY_REQUEST"
            cpu: "$CPU_REQUEST"
          limits:
            memory: "$MEMORY_LIMIT"
            cpu: "$CPU_LIMIT"
        livenessProbe:
          httpGet:
            path: /api/health
            port: 5000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /api/health
            port: 5000
          initialDelaySeconds: 5
          periodSeconds: 5
        imagePullPolicy: Always
      restartPolicy: Always

---
apiVersion: v1
kind: Service
metadata:
  name: hello-world-flask-service
  namespace: default
  labels:
    app: hello-world-flask
spec:
  selector:
    app: hello-world-flask
  ports:
  - port: 80
    targetPort: 5000
    protocol: TCP
    name: http
  type: LoadBalancer

---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: hello-world-flask-hpa
  namespace: default
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: hello-world-flask
  minReplicas: $MIN_REPLICAS
  maxReplicas: $MAX_REPLICAS
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
EOF
    then
        log_success "Kubernetes deployment applied"
    else
        log_error "Failed to apply Kubernetes deployment"
        exit 1
    fi
    
    # Step 7: Wait for deployment to be ready
    log_header " Waiting for Deployment"
    log_info "Waiting for pods to be ready..."
    
    if kubectl wait --for=condition=available --timeout=300s deployment/hello-world-flask; then
        log_success "Deployment is ready!"
    else
        log_warning "Deployment took longer than expected"
    fi
    
    # Step 8: Get service information
    log_header " Service Information"
    
    # Get service details
    SERVICE_IP=$(kubectl get service hello-world-flask-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")
    
    if [[ "$SERVICE_IP" == "pending" || -z "$SERVICE_IP" ]]; then
        log_info "External IP is still being assigned..."
        log_info "Run this command to check: kubectl get service hello-world-flask-service"
        log_info "Getting external IP (this may take a few minutes)..."
        kubectl get service hello-world-flask-service -w &
        WATCH_PID=$!
        sleep 30
        kill $WATCH_PID 2>/dev/null || true
        SERVICE_IP=$(kubectl get service hello-world-flask-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")
    fi
    
    # Display deployment information
    log_success "Deployment completed successfully!"
    echo ""
    echo -e "${GREEN} Deployment Summary:${NC}"
    echo "• Environment: $ENVIRONMENT"
    echo "• Image: $IMAGE_TAG"
    echo "• Cluster: $CLUSTER_NAME ($CLUSTER_REGION)"
    echo "• Replicas: $REPLICAS"
    echo "• Resources: ${MEMORY_REQUEST}/${MEMORY_LIMIT} memory, ${CPU_REQUEST}/${CPU_LIMIT} CPU"
    
    if [[ "$SERVICE_IP" != "pending" && -n "$SERVICE_IP" ]]; then
        echo "• External IP: $SERVICE_IP"
        echo ""
        echo -e "${BLUE} Access your app:${NC}"
        echo "• Main page: http://$SERVICE_IP"
        echo "• Health check: http://$SERVICE_IP/api/health"
        echo "• App info: http://$SERVICE_IP/api/info"
        echo "• Version: http://$SERVICE_IP/api/version"
    else
        echo "• External IP: Still being assigned..."
        echo ""
        echo -e "${YELLOW} To get the external IP when ready:${NC}"
        echo "kubectl get service hello-world-flask-service"
    fi
    
    echo ""
    echo -e "${BLUE} Useful commands:${NC}"
    echo "• Check pods: kubectl get pods -l app=hello-world-flask"
    echo "• Check service: kubectl get service hello-world-flask-service"
    echo "• View logs: kubectl logs deployment/hello-world-flask"
    echo "• Scale app: kubectl scale deployment hello-world-flask --replicas=3"
    echo "• Delete app: kubectl delete deployment,service,hpa -l app=hello-world-flask"
}

# Help function
show_help() {
    echo "Usage: $0 [VERSION] [ENVIRONMENT]"
    echo ""
    echo "Arguments:"
    echo "  VERSION      Image version tag (default: latest)"
    echo "  ENVIRONMENT  Target environment: staging|production (default: staging)"
    echo ""
    echo "Examples:"
    echo "  $0                    # Deploy latest to staging"
    echo "  $0 v1.0.0             # Deploy v1.0.0 to staging"
    echo "  $0 v1.0.0 production  # Deploy v1.0.0 to production"
    echo ""
    echo "Prerequisites:"
    echo "  • Docker installed and running"
    echo "  • gcloud configured and authenticated"
    echo "  • kubectl installed"
    echo "  • Artifact Registry authentication configured"
}

# Check arguments
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
    exit 0
fi

# Run main function
main
