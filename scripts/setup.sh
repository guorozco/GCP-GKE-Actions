#!/bin/bash

# Setup script for GKE Infrastructure
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

check_command() {
    if ! command -v $1 &> /dev/null; then
        log_error "$1 is not installed. Please install it and try again."
        exit 1
    fi
}

# Main script
echo -e "${BLUE} GKE Infrastructure Setup${NC}"
echo "=================================="

# Check prerequisites
log_info "Checking prerequisites..."
check_command "gcloud"
check_command "terraform" 
check_command "terragrunt"

log_success "All required tools are installed"

# Check if user is authenticated
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    log_error "Not authenticated with gcloud. Please run 'gcloud auth login'"
    exit 1
fi

log_success "gcloud authentication verified"

# Get project ID
if [ -z "$TF_VAR_project_id" ]; then
    echo -e "${YELLOW}Enter your GCP Project ID:${NC}"
    read -r project_id
    export TF_VAR_project_id="$project_id"
else
    log_info "Using project ID: $TF_VAR_project_id"
fi

# Verify project exists
if ! gcloud projects describe "$TF_VAR_project_id" &> /dev/null; then
    log_error "Project '$TF_VAR_project_id' not found or not accessible"
    exit 1
fi

log_success "Project '$TF_VAR_project_id' verified"

# Set current project
gcloud config set project "$TF_VAR_project_id"

# Enable required APIs
log_info "Enabling required Google Cloud APIs..."
apis=(
    "container.googleapis.com"
    "compute.googleapis.com" 
    "cloudresourcemanager.googleapis.com"
    "secretmanager.googleapis.com"
    "iam.googleapis.com"
    "serviceusage.googleapis.com"
)

for api in "${apis[@]}"; do
    log_info "Enabling $api..."
    gcloud services enable "$api"
done

log_success "All required APIs enabled"

# Create GCS buckets for Terraform state
log_info "Creating GCS buckets for Terraform state..."

buckets=(
    "${TF_VAR_project_id}-tfstate-staging"
    "${TF_VAR_project_id}-tfstate-production"
)

for bucket in "${buckets[@]}"; do
    if gsutil ls -b "gs://$bucket" &> /dev/null; then
        log_warning "Bucket gs://$bucket already exists"
    else
        log_info "Creating bucket gs://$bucket..."
        gsutil mb "gs://$bucket"
        gsutil versioning set on "gs://$bucket"
        log_success "Created and enabled versioning for gs://$bucket"
    fi
done

# Check and set up service account (optional)
echo -e "${YELLOW}Do you want to create a dedicated service account for Terraform? (y/N):${NC}"
read -r create_sa

if [[ $create_sa =~ ^[Yy]$ ]]; then
    sa_name="terraform-gke"
    sa_email="${sa_name}@${TF_VAR_project_id}.iam.gserviceaccount.com"
    
    log_info "Creating service account: $sa_name"
    
    if gcloud iam service-accounts describe "$sa_email" &> /dev/null; then
        log_warning "Service account $sa_email already exists"
    else
        gcloud iam service-accounts create "$sa_name" \
            --display-name="Terraform GKE Service Account" \
            --description="Service account for Terraform GKE operations"
        log_success "Service account created: $sa_email"
    fi
    
    # Assign required roles
    roles=(
        "roles/container.admin"
        "roles/compute.admin"
        "roles/iam.serviceAccountAdmin"
        "roles/resourcemanager.projectIamAdmin"
        "roles/secretmanager.admin"
        "roles/storage.admin"
    )
    
    log_info "Assigning IAM roles to service account..."
    for role in "${roles[@]}"; do
        gcloud projects add-iam-policy-binding "$TF_VAR_project_id" \
            --member="serviceAccount:$sa_email" \
            --role="$role" \
            --quiet
    done
    
    log_success "IAM roles assigned to service account"
    
    # Create and download key
    key_file="terraform-sa-key.json"
    if [ ! -f "$key_file" ]; then
        log_info "Creating service account key..."
        gcloud iam service-accounts keys create "$key_file" \
            --iam-account="$sa_email"
        
        log_success "Service account key created: $key_file"
        log_warning "Keep this key file secure and don't commit it to git!"
        
        echo -e "${YELLOW}To use this service account, set:${NC}"
        echo "export GOOGLE_APPLICATION_CREDENTIALS=\"$(pwd)/$key_file\""
    fi
fi

# Create environment file
env_file=".env.local"
log_info "Creating environment file: $env_file"

cat > "$env_file" << EOF
# GKE Infrastructure Environment Variables
export TF_VAR_project_id="$TF_VAR_project_id"

# Uncomment and set if using service account key
# export GOOGLE_APPLICATION_CREDENTIALS="$(pwd)/terraform-sa-key.json"

# Terraform/Terragrunt settings
export TF_LOG=INFO
export TF_LOG_PATH=./terraform.log
EOF

log_success "Environment file created: $env_file"

# Summary
echo ""
echo -e "${GREEN} Setup completed successfully!${NC}"
echo "=================================="
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Source the environment file: source $env_file"
echo "2. Navigate to an environment: cd infra/environments/staging"
echo "3. Initialize Terragrunt: terragrunt init"
echo "4. Plan deployment: terragrunt plan"
echo "5. Apply changes: terragrunt apply"
echo ""
echo -e "${BLUE}Useful commands:${NC}"
echo "• make help                    # Show available make targets"
echo "• make init-staging           # Initialize staging environment"
echo "• make plan-staging           # Plan staging deployment"
echo "• make apply-staging          # Apply staging changes"
echo ""
echo -e "${YELLOW}Remember to:${NC}"
echo "• Keep your service account key secure"
echo "• Review terraform plans before applying"
echo "• Use staging environment for testing"
echo ""
echo -e "${GREEN}Happy deploying! ${NC}"

