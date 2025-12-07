# ECR Operations Makefile
# Usage: make -f scripts/ecr.mk <target> REPO=<repo-name>
#
# Examples:
#   make -f scripts/ecr.mk create-repo REPO=localstore/api
#   make -f scripts/ecr.mk lifecycle-policy REPO=localstore/ai
#
# Note: ECR repositories are shared across all environments (dev/staging/prod).
#       Environment-specific images are differentiated by image tags.

AWS_REGION ?= ap-southeast-1
UNTAGGED_EXPIRY_DAYS ?= 7

.PHONY: create-repo lifecycle-policy setup-repo tag-repo help

help:
	@echo "ECR Operations Makefile"
	@echo ""
	@echo "Usage: make -f scripts/ecr.mk <target> REPO=<repo-name>"
	@echo ""
	@echo "Targets:"
	@echo "  create-repo       Create ECR repository if not exists"
	@echo "  lifecycle-policy  Set lifecycle policy for untagged images"
	@echo "  tag-repo          Tag existing ECR repository"
	@echo "  setup-repo        Create repo, set lifecycle policy, and apply tags"
	@echo ""
	@echo "Variables:"
	@echo "  REPO                  Repository name (required)"
	@echo "  AWS_REGION            AWS region (default: ap-southeast-1)"
	@echo "  UNTAGGED_EXPIRY_DAYS  Days before untagged images expire (default: 7)"

create-repo:
ifndef REPO
	$(error REPO is required. Usage: make create-repo REPO=localstore/api)
endif
	@echo "Creating ECR repository: $(REPO)"
	@aws ecr describe-repositories --repository-names "$(REPO)" --region $(AWS_REGION) 2>/dev/null || \
		aws ecr create-repository \
			--repository-name "$(REPO)" \
			--region $(AWS_REGION) \
			--image-scanning-configuration scanOnPush=true \
			--image-tag-mutability MUTABLE \
			--tags Key=Project,Value="Local Store Platform" Key=ManagedBy,Value=github-actions
	@echo "Repository $(REPO) ready"

tag-repo:
ifndef REPO
	$(error REPO is required. Usage: make tag-repo REPO=localstore/api)
endif
	@echo "Tagging ECR repository: $(REPO)"
	@REPO_ARN=$$(aws ecr describe-repositories --repository-names "$(REPO)" --region $(AWS_REGION) --query 'repositories[0].repositoryArn' --output text) && \
		aws ecr tag-resource \
			--resource-arn "$$REPO_ARN" \
			--region $(AWS_REGION) \
			--tags Key=Project,Value="Local Store Platform" Key=ManagedBy,Value=github-actions
	@echo "Repository $(REPO) tagged"

lifecycle-policy:
ifndef REPO
	$(error REPO is required. Usage: make lifecycle-policy REPO=localstore/api)
endif
	@echo "Setting lifecycle policy for: $(REPO) (untagged images expire after $(UNTAGGED_EXPIRY_DAYS) days)"
	@aws ecr put-lifecycle-policy \
		--repository-name "$(REPO)" \
		--region $(AWS_REGION) \
		--lifecycle-policy-text '{"rules":[{"rulePriority":1,"description":"Delete untagged images after $(UNTAGGED_EXPIRY_DAYS) days","selection":{"tagStatus":"untagged","countType":"sinceImagePushed","countUnit":"days","countNumber":$(UNTAGGED_EXPIRY_DAYS)},"action":{"type":"expire"}}]}'
	@echo "Lifecycle policy set for $(REPO)"

setup-repo: create-repo lifecycle-policy
	@echo "ECR repository $(REPO) fully configured"
