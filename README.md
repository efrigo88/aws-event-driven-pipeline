# AWS Event-Driven Pipeline (DynamoDB → EventBridge → SQS → Lambda → EC2)

## Overview
This Terraform project provisions a fully isolated, event-driven pipeline for file processing and status tracking. The architecture includes:

- **VPC, Subnet, Security Group**: All resources are isolated in a dedicated VPC for safe testing.
- **DynamoDB Table**: Stores file pointers and status, with a GSI on `status`.
- **EventBridge Pipe**: Forwards new DynamoDB rows with `status = PENDING` to SQS.
- **SQS Queue**: Buffers file pointers for processing.
- **Lambda Orchestrator**: Triggered by EventBridge schedule (cron), checks SQS, launches EC2 if needed.
- **EC2 Worker**: Receives the SQS message (row id) via user data, updates DynamoDB status to `FINISHED`, and auto-terminates.

## Architecture Flow
1. **PutItem** into DynamoDB with `status = PENDING`.
2. **EventBridge Pipe** forwards to SQS if status is PENDING.
3. **SQS** accumulates messages.
4. **EventBridge Rule** triggers Lambda every 5 minutes (or work hours via cron).
5. **Lambda**:
   - Receives a message from SQS (extracts row id)
   - Checks for running EC2 with tag `Role=rag-worker`
   - If none, launches EC2 (t3.micro) in the isolated VPC/subnet/SG, passing row id in user data
6. **EC2**:
   - On boot, reads row id from user data
   - Updates DynamoDB row to `status = FINISHED` using AWS CLI
   - Auto-terminates after 5 minutes
   - Instance is tagged with `Name=rag-worker-<row_id>` for easy identification

## Terraform Structure
```
main.tf
variables.tf
outputs.tf
modules/
  vpc/           # VPC, subnet, security group
  dynamodb/      # DynamoDB table + GSI
  sqs/           # SQS queue
  eventbridge/   # EventBridge Pipe + IAM
  ec2/           # AMI lookup
  lambda/        # Lambda function, IAM, env
  eventbridge_lambda/ # EventBridge rule to trigger Lambda
```

## Environment Variables & Parameters
- **Lambda** receives all required parameters as environment variables:
  - `SQS_QUEUE_URL`, `DYNAMODB_TABLE_NAME`, `EC2_TAG_KEY`, `EC2_TAG_VALUE`, `EC2_AMI_ID`, `EC2_INSTANCE_TYPE`, `EC2_AUTOTERMINATE_MINUTES`, `EC2_SUBNET_ID`, `EC2_SECURITY_GROUP_ID`
- **EC2** is launched with user data that:
  - Receives the row id
  - Updates DynamoDB status to `FINISHED`
  - Shuts down after 5 minutes

## Setup & Deployment
1. **Configure AWS credentials/profile** as described earlier.
2. **Initialize Terraform:**
   ```sh
   terraform init
   ```
3. **Plan and apply:**
   ```sh
   terraform plan
   terraform apply
   ```
4. **Lambda packaging:**
   - Place your `lambda_function.py` in `modules/lambda/build/` (Terraform will zip it automatically).

## Testing the Flow
1. **Add a row to DynamoDB:**
   ```sh
   aws dynamodb put-item \
     --table-name <TABLE_NAME> \
     --item '{"id": {"S": "test1"}, "status": {"S": "PENDING"}}'
   ```
2. **Observe:**
   - SQS receives the message
   - Lambda is triggered by EventBridge rule
   - Lambda launches EC2 (if none running)
   - EC2 instance is named `rag-worker-<row_id>` and updates DynamoDB
   - EC2 auto-terminates after 5 minutes
3. **Check DynamoDB:**
   - The row's status should be updated to `FINISHED`

## Notes & Best Practices
- **VPC isolation** ensures your tests do not interfere with other resources.
- **EC2 instance is named** for easy identification in the AWS Console.
- **IAM roles** are scoped for least privilege for Lambda, EC2, and EventBridge.
- **Security group** allows SSH for testing (restrict in production).
- **All resources are tagged** for cost and environment tracking.
- **No default VPC required**—all networking is managed by Terraform.

## Troubleshooting
- **No messages in SQS:** Ensure you are adding items to DynamoDB with `status = PENDING`.
- **EC2 not launching:** Check Lambda logs for VPC/subnet/security group errors.
- **DynamoDB not updated:** Ensure EC2 has IAM permissions and AWS CLI is available.
- **Resource cleanup:** All resources are managed by Terraform and can be destroyed with `terraform destroy`.

## Next Steps
- Add more sophisticated EC2 worker logic (e.g., process files, handle errors, delete SQS messages after processing).
- Add monitoring/alerts for failed Lambda or EC2 runs.
- Restrict security group rules for production.