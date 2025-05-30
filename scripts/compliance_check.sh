#!/bin/bash

# Compliance check script for AWS infrastructure
# This script checks various security and compliance requirements

# Set environment variables
ENV=${1:-dev}
REGION=${2:-us-east-1}

echo "Running compliance checks for environment: $ENV in region: $REGION"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check required tools
for tool in aws terraform jq; do
    if ! command_exists "$tool"; then
        echo "Error: $tool is required but not installed."
        exit 1
    fi
done

# Check AWS credentials
echo "Checking AWS credentials..."
if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo "Error: Invalid AWS credentials or no AWS access"
    exit 1
fi

# Check VPC encryption
echo "Checking VPC Flow Logs..."
if ! aws ec2 describe-flow-logs --region "$REGION" --filter "Name=resource-id,Values=$(terraform output -json | jq -r .vpc_id.value)" | jq -e '.FlowLogs[0]' >/dev/null; then
    echo "Warning: VPC Flow Logs are not enabled"
fi

# Check S3 bucket encryption
echo "Checking S3 bucket encryption..."
aws s3api get-bucket-encryption --bucket "${ENV}-app-assets-$(aws sts get-caller-identity --query Account --output text)" 2>/dev/null || echo "Warning: S3 bucket encryption not enabled"

# Check security group rules
echo "Checking security group rules..."
aws ec2 describe-security-groups --region "$REGION" --group-ids $(terraform output -json | jq -r .app_security_group_id.value) | \
    jq -r '.SecurityGroups[].IpPermissions[] | select(.FromPort == 22) | "Warning: SSH port 22 is open in security group"'

# Check KMS key rotation
echo "Checking KMS key rotation..."
aws kms get-key-rotation-status --key-id $(terraform output -json | jq -r .kms_key_id.value) --region "$REGION" | \
    jq -e '.KeyRotationEnabled' >/dev/null || echo "Warning: KMS key rotation not enabled"

# Check for public S3 buckets
echo "Checking for public S3 buckets..."
aws s3api get-bucket-policy-status --bucket "${ENV}-app-assets-$(aws sts get-caller-identity --query Account --output text)" 2>/dev/null | \
    jq -e '.PolicyStatus.IsPublic' | grep -q "true" && echo "Warning: S3 bucket is public"

# Check IAM roles for least privilege
echo "Checking IAM roles..."
aws iam get-role --role-name "${ENV}-ec2-role" | \
    jq -r '.Role.AssumeRolePolicyDocument' | grep -q "ec2.amazonaws.com" || echo "Warning: EC2 role trust relationship might be too permissive"

# Check for unencrypted EBS volumes
echo "Checking EBS encryption..."
aws ec2 describe-volumes --region "$REGION" --filters "Name=encrypted,Values=false" | \
    jq -e '.Volumes[0]' >/dev/null && echo "Warning: Unencrypted EBS volumes found"

# Check for CloudTrail
echo "Checking CloudTrail..."
aws cloudtrail describe-trails --region "$REGION" | \
    jq -e '.trailList[0]' >/dev/null || echo "Warning: CloudTrail is not enabled"

# Check for GuardDuty
echo "Checking GuardDuty..."
aws guardduty list-detectors --region "$REGION" | \
    jq -e '.DetectorIds[0]' >/dev/null || echo "Warning: GuardDuty is not enabled"

echo "Compliance check completed." 