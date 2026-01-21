#!/bin/bash

# Simple S3 Upload Script - Chỉ dùng AWS CLI, không cần Python
# Usage: ./simple_upload.sh --bucket <bucket-name> [OPTIONS]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default values
BUCKET_NAME=""
AWS_REGION="us-east-1"
S3_PREFIX="cic_parquet"
LOCAL_PATH="./cicflow_parquet"
ENABLE_VERSIONING=false
ENABLE_ENCRYPTION=true
CREATE_BUCKET=true

# Helper functions
print_info() { echo -e "${BLUE}ℹ ${1}${NC}"; }
print_success() { echo -e "${GREEN}✓ ${1}${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ ${1}${NC}"; }
print_error() { echo -e "${RED}✗ ${1}${NC}"; }
print_header() { echo -e "\n${GREEN}=== ${1} ===${NC}\n"; }

# Show usage
show_usage() {
    cat << EOF
Usage: $0 --bucket <bucket-name> [OPTIONS]

Required:
  --bucket <name>          S3 bucket name

Optional:
  --region <region>        AWS region (default: us-east-1)
  --prefix <path>          S3 prefix/folder (default: cic_parquet)
  --local-path <path>      Local data path (default: ./cicflow_parquet)
  --no-create-bucket       Skip bucket creation (use existing bucket)
  --enable-versioning      Enable S3 versioning
  --no-encryption          Disable encryption
  --help                   Show this help

Examples:
  # Tạo bucket và upload
  $0 --bucket my-cic-bucket

  # Chỉ upload vào bucket có sẵn
  $0 --bucket existing-bucket --no-create-bucket

  # Custom region và prefix
  $0 --bucket my-bucket --region ap-southeast-1 --prefix data/cic

EOF
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --bucket) BUCKET_NAME="$2"; shift 2 ;;
        --region) AWS_REGION="$2"; shift 2 ;;
        --prefix) S3_PREFIX="$2"; shift 2 ;;
        --local-path) LOCAL_PATH="$2"; shift 2 ;;
        --no-create-bucket) CREATE_BUCKET=false; shift ;;
        --enable-versioning) ENABLE_VERSIONING=true; shift ;;
        --no-encryption) ENABLE_ENCRYPTION=false; shift ;;
        --help) show_usage ;;
        *) print_error "Unknown option: $1"; show_usage ;;
    esac
done

# Validate
if [ -z "$BUCKET_NAME" ]; then
    print_error "Bucket name is required"
    show_usage
fi

# Print config
print_header "Configuration"
echo "Bucket:           $BUCKET_NAME"
echo "Region:           $AWS_REGION"
echo "S3 Prefix:        $S3_PREFIX"
echo "Local Path:       $LOCAL_PATH"
echo "Create Bucket:    $CREATE_BUCKET"
echo "Versioning:       $ENABLE_VERSIONING"
echo "Encryption:       $ENABLE_ENCRYPTION"
echo ""

# Check prerequisites
print_header "Checking Prerequisites"

if ! command -v aws &> /dev/null; then
    print_error "AWS CLI not installed"
    exit 1
fi
print_success "AWS CLI installed"

if ! aws sts get-caller-identity &> /dev/null; then
    print_error "AWS credentials not configured"
    exit 1
fi
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
print_success "AWS credentials OK (Account: $ACCOUNT_ID)"

if [ ! -d "$LOCAL_PATH" ]; then
    print_error "Local path not found: $LOCAL_PATH"
    exit 1
fi
FILE_COUNT=$(find "$LOCAL_PATH" -type f | wc -l)
print_success "Local data found ($FILE_COUNT files)"

# Confirm
echo ""
read -p "$(echo -e ${YELLOW}Proceed? \(yes/no\): ${NC})" -r
if [[ ! $REPLY =~ ^[Yy]es$ ]]; then
    print_warning "Cancelled"
    exit 0
fi

# Create bucket if needed
if [ "$CREATE_BUCKET" = true ]; then
    print_header "Creating S3 Bucket"
    
    if aws s3 ls "s3://$BUCKET_NAME" 2>/dev/null; then
        print_warning "Bucket already exists: $BUCKET_NAME"
    else
        print_info "Creating bucket..."
        
        if [ "$AWS_REGION" == "us-east-1" ]; then
            aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$AWS_REGION"
        else
            aws s3api create-bucket \
                --bucket "$BUCKET_NAME" \
                --region "$AWS_REGION" \
                --create-bucket-configuration LocationConstraint="$AWS_REGION"
        fi
        
        print_success "Bucket created"
    fi
    
    # Configure bucket
    print_info "Configuring bucket..."
    
    # Block public access
    aws s3api put-public-access-block \
        --bucket "$BUCKET_NAME" \
        --public-access-block-configuration \
        "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
    
    # Versioning
    if [ "$ENABLE_VERSIONING" = true ]; then
        aws s3api put-bucket-versioning \
            --bucket "$BUCKET_NAME" \
            --versioning-configuration Status=Enabled
    fi
    
    # Encryption
    if [ "$ENABLE_ENCRYPTION" = true ]; then
        aws s3api put-bucket-encryption \
            --bucket "$BUCKET_NAME" \
            --server-side-encryption-configuration '{
                "Rules": [{
                    "ApplyServerSideEncryptionByDefault": {
                        "SSEAlgorithm": "AES256"
                    },
                    "BucketKeyEnabled": true
                }]
            }'
    fi
    
    # Tags
    aws s3api put-bucket-tagging \
        --bucket "$BUCKET_NAME" \
        --tagging "TagSet=[
            {Key=Project,Value=CIC-Parquet},
            {Key=CreatedDate,Value=$(date +%Y-%m-%d)}
        ]"
    
    print_success "Bucket configured"
fi

# Upload data
print_header "Uploading Data"

print_info "Starting upload..."
echo ""

# Use aws s3 sync for efficient upload
aws s3 sync "$LOCAL_PATH" "s3://$BUCKET_NAME/$S3_PREFIX/" \
    --region "$AWS_REGION" \
    --no-progress

if [ $? -eq 0 ]; then
    echo ""
    print_success "Upload completed!"
    
    print_header "Summary"
    echo "S3 Location:  s3://$BUCKET_NAME/$S3_PREFIX/"
    echo "Console URL:  https://s3.console.aws.amazon.com/s3/buckets/$BUCKET_NAME?prefix=$S3_PREFIX/"
    echo ""
    
    # Show size
    print_info "Calculating size..."
    SIZE=$(aws s3 ls "s3://$BUCKET_NAME/$S3_PREFIX/" --recursive --summarize --human-readable | grep "Total Size" | awk '{print $3, $4}')
    echo "Total Size:   $SIZE"
    
    print_success "Done!"
else
    print_error "Upload failed"
    exit 1
fi
