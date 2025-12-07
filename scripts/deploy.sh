#!/bin/bash
# LocalStore Platform - Deployment Script
# Usage: ./deploy.sh [environment]
#
# Uses Terraform workspaces for environment management

set -e

ENVIRONMENT=${1:-dev}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(dirname "$SCRIPT_DIR")"
TERRAFORM_DIR="$INFRA_DIR/terraform"

echo "=== LocalStore Platform Deployment ==="
echo "Environment: $ENVIRONMENT"
echo "======================================="

# Check prerequisites
check_prerequisites() {
    echo "Checking prerequisites..."
    
    if ! command -v terraform &> /dev/null; then
        echo "ERROR: terraform is not installed"
        exit 1
    fi
    
    if ! command -v docker &> /dev/null; then
        echo "ERROR: docker is not installed"
        exit 1
    fi
    
    if ! command -v aws &> /dev/null; then
        echo "ERROR: aws-cli is not installed"
        exit 1
    fi
    
    echo "All prerequisites met."
}

# Deploy infrastructure
deploy_infrastructure() {
    echo "Deploying infrastructure..."
    
    cd "$TERRAFORM_DIR"
    
    # Initialize if needed
    if [ ! -d ".terraform" ]; then
        terraform init
    fi
    
    # Select or create workspace
    if ! terraform workspace select "$ENVIRONMENT" 2>/dev/null; then
        echo "Creating workspace: $ENVIRONMENT"
        terraform workspace new "$ENVIRONMENT"
    fi
    
    echo "Using workspace: $(terraform workspace show)"
    
    terraform plan -var-file="tfvars/${ENVIRONMENT}.tfvars" -out="${ENVIRONMENT}.tfplan"
    
    echo "Review the plan above. Continue? (yes/no)"
    read -r CONFIRM
    
    if [ "$CONFIRM" = "yes" ]; then
        terraform apply "${ENVIRONMENT}.tfplan"
        rm -f "${ENVIRONMENT}.tfplan"
        echo "Infrastructure deployed successfully."
    else
        rm -f "${ENVIRONMENT}.tfplan"
        echo "Deployment cancelled."
        exit 1
    fi
}

# Deploy application
deploy_application() {
    echo "Deploying application..."
    
    cd "$TERRAFORM_DIR"
    
    # Ensure correct workspace
    terraform workspace select "$ENVIRONMENT" 2>/dev/null || {
        echo "ERROR: Workspace $ENVIRONMENT does not exist. Run infrastructure deployment first."
        exit 1
    }
    
    EC2_IP=$(terraform output -raw instance_public_ip 2>/dev/null || echo "")
    
    if [ -z "$EC2_IP" ]; then
        echo "ERROR: Could not get EC2 IP from Terraform output"
        exit 1
    fi
    
    SSH_KEY="$HOME/.ssh/localstore-${ENVIRONMENT}.pem"
    
    if [ ! -f "$SSH_KEY" ]; then
        echo "ERROR: SSH key not found: $SSH_KEY"
        exit 1
    fi
    
    echo "Deploying to $EC2_IP..."
    
    # Select compose file based on environment
    if [ "$ENVIRONMENT" = "prod" ]; then
        COMPOSE_FILE="docker-compose.prod.yml"
    else
        COMPOSE_FILE="docker-compose.dev.yml"
    fi
    
    echo "Using compose file: $COMPOSE_FILE"
    
    # Create directory on remote
    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "ec2-user@$EC2_IP" \
        "sudo mkdir -p /opt/localstore && sudo chown ec2-user:ec2-user /opt/localstore"
    
    # Copy docker-compose files
    scp -i "$SSH_KEY" -o StrictHostKeyChecking=no \
        "$INFRA_DIR/docker/compose/$COMPOSE_FILE" \
        "ec2-user@$EC2_IP:/opt/localstore/docker-compose.yml"
    
    # Copy .env file if exists
    if [ -f "$INFRA_DIR/.env.${ENVIRONMENT}" ]; then
        scp -i "$SSH_KEY" -o StrictHostKeyChecking=no \
            "$INFRA_DIR/.env.${ENVIRONMENT}" \
            "ec2-user@$EC2_IP:/opt/localstore/.env"
    fi
    
    # Deploy
    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "ec2-user@$EC2_IP" << 'EOF'
        cd /opt/localstore
        
        # Login to ECR (uses instance IAM role)
        # Get AWS account ID and region dynamically (IMDSv2 requires token)
        TOKEN=$(curl -sX PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
        AWS_REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/region)
        AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
        ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        
        # Export ECR_REGISTRY for docker-compose
        export ECR_REGISTRY
        
        # Get ECR login token and authenticate Docker
        aws ecr get-login-password --region $AWS_REGION | \
            docker login --username AWS --password-stdin $ECR_REGISTRY 2>/dev/null || \
            echo "Warning: ECR login failed. Will use local/public images only."
        
        # Update .env with ECR_REGISTRY if not set
        if ! grep -q "^ECR_REGISTRY=" .env 2>/dev/null; then
            echo "ECR_REGISTRY=$ECR_REGISTRY" >> .env
        fi
        
        docker compose pull || echo "Some images may not be available yet"
        docker compose up -d
        docker compose ps
EOF
    
    echo "Application deployed successfully."
    echo ""
    echo "Services available at:"
    echo "  PostgreSQL: $EC2_IP:5432"
    echo "  Redis:      $EC2_IP:6379"
    if [ "$ENVIRONMENT" = "prod" ]; then
        echo "  API:        http://$EC2_IP:80"
    fi
}

# Main
main() {
    check_prerequisites
    
    echo ""
    echo "Select deployment type:"
    echo "1. Infrastructure only"
    echo "2. Application only"
    echo "3. Both"
    read -r CHOICE
    
    case $CHOICE in
        1)
            deploy_infrastructure
            ;;
        2)
            deploy_application
            ;;
        3)
            deploy_infrastructure
            deploy_application
            ;;
        *)
            echo "Invalid choice"
            exit 1
            ;;
    esac
    
    echo ""
    echo "=== Deployment Complete ==="
}

main
