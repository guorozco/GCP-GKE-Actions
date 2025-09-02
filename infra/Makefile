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
