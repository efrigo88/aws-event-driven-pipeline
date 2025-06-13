# Lambda Orchestrator (rag_launcher)

This Lambda function is triggered by an EventBridge schedule every 5 minutes. It:
- Checks the SQS queue for messages
- Checks for a running EC2 instance with a specific tag
- Launches a t3.micro EC2 instance with auto-termination if needed

## Environment Variables
- `SQS_QUEUE_URL`: SQS queue URL
- `EC2_TAG_KEY`: Tag key to identify worker EC2s
- `EC2_TAG_VALUE`: Tag value to identify worker EC2s
- `EC2_AMI_ID`: AMI ID to use for EC2
- `EC2_INSTANCE_TYPE`: EC2 instance type (default: t3.micro)
- `EC2_AUTOTERMINATE_MINUTES`: Minutes after which EC2 will auto-terminate (default: 5) 