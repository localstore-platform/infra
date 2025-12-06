#!/bin/bash
# LocalStore Platform - Deployment Script
# Usage: ./deploy.sh [environment]

set -e

ENVIRONMENT=${1:-prod}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(dirname "$SCRIPT_DIR")"

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
    
    cd "$INFRA_DIR/terraform/environments/$ENVIRONMENT"
    
    terraform init
    terraform plan -var-file="terraform.tfvars" -out=plan.tfplan
    
    echo "Review the plan above. Continue? (yes/no)"
    read -r CONFIRM
    
    if [ "$CONFIRM" = "yes" ]; then
        terraform apply plan.tfplan
        echo "Infrastructure deployed successfully."
    else
        echo "Deployment cancelled."
        exit 1
    fi
}

# Deploy application
deploy_application() {
    echo "Deploying application..."
    
    EC2_IP=$(terraform output -raw ec2_public_ip 2>/dev/null || echo "")
    
    if [ -z "$EC2_IP" ]; then
        echo "ERROR: Could not get EC2 IP from Terraform output"
        exit 1
    fi
    
    echo "Deploying to $EC2_IP..."
    
    # Copy docker-compose files
    scp -i ~/.ssh/localstore-key.pem \
        "$INFRA_DIR/docker/compose/docker-compose.prod.yml" \
        "ec2-user@$EC2_IP:/opt/localstore/"
    
    # Deploy
    ssh -i ~/.ssh/localstore-key.pem "ec2-user@$EC2_IP" << 'EOF'
        cd /opt/localstore
        docker compose -f docker-compose.prod.yml pull
        docker compose -f docker-compose.prod.yml up -d
        docker compose -f docker-compose.prod.yml ps
EOF
    
    echo "Application deployed successfully."
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
