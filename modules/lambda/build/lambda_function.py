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
    s3_bucket_name = os.environ["S3_BUCKET_NAME"]
    key_name = os.environ["EC2_KEY_NAME"]
    instance_profile_name = os.environ["EC2_INSTANCE_PROFILE_NAME"]

    # Receive one message from SQS
    messages = sqs.receive_message(
        QueueUrl=queue_url, MaxNumberOfMessages=1, WaitTimeSeconds=0
    ).get("Messages", [])

    if not messages:
        print("No messages in SQS. Exiting.")
        return {"status": "no_messages"}

    message = messages[0]
    message_json = json.dumps(message)
    receipt_handle = message["ReceiptHandle"]

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

    # Read and substitute the shell script template
    with open("/var/task/ec2_bootstrap.sh", "r", encoding="utf-8") as f:
        script_template = f.read()

    user_data = (
        script_template
        .replace("${MESSAGE_JSON}", message_json)
        .replace("${DYNAMODB_TABLE_NAME}", dynamodb_table_name)
        .replace("${S3_BUCKET_NAME}", s3_bucket_name)
        .replace("${AUTO_TERMINATE}", str(auto_terminate))
    )

    resp = ec2.run_instances(
        ImageId=ami_id,
        InstanceType=instance_type,
        MinCount=1,
        MaxCount=1,
        SubnetId=subnet_id,
        SecurityGroupIds=[security_group_id],
        KeyName=key_name,
        IamInstanceProfile={"Name": instance_profile_name},
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

    # Delete the SQS message after EC2 is successfully launched
    sqs.delete_message(QueueUrl=queue_url, ReceiptHandle=receipt_handle)
    print("Deleted SQS message with receipt handle:", receipt_handle)

    return {
        "status": "ec2_launched",
        "instance_id": resp["Instances"][0]["InstanceId"],
    }
