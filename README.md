# AWS Event-Driven Pipeline (DynamoDB → EventBridge → SQS → Lambda → EC2)

## Overview
This Terraform project provisions a fully isolated, event-driven pipeline for file processing and status tracking. The architecture includes:

- **VPC, Subnet, Security Group**: All resources are isolated in a dedicated VPC for safe testing.
- **DynamoDB Table**: Stores file pointers and status, with a GSI on `status`.
- **EventBridge Pipe**: Forwards new DynamoDB rows with `status = PENDING` to SQS.
- **SQS Queue**: Buffers file pointers for processing.
- **Lambda Orchestrator**: Triggered by EventBridge schedule (every minute), checks SQS for messages, launches EC2 if needed.
- **EC2 Worker**: Downloads worker script from S3, processes SQS messages, updates DynamoDB status to `FINISHED`, and auto-terminates.

## Architecture Flow
1. **PutItem** into DynamoDB with `status = PENDING` and `s3_path` pointing to input file.
2. **EventBridge Pipe** forwards to SQS if status is PENDING.
3. **SQS** accumulates messages.
4. **EventBridge Rule** triggers Lambda every minute.
5. **Lambda**:
   - Checks SQS for messages
   - If no messages, exits without launching EC2
   - If messages exist, checks for running EC2 with tag `Role=rag-worker`
   - If none running, launches EC2 (t3.micro) in the isolated VPC/subnet/SG
6. **EC2**:
   - On boot, downloads worker script from S3
   - Sets up logging to `/home/ubuntu/sqs_worker.logs`
   - Processes SQS messages:
     - Gets S3 path from DynamoDB
     - Copies file from input to output path
     - Updates DynamoDB status to `FINISHED`
   - Auto-terminates after configurable idle period (default: 5 minutes)

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
  ec2/           # AMI lookup, key pair, IAM role
  lambda/        # Lambda function, IAM, env
  eventbridge_lambda/ # EventBridge rule to trigger Lambda
  s3/            # S3 bucket for worker script and logs
```

## Environment Variables & Parameters
- **Lambda** receives all required parameters as environment variables:
  - `SQS_QUEUE_URL`, `DYNAMODB_TABLE_NAME`, `EC2_TAG_KEY`, `EC2_TAG_VALUE`
  - `EC2_AMI_ID`, `EC2_INSTANCE_TYPE`, `EC2_AUTOTERMINATE_MINUTES`
  - `EC2_SUBNET_ID`, `EC2_SECURITY_GROUP_ID`, `S3_BUCKET_NAME`
  - `EC2_KEY_NAME`, `EC2_INSTANCE_PROFILE_NAME`
- **EC2** is launched with user data that:
  - Downloads worker script from S3
  - Sets up file-based logging
  - Configures environment variables
  - Runs the worker script

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

## Testing the Flow
1. **Add a row to DynamoDB:**
   ```sh
   aws dynamodb put-item \
     --table-name <TABLE_NAME> \
     --item '{
       "id": {"S": "test1"},
       "status": {"S": "PENDING"},
       "s3_path": {"S": "s3://your-bucket/data/input/client_1/test_file_1.txt"}
     }'
   ```
2. **Observe:**
   - SQS receives the message
   - Lambda is triggered by EventBridge rule
   - Lambda checks SQS and launches EC2 if needed
   - EC2 downloads worker script from S3
   - Worker processes messages and updates DynamoDB
   - EC2 auto-terminates after idle timeout
3. **Check DynamoDB:**
   - The row's status should be updated to `FINISHED`
4. **Check S3:**
   - Input file should be copied to output path
   - Output path should be: `s3://your-bucket/data/output/client_1/test_file_1.txt`
5. **Check Logs:**
   - Worker logs are available at `/home/ubuntu/sqs_worker.logs` on the EC2 instance
   - Lambda logs are available in CloudWatch Logs

## Notes & Best Practices
- **VPC isolation** ensures your tests do not interfere with other resources.
- **EC2 instance is named** for easy identification in the AWS Console.
- **IAM roles** are scoped for least privilege for Lambda, EC2, and EventBridge.
- **Security group** allows SSH for testing (restrict in production).
- **All resources are tagged** for cost and environment tracking.
- **No default VPC required**—all networking is managed by Terraform.
- **File-based logging** for easy debugging and monitoring.
- **Efficient resource usage** - EC2 only launched when there are messages to process.
- **Robust error handling** in worker script for S3 operations and path parsing.

## Troubleshooting
- **No messages in SQS:** Ensure you are adding items to DynamoDB with `status = PENDING`.
- **EC2 not launching:** Check Lambda logs for VPC/subnet/security group errors.
- **DynamoDB not updated:** Ensure EC2 has IAM permissions and check worker logs.
- **Worker script not found:** Verify S3 bucket permissions and script upload.
- **S3 copy fails:** Check IAM permissions and verify S3 paths in DynamoDB.
- **Resource cleanup:** All resources are managed by Terraform and can be destroyed with `terraform destroy`.

## Next Steps
- Add CloudWatch alarms for failed Lambda or EC2 runs.
- Implement more sophisticated error handling and retries.
- Add monitoring for SQS queue depth and processing times.
- Restrict security group rules for production.
- Consider implementing dead-letter queues for failed messages.
- Add S3 event notifications for file processing status.