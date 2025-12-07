#!/bin/bash
# LocalStore Platform - Environment Configuration Generator
# Usage: ./scripts/config.sh [environment]
# 
# Generates .env files for the specified environment (dev, staging, prod)
# Prompts for required values and generates secure defaults where appropriate

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
DEFAULT_AWS_REGION="ap-southeast-1"
DEFAULT_DB_NAME="localstore"
DEFAULT_DB_USER="localstore"
DEFAULT_API_VERSION="latest"
DEFAULT_AI_VERSION="latest"

# Domain mapping per environment
# CloudFlare free SSL covers *.localstore-platform.com (single-level only)
# So we use: api-dev, api-staging, api (not api.dev, api.staging)
get_api_domain() {
    local env="$1"
    case "$env" in
        dev)     echo "api-dev.localstore-platform.com" ;;
        staging) echo "api-staging.localstore-platform.com" ;;
        prod)    echo "api.localstore-platform.com" ;;
    esac
}

# Functions
print_header() {
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}  LocalStore Platform Configuration${NC}"
    echo -e "${BLUE}======================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

prompt_value() {
    local prompt="$1"
    local default="$2"
    local secret="$3"
    local value=""
    
    if [ -n "$default" ]; then
        prompt="$prompt [$default]"
    fi
    
    if [ "$secret" = "true" ]; then
        read -sp "$prompt: " value
        echo ""
    else
        read -p "$prompt: " value
    fi
    
    if [ -z "$value" ] && [ -n "$default" ]; then
        value="$default"
    fi
    
    echo "$value"
}

generate_random_string() {
    local length="${1:-32}"
    openssl rand -base64 48 | tr -dc 'a-zA-Z0-9' | head -c "$length"
}

get_aws_account_id() {
    aws sts get-caller-identity --query Account --output text 2>/dev/null || echo ""
}

# Main configuration function
configure_environment() {
    local env="$1"
    local output_file="$INFRA_DIR/.env.${env}"
    
    print_header
    echo "Configuring environment: ${env}"
    echo "Output file: ${output_file}"
    echo ""
    
    # Check if file exists
    if [ -f "$output_file" ]; then
        read -p "File already exists. Overwrite? (y/N): " overwrite
        if [ "$overwrite" != "y" ] && [ "$overwrite" != "Y" ]; then
            print_warning "Configuration cancelled"
            exit 0
        fi
    fi
    
    echo ""
    echo -e "${YELLOW}=== AWS Configuration ===${NC}"
    
    # Try to get AWS account ID automatically
    local detected_account_id=$(get_aws_account_id)
    if [ -n "$detected_account_id" ]; then
        print_success "Detected AWS Account ID: $detected_account_id"
        AWS_ACCOUNT_ID=$(prompt_value "AWS Account ID" "$detected_account_id")
    else
        print_warning "Could not detect AWS Account ID (ensure AWS CLI is configured)"
        AWS_ACCOUNT_ID=$(prompt_value "AWS Account ID" "")
    fi
    
    AWS_REGION=$(prompt_value "AWS Region" "$DEFAULT_AWS_REGION")
    
    # Construct ECR Registry
    ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
    print_success "ECR Registry: $ECR_REGISTRY"
    
    echo ""
    echo -e "${YELLOW}=== Database Configuration ===${NC}"
    
    DB_NAME=$(prompt_value "Database Name" "$DEFAULT_DB_NAME")
    DB_USER=$(prompt_value "Database User" "$DEFAULT_DB_USER")
    
    if [ "$env" = "prod" ]; then
        echo "Generating secure database password..."
        DB_PASSWORD=$(generate_random_string 32)
        print_success "Database password generated (32 chars)"
    else
        DB_PASSWORD=$(prompt_value "Database Password" "localstore_${env}")
    fi
    
    echo ""
    echo -e "${YELLOW}=== Redis Configuration ===${NC}"
    
    if [ "$env" = "prod" ]; then
        echo "Generating secure Redis password..."
        REDIS_PASSWORD=$(generate_random_string 32)
        print_success "Redis password generated (32 chars)"
    else
        REDIS_PASSWORD=""
        print_warning "No Redis password for ${env} environment"
    fi
    
    echo ""
    echo -e "${YELLOW}=== Application Configuration ===${NC}"
    
    API_VERSION=$(prompt_value "API Version" "$DEFAULT_API_VERSION")
    AI_VERSION=$(prompt_value "AI Version" "$DEFAULT_AI_VERSION")
    
    echo "Generating JWT secret..."
    JWT_SECRET=$(generate_random_string 64)
    print_success "JWT secret generated (64 chars)"
    
    # Get API domain for this environment
    API_DOMAIN=$(get_api_domain "$env")
    print_success "API Domain: $API_DOMAIN"
    
    echo ""
    echo -e "${YELLOW}=== Writing Configuration ===${NC}"
    
    # Capitalize environment name for header
    local env_upper=$(echo "$env" | tr '[:lower:]' '[:upper:]')
    
    # Generate .env file
    cat > "$output_file" << EOF
# LocalStore Platform - ${env_upper} Environment
# Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
# DO NOT COMMIT THIS FILE TO VERSION CONTROL

# ======================
# AWS Configuration
# ======================
AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID}
AWS_REGION=${AWS_REGION}
ECR_REGISTRY=${ECR_REGISTRY}

# ======================
# Container Versions
# ======================
API_VERSION=${API_VERSION}
AI_VERSION=${AI_VERSION}

# ======================
# Database Configuration
# ======================
DB_NAME=${DB_NAME}
DB_USER=${DB_USER}
DB_PASSWORD=${DB_PASSWORD}

# ======================
# Redis Configuration
# ======================
REDIS_PASSWORD=${REDIS_PASSWORD}

# ======================
# Application Configuration
# ======================
NODE_ENV=${env}
JWT_SECRET=${JWT_SECRET}
API_DOMAIN=${API_DOMAIN}
EOF

    print_success "Configuration written to: $output_file"
    
    # Set restrictive permissions
    chmod 600 "$output_file"
    print_success "File permissions set to 600 (owner read/write only)"
    
    echo ""
    echo -e "${GREEN}Configuration complete!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Review the generated file: cat $output_file"
    echo "  2. Deploy infrastructure: make deploy-infra ENV=${env}"
    echo "  3. Deploy application: make deploy-app ENV=${env}"
}

# Parse arguments
ENVIRONMENT="${1:-dev}"

case "$ENVIRONMENT" in
    dev|staging|prod)
        configure_environment "$ENVIRONMENT"
        ;;
    *)
        echo "Usage: $0 [dev|staging|prod]"
        echo ""
        echo "Environments:"
        echo "  dev      Development environment (default)"
        echo "  staging  Staging environment"
        echo "  prod     Production environment"
        exit 1
        ;;
esac
