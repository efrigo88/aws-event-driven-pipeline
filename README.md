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
  eventbridge/     # EventBridge Pipe + IAM
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

## Next Steps
- Add Lambda and EC2 orchestration modules for the rest of the pipeline. 