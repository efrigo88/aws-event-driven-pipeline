import os
import boto3
import json


def lambda_handler(event, context):
    sqs = boto3.client("sqs")
    ec2 = boto3.client("ec2")
    queue_url = os.environ["SQS_QUEUE_URL"]
    dynamodb_table_name = os.environ["DYNAMODB_TABLE_NAME"]
    tag_key = os.environ["EC2_TAG_KEY"]
    tag_value = os.environ["EC2_TAG_VALUE"]
    ami_id = os.environ["EC2_AMI_ID"]
    instance_type = os.environ["EC2_INSTANCE_TYPE"]
    auto_terminate = int(os.environ["EC2_AUTOTERMINATE_MINUTES"])
    subnet_id = os.environ["EC2_SUBNET_ID"]
    security_group_id = os.environ["EC2_SECURITY_GROUP_ID"]

    # Receive one message from SQS
    messages = sqs.receive_message(
        QueueUrl=queue_url, MaxNumberOfMessages=1, WaitTimeSeconds=0
    ).get("Messages", [])

    if not messages:
        print("No messages in SQS. Exiting.")
        return {"status": "no_messages"}

    message = messages[0]
    message_body = message["Body"]
    # Try to extract row id from message body
    try:
        body_json = json.loads(message_body)
        row_id = body_json.get("id", "")
    except json.JSONDecodeError:
        row_id = message_body  # fallback: just pass the body

    # Check for running EC2 with the tag
    filters = [
        {"Name": f"tag:{tag_key}", "Values": [tag_value]},
        {"Name": "instance-state-name", "Values": ["pending", "running"]},
    ]
    instances = ec2.describe_instances(Filters=filters)
    running = [i for r in instances["Reservations"] for i in r["Instances"]]
    if running:
        print("EC2 already running. Exiting.")
        return {"status": "ec2_running"}

    # Pass the row_id/message to EC2 via user data
    user_data = f"""#!/bin/bash
echo '{row_id}' > /tmp/sqs_row_id.txt
aws dynamodb update-item \
    --table-name  {dynamodb_table_name} \
    --key '{{"id":{{"S":"{row_id}"}}}}' \
    --update-expression 'SET #s = :s' \
    --expression-attribute-names '{{"#s":"status"}}' \
    --expression-attribute-values '{{":s":{{"S":"FINISHED"}}}}' \
    --region {os.environ.get('AWS_DEFAULT_REGION', 'us-east-1')}
shutdown -h +{auto_terminate}
"""

    resp = ec2.run_instances(
        ImageId=ami_id,
        InstanceType=instance_type,
        MinCount=1,
        MaxCount=1,
        SubnetId=subnet_id,
        SecurityGroupIds=[security_group_id],
        TagSpecifications=[
            {
                "ResourceType": "instance",
                "Tags": [
                    {"Key": "Name", "Value": "rag-worker-instance"},
                    {"Key": tag_key, "Value": tag_value},
                ],
            }
        ],
        UserData=user_data,
    )
    print("Launched EC2:", resp["Instances"][0]["InstanceId"])
    return {
        "status": "ec2_launched",
        "instance_id": resp["Instances"][0]["InstanceId"],
        "row_id": row_id,
    }
