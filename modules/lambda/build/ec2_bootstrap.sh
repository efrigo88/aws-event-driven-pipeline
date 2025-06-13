#!/bin/bash
exec > /home/ubuntu/user-data.log 2>&1
set -x
cd /home/ubuntu

# Install AWS CLI v2 and jq
apt-get update
apt-get install -y unzip curl jq python3-pip
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
export PATH=$PATH:/usr/local/bin

# Install boto3
pip3 install boto3

# Download the SQS worker script from S3
aws s3 cp s3://${S3_BUCKET_NAME}/sqs_worker.py /home/ubuntu/sqs_worker.py
chmod +x /home/ubuntu/sqs_worker.py

# Set environment variables for the worker
export SQS_QUEUE_URL="${SQS_QUEUE_URL}"
export DYNAMODB_TABLE_NAME="${DYNAMODB_TABLE_NAME}"
export EC2_AUTOTERMINATE_MINUTES="${AUTO_TERMINATE}"
export AWS_REGION="${AWS_REGION:-us-east-1}"

# Run the worker
python3 /home/ubuntu/sqs_worker.py