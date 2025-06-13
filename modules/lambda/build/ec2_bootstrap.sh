#!/bin/bash
exec > /home/ubuntu/user-data.log 2>&1
set -x
cd /home/ubuntu

# Install AWS CLI v2 and jq
apt-get update
apt-get install -y unzip curl jq
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
export PATH=$PATH:/usr/local/bin

echo '${MESSAGE_JSON}' > /home/ubuntu/sqs_message.json
echo "Message: ${MESSAGE_JSON}"

ROW_ID=$(jq -r '.Body | fromjson | .dynamodb.Keys.id.S' /home/ubuntu/sqs_message.json)
echo "Extracted row ID: $ROW_ID"

aws dynamodb update-item \
    --table-name ${DYNAMODB_TABLE_NAME} \
    --key "{\"id\":{\"S\":\"$ROW_ID\"}}" \
    --update-expression 'SET #s = :s' \
    --expression-attribute-names '{"#s":"status"}' \
    --expression-attribute-values '{":s":{"S":"FINISHED"}}'
echo "DynamoDB update completed"

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
aws s3 cp /home/ubuntu/user-data.log s3://${S3_BUCKET_NAME}/$TIMESTAMP/run.log
shutdown -h +${AUTO_TERMINATE}