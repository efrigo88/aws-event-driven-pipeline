import os
import boto3


def lambda_handler(event, context):
    """Check for running EC2 instances and launch a new one if needed."""
    sqs = boto3.client("sqs")
    ec2 = boto3.client("ec2")

    # Get environment variables
    region = os.environ["REGION"]
    sqs_queue_url = os.environ["SQS_QUEUE_URL"]
    dynamodb_table = os.environ["DYNAMODB_TABLE"]
    tag_key = os.environ["EC2_TAG_KEY"]
    tag_value = os.environ["EC2_TAG_VALUE"]
    ami_id = os.environ["EC2_AMI_ID"]
    instance_type = os.environ["EC2_INSTANCE_TYPE"]
    auto_terminate = os.environ["EC2_AUTOTERMINATE_MINUTES"]
    subnet_id = os.environ["EC2_SUBNET_ID"]
    security_group_id = os.environ["EC2_SECURITY_GROUP_ID"]
    s3_bucket_name = os.environ["S3_BUCKET_NAME"]
    key_name = os.environ["EC2_KEY_NAME"]
    instance_profile_name = os.environ["EC2_INSTANCE_PROFILE_NAME"]

    # Check for messages in SQS
    messages = sqs.receive_message(
        QueueUrl=sqs_queue_url,
        MaxNumberOfMessages=1,
        WaitTimeSeconds=0,
        VisibilityTimeout=0  # Makes message visible again right after receive
    ).get("Messages", [])

    if not messages:
        print("No messages in SQS. Exiting.")
        return {"status": "no_messages"}

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

    # Replace the variables in the script template
    user_data = (
        script_template
        .replace("${REGION}", region)
        .replace("${S3_BUCKET_NAME}", s3_bucket_name)
        .replace("${AUTO_TERMINATE}", auto_terminate)
        .replace("${SQS_QUEUE_URL}", sqs_queue_url)
        .replace("${DYNAMODB_TABLE}", dynamodb_table)
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
        InstanceInitiatedShutdownBehavior="terminate",
    )
    print("Launched EC2:", resp["Instances"][0]["InstanceId"])

    return {
        "status": "ec2_launched",
        "instance_id": resp["Instances"][0]["InstanceId"],
    }
