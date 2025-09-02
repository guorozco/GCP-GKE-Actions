#!/bin/bash

# Test script for Artifact Registry deployment
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Main script
echo -e "${BLUE} Artifact Registry Test Script${NC}"
echo "=================================="

# Check prerequisites
if [ -z "$TF_VAR_project_id" ]; then
    log_error "TF_VAR_project_id not set. Please set it first:"
    echo "export TF_VAR_project_id=\"your-project-id\""
    exit 1
fi

log_info "Project ID: $TF_VAR_project_id"

# Test 1: Check if registries exist
log_info "Testing if registries exist..."
if gcloud artifacts repositories list --project=$TF_VAR_project_id &>/dev/null; then
    log_success "Can access Artifact Registry"
    gcloud artifacts repositories list --project=$TF_VAR_project_id
else
    log_warning "No registries found or access denied"
fi

# Test 2: Configure Docker authentication
log_info "Configuring Docker authentication..."
if gcloud auth configure-docker us-central1-docker.pkg.dev,us-east1-docker.pkg.dev --project=$TF_VAR_project_id; then
    log_success "Docker authentication configured"
else
    log_error "Failed to configure Docker authentication"
    exit 1
fi

# Test 3: Create a test image
log_info "Creating test Docker image..."
cat > Dockerfile.test << EOF
FROM alpine:latest
RUN echo "Hello from Artifact Registry test!" > /hello.txt
CMD cat /hello.txt
EOF

if docker build -t test-image:latest -f Dockerfile.test .; then
    log_success "Test image built successfully"
else
    log_error "Failed to build test image"
    exit 1
fi

# Test 4: Tag and push to staging registry (if it exists)
STAGING_REGISTRY="us-central1-docker.pkg.dev/$TF_VAR_project_id/staging-docker"
if gcloud artifacts repositories describe staging-docker --location=us-central1 --project=$TF_VAR_project_id &>/dev/null; then
    log_info "Testing push to staging registry..."
    
    docker tag test-image:latest $STAGING_REGISTRY/test-image:latest
    
    if docker push $STAGING_REGISTRY/test-image:latest; then
        log_success "Successfully pushed to staging registry"
        
        # Test pull
        docker rmi $STAGING_REGISTRY/test-image:latest
        if docker pull $STAGING_REGISTRY/test-image:latest; then
            log_success "Successfully pulled from staging registry"
        else
            log_error "Failed to pull from staging registry"
        fi
        
        # Clean up test image from registry
        log_info "Cleaning up test image from registry..."
        gcloud artifacts docker images delete $STAGING_REGISTRY/test-image:latest --quiet --project=$TF_VAR_project_id || true
        
    else
        log_error "Failed to push to staging registry"
    fi
else
    log_warning "Staging registry not found - skipping push test"
fi

# Test 5: Test production registry (if it exists)
PRODUCTION_REGISTRY="us-east1-docker.pkg.dev/$TF_VAR_project_id/production-docker"
if gcloud artifacts repositories describe production-docker --location=us-east1 --project=$TF_VAR_project_id &>/dev/null; then
    log_info "Testing push to production registry..."
    
    docker tag test-image:latest $PRODUCTION_REGISTRY/test-image:latest
    
    if docker push $PRODUCTION_REGISTRY/test-image:latest; then
        log_success "Successfully pushed to production registry"
        
        # Clean up test image from registry
        log_info "Cleaning up test image from registry..."
        gcloud artifacts docker images delete $PRODUCTION_REGISTRY/test-image:latest --quiet --project=$TF_VAR_project_id || true
        
    else
        log_error "Failed to push to production registry"
    fi
else
    log_warning "Production registry not found - skipping push test"
fi

# Clean up local images
log_info "Cleaning up local test images..."
docker rmi test-image:latest || true
docker rmi $STAGING_REGISTRY/test-image:latest || true
docker rmi $PRODUCTION_REGISTRY/test-image:latest || true
rm -f Dockerfile.test

# Test 6: Check secret manager integration
log_info "Checking Secret Manager integration..."
if gcloud secrets list --filter="name~staging-docker-config OR name~production-docker-config" --project=$TF_VAR_project_id | grep -q "staging-docker-config\|production-docker-config"; then
    log_success "Secret Manager secrets created"
    gcloud secrets list --filter="name~docker-config" --project=$TF_VAR_project_id
else
    log_warning "No Secret Manager secrets found"
fi

# Test 7: Check service accounts
log_info "Checking service accounts..."
if gcloud iam service-accounts list --filter="displayName~Artifact Registry" --project=$TF_VAR_project_id | grep -q "Artifact Registry"; then
    log_success "Artifact Registry service accounts created"
    gcloud iam service-accounts list --filter="displayName~Artifact Registry" --project=$TF_VAR_project_id
else
    log_warning "No Artifact Registry service accounts found"
fi

# Summary
echo ""
echo -e "${GREEN} Test completed!${NC}"
echo "=================================="
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Deploy your registries: make deploy-registry-staging"
echo "2. Build and push your images"
echo "3. Deploy to GKE clusters"
echo ""
echo -e "${BLUE}Useful commands:${NC}"
echo "• make list-registries        # List all registries"
echo "• make list-images           # List all images"
echo "• make configure-docker-all  # Configure Docker auth"
echo ""
echo -e "${GREEN}Happy containerizing! ${NC}"
