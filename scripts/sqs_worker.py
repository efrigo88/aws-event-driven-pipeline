"""Process SQS messages and manage S3 file operations."""

import json
import logging
import os
import time
from datetime import datetime

import boto3
from botocore.exceptions import ClientError

QUEUE_URL = os.environ["SQS_QUEUE_URL"]
DYNAMODB_TABLE = os.environ["DYNAMODB_TABLE"]
IDLE_MINUTES = int(os.environ["EC2_AUTOTERMINATE_MINUTES"])
REGION = os.environ["REGION"]
S3_BUCKET_NAME = os.environ["S3_BUCKET_NAME"]
LOG_FILE = "/home/ubuntu/sqs_worker.logs"

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    filename=LOG_FILE,
)
logger = logging.getLogger(__name__)

s3 = boto3.client("s3", region_name=REGION)
dynamodb = boto3.client("dynamodb", region_name=REGION)
sqs = boto3.client("sqs", region_name=REGION)


def copy_s3_file(source_path, destination_path):
    """Copy a file from source S3 path to destination S3 path."""
    try:
        # Extract bucket and key from source path
        source_parts = source_path.replace("s3://", "").split("/", 1)
        source_bucket = source_parts[0]
        source_key = source_parts[1]

        # Extract bucket and key from destination path
        dest_parts = destination_path.replace("s3://", "").split("/", 1)
        dest_bucket = dest_parts[0]
        dest_key = dest_parts[1]

        logger.info("Source bucket: %s, key: %s", source_bucket, source_key)
        logger.info("Destination bucket: %s, key: %s", dest_bucket, dest_key)

        # Get the object from source
        try:
            response = s3.get_object(Bucket=source_bucket, Key=source_key)
            logger.info("Successfully retrieved source file")
        except ClientError as e:
            logger.error("Error getting source file: %s", str(e))
            logger.error("Error response: %s", e.response)
            return False

        # Upload to destination
        try:
            s3.put_object(
                Bucket=dest_bucket,
                Key=dest_key,
                Body=response["Body"].read()
            )
            logger.info("Successfully copied to destination")
            return True
        except ClientError as e:
            logger.error("Error uploading to destination: %s", str(e))
            logger.error("Error response: %s", e.response)
            return False

    except (ValueError, IndexError) as e:
        logger.error("Error parsing S3 path: %s", str(e))
        return False


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

        # Get the S3 path from DynamoDB
        response = dynamodb.get_item(
            TableName=DYNAMODB_TABLE, Key={"id": {"S": row_id}}
        )

        if "Item" not in response:
            logger.error("Row %s not found in DynamoDB", row_id)
            return False

        s3_path = response["Item"].get("s3_path", {}).get("S")
        if not s3_path:
            logger.error("No s3_path found for row %s", row_id)
            return False

        logger.info("Source S3 path: %s", s3_path)

        # Construct destination path by replacing 'input' with 'output'
        dest_path = s3_path.replace("/input/", "/output/")
        logger.info("Destination S3 path: %s", dest_path)

        # Copy the file
        if not copy_s3_file(s3_path, dest_path):
            logger.error("Failed to copy file for row %s", row_id)
            return False

        # Update DynamoDB status
        dynamodb.update_item(
            TableName=DYNAMODB_TABLE,
            Key={"id": {"S": row_id}},
            UpdateExpression="SET #s = :s",
            ExpressionAttributeNames={"#s": "status"},
            ExpressionAttributeValues={":s": {"S": "FINISHED"}},
        )
        logger.info("Updated DynamoDB row %s to FINISHED", row_id)
        return True

    except (json.JSONDecodeError, ClientError) as e:
        logger.error("Error processing message: %s", e)
        return False


def main():
    """Main function to poll SQS and process messages."""
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
                logger.info("Deleted message from SQS")
            idle_seconds = 0  # Reset idle timer after processing
        else:
            idle_seconds += 10
        time.sleep(1)

    # Upload logs to S3 before shutdown
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    log_key = f"logs/{timestamp}/run.log"
    try:
        s3.upload_file(LOG_FILE, S3_BUCKET_NAME, log_key)
        logger.info("Uploaded logs to s3://%s/%s", S3_BUCKET_NAME, log_key)
    except (ClientError, IOError) as e:
        logger.error("Failed to upload logs to S3: %s", e)

    logger.info("Idle timeout reached, shutting down.")
    os.system("sudo shutdown -P now")


if __name__ == "__main__":
    main()
