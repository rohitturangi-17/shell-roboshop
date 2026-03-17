#!/bin/bash

AMI_ID="ami-0220d79f3f480ecf5"
SG_ID="sg-09edf8959063cdcee"
ZONE_ID="Z092194813ENPXN9CPPX7"
DOMAIN_NAME="turangi.site"

for instance in $@
do
    INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type t3.micro \
    --security-group-ids $SG_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name, Value=$instance}]" \
    --query "Instances[0].InstanceId" \
    --output text)

    if [ "$instance" != "frontend" ]
    then
        IP=$(aws ec2 describe-instances \
        --instance-ids $INSTANCE_ID \
        --query "Reservations[0].Instances[0].PrivateIpAddress" \
        --output text)

        RECORD_NAME="$instance.$DOMAIN_NAME"
    else
        IP=$(aws ec2 describe-instances \
        --instance-ids $INSTANCE_ID \
        --query "Reservations[0].Instances[0].PublicIpAddress" \
        --output text)

        RECORD_NAME="$DOMAIN_NAME"
    fi

    echo "$instance IP address: $IP"

    aws route53 change-resource-record-sets \
    --output json \
    --hosted-zone-id $ZONE_ID \
    --change-batch "{
        \"Comment\": \"Creating or Updating record\",
        \"Changes\": [{
            \"Action\": \"UPSERT\",
            \"ResourceRecordSet\": {
                \"Name\": \"$RECORD_NAME\",
                \"Type\": \"A\",
                \"TTL\": 1,
                \"ResourceRecords\": [{
                    \"Value\": \"$IP\"
                }]
            }
        }]
    }"

done