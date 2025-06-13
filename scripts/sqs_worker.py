import os
import time
import json
import logging
import boto3
import botocore
from time import sleep

QUEUE_URL = os.environ["SQS_QUEUE_URL"]
DYNAMODB_TABLE = os.environ["DYNAMODB_TABLE_NAME"]
IDLE_MINUTES = int(os.environ.get("EC2_AUTOTERMINATE_MINUTES", 60))
AWS_REGION = os.environ.get("AWS_REGION", "us-east-1")

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)
file_handler = logging.FileHandler("/home/ubuntu/sqs_worker.logs")
file_handler.setFormatter(
    logging.Formatter("%(asctime)s - %(name)s - %(levelname)s - %(message)s")
)
logger.addHandler(file_handler)


def process_message(msg):
    """Process a single SQS message and update DynamoDB status."""
    body = msg["Body"]
    try:
        body_json = json.loads(body)
        row_id = (
            body_json.get("dynamodb", {})
            .get("Keys", {})
            .get("id", {})
            .get("S", "")
        )
        logger.info("Processing row_id: %s", row_id)
        sleep(10)  # Simulate processing time
        dynamodb = boto3.client("dynamodb", region_name=AWS_REGION)
        dynamodb.update_item(
            TableName=DYNAMODB_TABLE,
            Key={"id": {"S": row_id}},
            UpdateExpression="SET #s = :s",
            ExpressionAttributeNames={"#s": "status"},
            ExpressionAttributeValues={":s": {"S": "FINISHED"}},
        )
        logger.info("Updated DynamoDB row %s to FINISHED", row_id)
    except (json.JSONDecodeError, botocore.exceptions.BotoCoreError) as e:
        logger.error("Error processing message: %s", e)


def main():
    """Poll SQS for messages and process them, terminating after idle timeout."""
    sqs = boto3.client("sqs", region_name=AWS_REGION)
    idle_seconds = 0
    while idle_seconds < IDLE_MINUTES * 60:
        resp = sqs.receive_message(
            QueueUrl=QUEUE_URL, MaxNumberOfMessages=1, WaitTimeSeconds=10
        )
        messages = resp.get("Messages", [])
        if messages:
            for msg in messages:
                process_message(msg)
                sqs.delete_message(
                    QueueUrl=QUEUE_URL, ReceiptHandle=msg["ReceiptHandle"]
                )
            idle_seconds = 0  # Reset idle timer after processing
        else:
            idle_seconds += 10
        time.sleep(1)
    logger.info("Idle timeout reached, shutting down.")
    os.system("sudo shutdown -P now")


if __name__ == "__main__":
    main()
