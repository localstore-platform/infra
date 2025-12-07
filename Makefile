# LocalStore Platform - Infrastructure Makefile
# Usage: make <target> [ENV=dev|staging|prod]

.PHONY: help config deploy-infra deploy-app deploy validate clean

# Default environment
ENV ?= dev

# Directories
SCRIPT_DIR := scripts
TERRAFORM_DIR := terraform
COMPOSE_DIR := docker/compose

# Colors
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m

help:
	@echo "$(BLUE)LocalStore Platform - Infrastructure$(NC)"
	@echo ""
	@echo "$(YELLOW)Configuration:$(NC)"
	@echo "  make config ENV=<env>        Generate .env file for environment"
	@echo ""
	@echo "$(YELLOW)Deployment:$(NC)"
	@echo "  make plan ENV=<env>          Preview infrastructure changes (Terraform plan)"
	@echo "  make deploy-infra ENV=<env>  Deploy infrastructure (Terraform apply)"
	@echo "  make deploy-app ENV=<env>    Deploy application (Docker Compose)"
	@echo "  make deploy ENV=<env>        Plan, confirm, then deploy both"
	@echo ""
	@echo "$(YELLOW)Validation:$(NC)"
	@echo "  make validate                Validate Terraform and configs"
	@echo "  make check-env ENV=<env>     Check if .env file exists"
	@echo ""
	@echo "$(YELLOW)Docker:$(NC)"
	@echo "  make docker-build            Build Docker images"
	@echo "  make docker-push             Push images to ECR"
	@echo ""
	@echo "$(YELLOW)Utilities:$(NC)"
	@echo "  make ssh ENV=<env>           SSH into EC2 instance"
	@echo "  make logs ENV=<env>          View container logs"
	@echo "  make clean                   Clean generated files"
	@echo ""
	@echo "$(YELLOW)Environments:$(NC) dev, staging, prod (default: dev)"

# ======================
# Configuration
# ======================

config:
	@echo "$(BLUE)Generating .env.$(ENV) configuration...$(NC)"
	@chmod +x $(SCRIPT_DIR)/config.sh
	@$(SCRIPT_DIR)/config.sh $(ENV)

check-env:
	@if [ ! -f .env.$(ENV) ]; then \
		echo "$(YELLOW)Error: .env.$(ENV) not found. Run 'make config ENV=$(ENV)' first.$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)✓ .env.$(ENV) exists$(NC)"

# ======================
# Deployment
# ======================

plan: check-env
	@echo "$(BLUE)Planning infrastructure for $(ENV)...$(NC)"
	@chmod +x $(SCRIPT_DIR)/deploy.sh
	@printf "1\nno\n" | $(SCRIPT_DIR)/deploy.sh $(ENV)

deploy-infra: check-env
	@echo "$(BLUE)Deploying infrastructure for $(ENV)...$(NC)"
	@chmod +x $(SCRIPT_DIR)/deploy.sh
	@(echo "1" && cat) | $(SCRIPT_DIR)/deploy.sh $(ENV)

deploy-app: check-env
	@echo "$(BLUE)Deploying application for $(ENV)...$(NC)"
	@chmod +x $(SCRIPT_DIR)/deploy.sh
	@printf "2\n" | $(SCRIPT_DIR)/deploy.sh $(ENV)

deploy: check-env
	@echo "$(BLUE)Deploying infrastructure and application for $(ENV)...$(NC)"
	@chmod +x $(SCRIPT_DIR)/deploy.sh
	@(echo "3" && cat) | $(SCRIPT_DIR)/deploy.sh $(ENV)

# ======================
# Validation
# ======================

validate:
	@echo "$(BLUE)Validating Terraform configuration...$(NC)"
	@cd $(TERRAFORM_DIR) && terraform init -backend=false > /dev/null 2>&1 || true
	@cd $(TERRAFORM_DIR) && terraform validate
	@cd $(TERRAFORM_DIR) && terraform fmt -check -recursive
	@echo "$(GREEN)✓ Terraform configuration is valid$(NC)"

# ======================
# Docker
# ======================

docker-build:
	@echo "$(BLUE)Building Docker images...$(NC)"
	@echo "Use GitHub Actions workflow: .github/workflows/docker-build.yml"
	@echo "Or trigger manually: gh workflow run docker-build.yml"

docker-push:
	@echo "$(BLUE)Pushing Docker images to ECR...$(NC)"
	@echo "Use GitHub Actions workflow: .github/workflows/docker-build.yml"

# ======================
# ECR Management
# ======================

ecr-setup:
	@echo "$(BLUE)Setting up ECR repositories...$(NC)"
	@make -f $(SCRIPT_DIR)/ecr.mk setup-repo REPO=localstore/api
	@make -f $(SCRIPT_DIR)/ecr.mk setup-repo REPO=localstore/ai
	@echo "$(GREEN)✓ ECR repositories configured$(NC)"

# ======================
# Utilities
# ======================

ssh: check-env
	@echo "$(BLUE)Connecting to EC2 for $(ENV)...$(NC)"
	@cd $(TERRAFORM_DIR) && \
		terraform workspace select $(ENV) > /dev/null 2>&1 && \
		eval $$(terraform output -raw ssh_command)

logs: check-env
	@echo "$(BLUE)Fetching logs from $(ENV)...$(NC)"
	@cd $(TERRAFORM_DIR) && \
		terraform workspace select $(ENV) > /dev/null 2>&1 && \
		IP=$$(terraform output -raw instance_public_ip) && \
		ssh -i ~/.ssh/localstore-$(ENV).pem ec2-user@$$IP "cd /opt/localstore && docker compose logs --tail=100"

status: check-env
	@echo "$(BLUE)Checking status for $(ENV)...$(NC)"
	@cd $(TERRAFORM_DIR) && \
		terraform workspace select $(ENV) > /dev/null 2>&1 && \
		IP=$$(terraform output -raw instance_public_ip) && \
		ssh -i ~/.ssh/localstore-$(ENV).pem ec2-user@$$IP "cd /opt/localstore && docker compose ps"

# ======================
# Cleanup
# ======================

clean:
	@echo "$(BLUE)Cleaning generated files...$(NC)"
	@rm -f $(TERRAFORM_DIR)/*.tfplan
	@rm -f $(TERRAFORM_DIR)/.terraform.lock.hcl
	@echo "$(GREEN)✓ Cleaned$(NC)"
	@echo "$(YELLOW)Note: .env files are not deleted for safety$(NC)"

clean-all: clean
	@echo "$(YELLOW)Warning: This will delete .env files!$(NC)"
	@read -p "Are you sure? (y/N): " confirm && [ "$$confirm" = "y" ] && \
		rm -f .env.dev .env.staging .env.prod || \
		echo "Cancelled"
