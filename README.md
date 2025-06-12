# AWS Event-Driven Pipeline (DynamoDB → EventBridge → SQS)

## Overview
This Terraform project provisions the first part of an event-driven pipeline:
- DynamoDB table with streams enabled
- EventBridge Pipe filtering on `status = PENDING`
- SQS queue for file pointers

## Structure
```
main.tf            # Root config, wires modules together
variables.tf       # Common variables
outputs.tf         # Useful outputs
modules/
  dynamodb/        # DynamoDB table + stream
  sqs/             # SQS queue
  eventbridge/     # EventBridge Pipe + IAM + CloudFormation
```

## AWS Credentials & Provider Setup
Terraform requires valid AWS credentials to deploy resources. The recommended approach is to use an AWS CLI profile.

1. **Configure your AWS profile** (if not already):
   ```sh
   aws configure --profile your-profile-name
   ```
2. **Update your provider block** (e.g., in `providers.tf`):
   ```hcl
   provider "aws" {
     region  = var.aws_region
     profile = "your-profile-name"
   }
   ```
3. **Alternatively, set environment variables** (not recommended for production):
   ```sh
   export AWS_ACCESS_KEY_ID=...
   export AWS_SECRET_ACCESS_KEY=...
   export AWS_DEFAULT_REGION=us-east-1
   ```

## Deployment
1. **Initialize Terraform:**
   ```sh
   terraform init
   ```
2. **Plan the deployment:**
   ```sh
   terraform plan
   ```
3. **Apply the deployment:**
   ```sh
   terraform apply
   ```

## Testing the Flow
1. **Get resource outputs:**
   ```sh
   terraform output
   ```
   - Note the DynamoDB table name and SQS queue URL.

2. **Manually add a row to DynamoDB:**
   - Use AWS Console or AWS CLI:
     ```sh
     aws dynamodb put-item \
       --table-name <TABLE_NAME> \
       --item '{"id": {"S": "test1"}, "status": {"S": "PENDING"}}'
     ```

3. **Check SQS for messages:**
   - Use AWS Console or AWS CLI:
     ```sh
     aws sqs receive-message --queue-url <QUEUE_URL>
     ```
   - You should see a message appear in SQS when a new item with `status = PENDING` is added to DynamoDB.

## Troubleshooting & Notes
- **Credentials Error:**
  - If you see `No valid credential sources found`, ensure your AWS profile is set up and referenced in the provider block, or that your environment variables are exported.
  - Run `env | grep AWS` to verify environment variables are set.
- **DynamoDB Index Error:**
  - If you see `all attributes must be indexed. Unused attributes: ["status"]`, ensure your DynamoDB table includes a Global Secondary Index (GSI) on the `status` attribute.
- **EventBridge Pipe Support:**
  - The AWS provider does not natively support `aws_eventbridge_pipe`. This project uses a CloudFormation stack to deploy the pipe.
- **Resource Tagging:**
  - All resources are tagged for cost allocation and environment tracking. Update tags as needed in your modules.

## Next Steps
- Add Lambda and EC2 orchestration modules for the rest of the pipeline.