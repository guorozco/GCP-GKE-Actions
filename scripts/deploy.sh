#!/bin/bash

# Free Tier Optimized GKE Deployment Script
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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

log_header() {
    echo -e "${PURPLE}$1${NC}"
    echo -e "${CYAN}$(printf '%.0s=' {1..50})${NC}"
}

# Main script
echo -e "${PURPLE}🚀 Free Tier Optimized GKE Deployment${NC}"
echo -e "${CYAN}======================================${NC}"

# Environment selection
if [ -z "$1" ]; then
    echo -e "${YELLOW}Select environment to deploy:${NC}"
    echo "1) staging (Autopilot - most cost-effective)"
    echo "2) production (Standard - more control)"
    echo "3) both (staging first, then production)"
    read -p "Enter choice [1-3]: " choice
    
    case $choice in
        1) ENVIRONMENT="staging" ;;
        2) ENVIRONMENT="production" ;;
        3) ENVIRONMENT="both" ;;
        *) log_error "Invalid choice. Exiting." && exit 1 ;;
    esac
else
    ENVIRONMENT="$1"
fi

# Check prerequisites
log_header "Checking Prerequisites"

if [ -z "$TF_VAR_project_id" ]; then
    log_error "TF_VAR_project_id not set. Please run './scripts/setup.sh' first."
    exit 1
fi

log_info "Project ID: $TF_VAR_project_id"

# Verify authentication
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    log_error "Not authenticated with gcloud. Please run 'gcloud auth login'"
    exit 1
fi

log_success "Prerequisites checked"

# Function to deploy environment
deploy_environment() {
    local env=$1
    local env_type
    
    if [ "$env" = "staging" ]; then
        env_type="Autopilot (Cost-Optimized)"
    else
        env_type="Standard (More Control)"
    fi
    
    log_header "Deploying $env Environment - $env_type"
    
    cd "infra/environments/$env"
    
    # Initialize Terragrunt
    log_info "Initializing Terragrunt..."
    terragrunt init
    
    # Generate plan
    log_info "Generating deployment plan..."
    terragrunt plan -out=tfplan
    
    # Show cost estimate
    log_header "Cost Estimate for $env"
    if [ "$env" = "staging" ]; then
        echo -e "${GREEN}Staging (Autopilot):${NC}"
        echo "  • Mode: GKE Autopilot"
        echo "  • Region: us-central1-a"
        echo "  • Estimated cost: \$0-10/month"
        echo "  • Features: Preemptible nodes, minimal resources"
    else
        echo -e "${GREEN}Production (Standard):${NC}"
        echo "  • Mode: Standard GKE"
        echo "  • Instance: 1x e2-small (preemptible)"
        echo "  • Region: us-east1-b"
        echo "  • Estimated cost: \$15-30/month"
        echo "  • Features: More control, custom networking"
    fi
    
    # Confirm deployment
    echo -e "${YELLOW}Do you want to proceed with deployment? (y/n):${NC}"
    read -r confirm
    
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        log_warning "Deployment cancelled"
        cd ../../..
        return 1
    fi
    
    # Apply changes
    log_info "Applying Terraform changes..."
    terragrunt apply tfplan
    
    # Get cluster credentials
    log_info "Getting cluster credentials..."
    if [ "$env" = "staging" ]; then
        gcloud container clusters get-credentials gke-staging \
            --region=us-central1-a \
            --project="$TF_VAR_project_id"
    else
        gcloud container clusters get-credentials gke-production \
            --region=us-east1-b \
            --project="$TF_VAR_project_id"
    fi
    
    # Verify deployment
    log_info "Verifying deployment..."
    kubectl cluster-info
    kubectl get nodes 2>/dev/null || echo "No nodes shown (normal for Autopilot)"
    
    log_success "$env environment deployed successfully!"
    
    cd ../../..
}

# Deploy environments
case $ENVIRONMENT in
    "staging")
        deploy_environment "staging"
        ;;
    "production")
        log_warning "Production deployment will incur costs!"
        deploy_environment "production"
        ;;
    "both")
        deploy_environment "staging"
        if [ $? -eq 0 ]; then
            log_info "Staging deployment complete. Proceeding to production..."
            sleep 3
            deploy_environment "production"
        fi
        ;;
esac

# Post-deployment summary
log_header "Deployment Summary"

echo -e "${GREEN}✅ Deployment completed successfully!${NC}"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "1. Deploy a sample application"
echo "2. Set up monitoring and alerting"
echo "3. Configure CI/CD pipelines"
echo ""
echo -e "${BLUE}Useful Commands:${NC}"
echo "• kubectl get nodes                    # View cluster nodes"
echo "• kubectl get pods --all-namespaces   # View all pods"
echo "• make status                         # Check cluster status"
echo "• make cost-estimate                  # View cost estimates"
echo "• make monitor                        # Monitor resource usage"
echo ""
echo -e "${YELLOW}Cost Management:${NC}"
echo "• Set up billing alerts: make billing-alerts"
echo "• Monitor usage regularly: make monitor"
echo "• Scale down when not needed"
echo "• Consider using staging for development"
echo ""
echo -e "${GREEN}Happy Kubernetes-ing! 🚀${NC}"
