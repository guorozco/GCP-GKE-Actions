# Makefile for Free Tier Optimized GKE Infrastructure
.PHONY: help init-staging init-production plan-staging plan-production apply-staging apply-production destroy-staging destroy-production clean cost-estimate

# Default environment
ENV ?= staging

# Colors for output
RED    := \033[31m
GREEN  := \033[32m
YELLOW := \033[33m
BLUE   := \033[34m
PURPLE := \033[35m
CYAN   := \033[36m
RESET  := \033[0m

help: ## Show this help message
	@echo "$(BLUE)🚀 Free Tier Optimized GKE Infrastructure$(RESET)"
	@echo "$(CYAN)================================================$(RESET)"
	@echo ""
	@echo "$(YELLOW)Usage:$(RESET)"
	@echo "  make <target> [ENV=staging|production]"
	@echo ""
	@echo "$(YELLOW)Targets:$(RESET)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-25s$(RESET) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(YELLOW)Free Tier Examples:$(RESET)"
	@echo "  make setup                    # Complete initial setup"
	@echo "  make init-staging             # Initialize staging (Autopilot)"
	@echo "  make deploy-staging           # Deploy staging environment"
	@echo "  make cost-estimate            # Estimate monthly costs"
	@echo "  make status                   # Check cluster status"
	@echo ""
	@echo "$(PURPLE)💰 Cost Optimization Features:$(RESET)"
	@echo "  • GKE Autopilot mode for staging"
	@echo "  • e2-micro/e2-small instances (free tier)"
	@echo "  • Preemptible nodes for cost savings"
	@echo "  • Minimal disk sizes (32GB)"
	@echo ""

# Prerequisites check
check-env:
	@if [ -z "$(TF_VAR_project_id)" ]; then \
		echo "$(RED)❌ Error: TF_VAR_project_id environment variable not set$(RESET)"; \
		echo "$(YELLOW)💡 Set it with: export TF_VAR_project_id=your-project-id$(RESET)"; \
		echo "$(YELLOW)💡 Or run: make setup$(RESET)"; \
		exit 1; \
	fi
	@echo "$(GREEN)✅ Project ID: $(TF_VAR_project_id)$(RESET)"

check-tools: ## Check if required tools are installed
	@echo "$(BLUE)🔧 Checking required tools...$(RESET)"
	@command -v gcloud >/dev/null 2>&1 || (echo "$(RED)❌ gcloud not found$(RESET)" && exit 1)
	@command -v terraform >/dev/null 2>&1 || (echo "$(RED)❌ terraform not found$(RESET)" && exit 1)
	@command -v terragrunt >/dev/null 2>&1 || (echo "$(RED)❌ terragrunt not found$(RESET)" && exit 1)
	@echo "$(GREEN)✅ All tools installed$(RESET)"

setup: check-tools ## Run initial setup script
	@echo "$(BLUE)🚀 Running initial setup...$(RESET)"
	@./scripts/setup.sh

init-staging: check-env ## Initialize Terragrunt for staging environment (Autopilot)
	@echo "$(BLUE)🔧 Initializing staging environment (Autopilot mode)...$(RESET)"
	cd environments/staging && terragrunt init

init-production: check-env ## Initialize Terragrunt for production environment (Standard)
	@echo "$(BLUE)🔧 Initializing production environment (Standard mode)...$(RESET)"
	cd environments/production && terragrunt init

plan-staging: check-env ## Plan changes for staging environment
	@echo "$(BLUE)📋 Planning staging environment...$(RESET)"
	cd environments/staging && terragrunt plan

plan-production: check-env ## Plan changes for production environment
	@echo "$(BLUE)📋 Planning production environment...$(RESET)"
	cd environments/production && terragrunt plan

deploy-staging: check-env ## Deploy staging environment (init + apply)
	@echo "$(BLUE)🚀 Deploying staging environment...$(RESET)"
	cd environments/staging && terragrunt init && terragrunt apply

deploy-production: check-env ## Deploy production environment (init + apply)
	@echo "$(YELLOW)⚠️  WARNING: You are about to deploy to PRODUCTION!$(RESET)"
	@echo "$(YELLOW)💰 This will incur costs. Continue? [y/N]$(RESET)"
	@read -r confirmation && [ "$$confirmation" = "y" ] || (echo "$(GREEN)Aborted$(RESET)" && exit 1)
	@echo "$(BLUE)🚀 Deploying production environment...$(RESET)"
	cd environments/production && terragrunt init && terragrunt apply

apply-staging: check-env ## Apply changes to staging environment
	@echo "$(BLUE)✅ Applying changes to staging environment...$(RESET)"
	cd environments/staging && terragrunt apply

apply-production: check-env ## Apply changes to production environment
	@echo "$(YELLOW)⚠️  WARNING: You are about to apply changes to PRODUCTION!$(RESET)"
	@echo "$(YELLOW)Press Enter to continue or Ctrl+C to abort...$(RESET)"
	@read
	@echo "$(BLUE)✅ Applying changes to production environment...$(RESET)"
	cd environments/production && terragrunt apply

destroy-staging: check-env ## Destroy staging environment
	@echo "$(RED)⚠️  WARNING: This will destroy the STAGING environment!$(RESET)"
	@echo "$(YELLOW)Type 'yes' to continue:$(RESET)"
	@read -r confirmation && [ "$$confirmation" = "yes" ] || (echo "$(GREEN)Aborted$(RESET)" && exit 1)
	@echo "$(RED)💥 Destroying staging environment...$(RESET)"
	cd environments/staging && terragrunt destroy

destroy-production: check-env ## Destroy production environment
	@echo "$(RED)🚨 DANGER: This will destroy the PRODUCTION environment!$(RESET)"
	@echo "$(RED)This action cannot be undone!$(RESET)"
	@echo "$(YELLOW)Type 'destroy-production' to continue:$(RESET)"
	@read -r confirmation && [ "$$confirmation" = "destroy-production" ] || (echo "$(GREEN)Aborted$(RESET)" && exit 1)
	@echo "$(RED)💥 Destroying production environment...$(RESET)"
	cd environments/production && terragrunt destroy

validate-staging: ## Validate staging Terraform configuration
	@echo "$(BLUE)✅ Validating staging configuration...$(RESET)"
	cd environments/staging && terragrunt validate

validate-production: ## Validate production Terraform configuration
	@echo "$(BLUE)✅ Validating production configuration...$(RESET)"
	cd environments/production && terragrunt validate

fmt: ## Format Terraform files
	@echo "$(BLUE)🎨 Formatting Terraform files...$(RESET)"
	terraform fmt -recursive .

clean: ## Clean up temporary files and caches
	@echo "$(BLUE)🧹 Cleaning up temporary files...$(RESET)"
	find . -type d -name ".terragrunt-cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	find . -name ".terraform.lock.hcl" -delete 2>/dev/null || true
	find . -name "backend.tf" -delete 2>/dev/null || true
	find . -name "provider.tf" -delete 2>/dev/null || true
	@echo "$(GREEN)✅ Cleanup complete$(RESET)"

cost-estimate: check-env ## Estimate monthly costs for both environments
	@echo "$(PURPLE)💰 Cost Estimation for Free Tier Setup$(RESET)"
	@echo "$(CYAN)=====================================$(RESET)"
	@echo ""
	@echo "$(YELLOW)📊 Staging Environment (Autopilot):$(RESET)"
	@echo "  • Mode: GKE Autopilot"
	@echo "  • Region: us-central1-a (free tier)"
	@echo "  • Estimated cost: $(GREEN)\$$0-10/month$(RESET)"
	@echo ""
	@echo "$(YELLOW)📊 Production Environment (Standard):$(RESET)"
	@echo "  • Mode: Standard GKE"
	@echo "  • Instance: 1x e2-small (preemptible)"
	@echo "  • Disk: 32GB standard persistent disk"
	@echo "  • Region: us-east1-b (free tier)"
	@echo "  • Estimated cost: $(GREEN)\$$15-30/month$(RESET)"
	@echo ""
	@echo "$(BLUE)💡 Tips to minimize costs:$(RESET)"
	@echo "  • Use staging (Autopilot) for development"
	@echo "  • Scale down production when not needed"
	@echo "  • Monitor usage with: make status"
	@echo "  • Set up billing alerts in GCP Console"

status-staging: check-env ## Show status of staging GKE cluster
	@echo "$(BLUE)📊 Staging cluster status:$(RESET)"
	@gcloud container clusters describe gke-staging --region=us-central1 --project=$(TF_VAR_project_id) --format="table(name,status,currentMasterVersion,currentNodeCount)" 2>/dev/null || echo "$(YELLOW)Cluster not found$(RESET)"

status-production: check-env ## Show status of production GKE cluster
	@echo "$(BLUE)📊 Production cluster status:$(RESET)"
	@gcloud container clusters describe gke-production --region=us-east1 --project=$(TF_VAR_project_id) --format="table(name,status,currentMasterVersion,currentNodeCount)" 2>/dev/null || echo "$(YELLOW)Cluster not found$(RESET)"

status: status-staging status-production ## Show status of all clusters

kubeconfig-staging: check-env ## Get kubectl credentials for staging
	@echo "$(BLUE)🔑 Getting staging kubeconfig...$(RESET)"
	gcloud container clusters get-credentials gke-staging --region=us-central1 --project=$(TF_VAR_project_id)
	@echo "$(GREEN)✅ Connected to staging cluster$(RESET)"
	@kubectl get nodes 2>/dev/null || echo "$(YELLOW)⚠️  No nodes found (Autopilot manages nodes automatically)$(RESET)"

kubeconfig-production: check-env ## Get kubectl credentials for production
	@echo "$(BLUE)🔑 Getting production kubeconfig...$(RESET)"
	gcloud container clusters get-credentials gke-production --region=us-east1 --project=$(TF_VAR_project_id)
	@echo "$(GREEN)✅ Connected to production cluster$(RESET)"
	@kubectl get nodes

monitor: check-env ## Monitor cluster resource usage
	@echo "$(BLUE)📊 Resource Usage Monitoring$(RESET)"
	@echo "$(CYAN)=============================$(RESET)"
	@echo ""
	@echo "$(YELLOW)Staging Cluster:$(RESET)"
	@gcloud container clusters get-credentials gke-staging --region=us-central1 --project=$(TF_VAR_project_id) --quiet 2>/dev/null || true
	@kubectl top nodes 2>/dev/null || echo "$(YELLOW)Metrics not available (normal for Autopilot)$(RESET)"
	@echo ""
	@echo "$(YELLOW)Production Cluster:$(RESET)"
	@gcloud container clusters get-credentials gke-production --region=us-east1 --project=$(TF_VAR_project_id) --quiet 2>/dev/null || true
	@kubectl top nodes 2>/dev/null || echo "$(YELLOW)Metrics not available or cluster not running$(RESET)"

billing-alerts: check-env ## Set up billing alerts (opens browser)
	@echo "$(BLUE)💰 Setting up billing alerts...$(RESET)"
	@echo "$(YELLOW)Opening GCP Billing console...$(RESET)"
	@open "https://console.cloud.google.com/billing/budgets?project=$(TF_VAR_project_id)" || echo "$(YELLOW)Please visit: https://console.cloud.google.com/billing/budgets?project=$(TF_VAR_project_id)$(RESET)"

# Generic targets that use ENV variable
init: check-env ## Initialize environment (use ENV=staging|production)
	@echo "$(BLUE)🔧 Initializing $(ENV) environment...$(RESET)"
	cd environments/$(ENV) && terragrunt init

plan: check-env ## Plan environment (use ENV=staging|production)
	@echo "$(BLUE)📋 Planning $(ENV) environment...$(RESET)"
	cd environments/$(ENV) && terragrunt plan

apply: check-env ## Apply environment (use ENV=staging|production)
	@if [ "$(ENV)" = "production" ]; then \
		echo "$(YELLOW)⚠️  WARNING: You are about to apply changes to PRODUCTION!$(RESET)"; \
		echo "$(YELLOW)Press Enter to continue or Ctrl+C to abort...$(RESET)"; \
		read; \
	fi
	@echo "$(BLUE)✅ Applying changes to $(ENV) environment...$(RESET)"
	cd environments/$(ENV) && terragrunt apply

validate: ## Validate environment configuration (use ENV=staging|production)
	@echo "$(BLUE)✅ Validating $(ENV) configuration...$(RESET)"
	cd environments/$(ENV) && terragrunt validate

destroy: check-env ## Destroy environment (use ENV=staging|production)
	@echo "$(RED)⚠️  WARNING: This will destroy the $(ENV) environment!$(RESET)"
	@echo "$(YELLOW)Type 'yes' to continue:$(RESET)"
	@read -r confirmation && [ "$$confirmation" = "yes" ] || (echo "$(GREEN)Aborted$(RESET)" && exit 1)
	@echo "$(RED)💥 Destroying $(ENV) environment...$(RESET)"
	cd environments/$(ENV) && terragrunt destroy

# Artifact Registry Commands
deploy-registry-staging: check-env ## Deploy Artifact Registry for staging
	@echo "$(BLUE)🐳 Deploying Artifact Registry for staging...$(RESET)"
	cd environments/staging/artifact-registry && terragrunt init && terragrunt apply

deploy-registry-production: check-env ## Deploy Artifact Registry for production
	@echo "$(YELLOW)⚠️  WARNING: You are about to deploy Artifact Registry to PRODUCTION!$(RESET)"
	@echo "$(YELLOW)Press Enter to continue or Ctrl+C to abort...$(RESET)"
	@read
	@echo "$(BLUE)🐳 Deploying Artifact Registry for production...$(RESET)"
	cd environments/production/artifact-registry && terragrunt init && terragrunt apply

deploy-registry-shared: check-env ## Deploy shared Artifact Registry
	@echo "$(BLUE)🐳 Deploying shared Artifact Registry...$(RESET)"
	cd environments/common/artifact-registry && terragrunt init && terragrunt apply

configure-docker-staging: check-env ## Configure Docker to use staging registry
	@echo "$(BLUE)🔧 Configuring Docker for staging registry...$(RESET)"
	gcloud auth configure-docker us-central1-docker.pkg.dev --project=$(TF_VAR_project_id)

configure-docker-production: check-env ## Configure Docker to use production registry
	@echo "$(BLUE)🔧 Configuring Docker for production registry...$(RESET)"
	gcloud auth configure-docker us-east1-docker.pkg.dev --project=$(TF_VAR_project_id)

configure-docker-all: check-env ## Configure Docker for all registries
	@echo "$(BLUE)🔧 Configuring Docker for all registries...$(RESET)"
	gcloud auth configure-docker us-central1-docker.pkg.dev,us-east1-docker.pkg.dev --project=$(TF_VAR_project_id)

list-registries: check-env ## List all Artifact Registry repositories
	@echo "$(BLUE)📦 Listing Artifact Registry repositories...$(RESET)"
	gcloud artifacts repositories list --project=$(TF_VAR_project_id)

list-images: check-env ## List images in repositories
	@echo "$(BLUE)🖼️  Listing images in repositories...$(RESET)"
	@echo "$(YELLOW)Staging Repository:$(RESET)"
	@gcloud artifacts docker images list us-central1-docker.pkg.dev/$(TF_VAR_project_id)/staging-docker --project=$(TF_VAR_project_id) 2>/dev/null || echo "No images found"
	@echo "$(YELLOW)Production Repository:$(RESET)"
	@gcloud artifacts docker images list us-east1-docker.pkg.dev/$(TF_VAR_project_id)/production-docker --project=$(TF_VAR_project_id) 2>/dev/null || echo "No images found"

# ==========================================
# Hello World Flask App Management
# ==========================================

deploy-app-staging: check-env ## Deploy Hello World Flask app to staging
	@echo "$(BLUE)🚀 Deploying Hello World Flask app to staging...$(RESET)"
	@cd ../app && ./deploy.sh latest staging

deploy-app-production: check-env ## Deploy Hello World Flask app to production
	@echo "$(BLUE)🚀 Deploying Hello World Flask app to production...$(RESET)"
	@cd ../app && ./deploy.sh v1.0.0 production

deploy-app-version: check-env ## Deploy specific version to environment
	@echo "$(BLUE)🚀 Deploying Hello World Flask app with custom version...$(RESET)"
	@read -p "Enter version (e.g., v1.0.1): " version; \
	read -p "Enter environment (staging/production): " env; \
	cd ../app && ./deploy.sh $$version $$env

test-app-local: check-env ## Test Hello World Flask app locally
	@echo "$(BLUE)🧪 Testing Hello World Flask app locally...$(RESET)"
	@cd ../app && docker build -t hello-world-flask:test . && \
	echo "$(GREEN)✅ Build successful! Run: docker run -p 5000:5000 hello-world-flask:test$(RESET)"

check-app-staging: check-env ## Check Hello World Flask app status in staging
	@echo "$(BLUE)🔍 Checking Hello World Flask app in staging...$(RESET)"
	@kubectl --context=gke_$(TF_VAR_project_id)_us-central1_gke-staging get pods -l app=hello-world-flask 2>/dev/null || echo "$(YELLOW)App not found in staging$(RESET)"
	@kubectl --context=gke_$(TF_VAR_project_id)_us-central1_gke-staging get service hello-world-flask-service 2>/dev/null || echo "$(YELLOW)Service not found in staging$(RESET)"

check-app-production: check-env ## Check Hello World Flask app status in production
	@echo "$(BLUE)🔍 Checking Hello World Flask app in production...$(RESET)"
	@kubectl --context=gke_$(TF_VAR_project_id)_us-east1_gke-production get pods -l app=hello-world-flask 2>/dev/null || echo "$(YELLOW)App not found in production$(RESET)"
	@kubectl --context=gke_$(TF_VAR_project_id)_us-east1_gke-production get service hello-world-flask-service 2>/dev/null || echo "$(YELLOW)Service not found in production$(RESET)"

logs-app-staging: check-env ## Get Hello World Flask app logs from staging
	@echo "$(BLUE)📋 Getting Hello World Flask app logs from staging...$(RESET)"
	@kubectl --context=gke_$(TF_VAR_project_id)_us-central1_gke-staging logs -l app=hello-world-flask --tail=100 2>/dev/null || echo "$(YELLOW)No logs found$(RESET)"

logs-app-production: check-env ## Get Hello World Flask app logs from production
	@echo "$(BLUE)📋 Getting Hello World Flask app logs from production...$(RESET)"
	@kubectl --context=gke_$(TF_VAR_project_id)_us-east1_gke-production logs -l app=hello-world-flask --tail=100 2>/dev/null || echo "$(YELLOW)No logs found$(RESET)"

scale-app-staging: check-env ## Scale Hello World Flask app in staging
	@echo "$(BLUE)📈 Scaling Hello World Flask app in staging...$(RESET)"
	@read -p "Enter replica count: " replicas; \
	kubectl --context=gke_$(TF_VAR_project_id)_us-central1_gke-staging scale deployment hello-world-flask --replicas=$$replicas

scale-app-production: check-env ## Scale Hello World Flask app in production
	@echo "$(BLUE)📈 Scaling Hello World Flask app in production...$(RESET)"
	@read -p "Enter replica count: " replicas; \
	kubectl --context=gke_$(TF_VAR_project_id)_us-east1_gke-production scale deployment hello-world-flask --replicas=$$replicas

delete-app-staging: check-env ## Delete Hello World Flask app from staging
	@echo "$(BLUE)🗑️  Deleting Hello World Flask app from staging...$(RESET)"
	@kubectl --context=gke_$(TF_VAR_project_id)_us-central1_gke-staging delete deployment,service,hpa -l app=hello-world-flask 2>/dev/null || echo "$(YELLOW)App not found$(RESET)"

delete-app-production: check-env ## Delete Hello World Flask app from production
	@echo "$(BLUE)🗑️  Deleting Hello World Flask app from production...$(RESET)"
	@kubectl --context=gke_$(TF_VAR_project_id)_us-east1_gke-production delete deployment,service,hpa -l app=hello-world-flask 2>/dev/null || echo "$(YELLOW)App not found$(RESET)"

get-app-url-staging: check-env ## Get the external URL for staging app
	@echo "$(BLUE)🌐 Getting staging app URL...$(RESET)"
	@SERVICE_IP=$$(kubectl --context=gke_$(TF_VAR_project_id)_us-central1_gke-staging get service hello-world-flask-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null); \
	if [ "$$SERVICE_IP" = "" ]; then \
		echo "$(YELLOW)External IP not yet assigned or app not deployed$(RESET)"; \
	else \
		echo "$(GREEN)Staging App URL: http://$$SERVICE_IP$(RESET)"; \
		echo "$(CYAN)Health Check: http://$$SERVICE_IP/api/health$(RESET)"; \
	fi

get-app-url-production: check-env ## Get the external URL for production app
	@echo "$(BLUE)🌐 Getting production app URL...$(RESET)"
	@SERVICE_IP=$$(kubectl --context=gke_$(TF_VAR_project_id)_us-east1_gke-production get service hello-world-flask-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null); \
	if [ "$$SERVICE_IP" = "" ]; then \
		echo "$(YELLOW)External IP not yet assigned or app not deployed$(RESET)"; \
	else \
		echo "$(GREEN)Production App URL: http://$$SERVICE_IP$(RESET)"; \
		echo "$(CYAN)Health Check: http://$$SERVICE_IP/api/health$(RESET)"; \
	fi
