#!/bin/bash

set -e

## Use kk profile
echo 'Loading AWS Profile: KodeKloud'
export AWS_PROFILE='kodekloud'
export AWS_REGION='us-east-1'

## Setting variables
export KEY_NAME='kk-yatharth'
export KEY_PAIR_PATH="${HOME}/Downloads/${KEY_NAME}.pem"

## Delete Key Pair
echo '⏳ Deleting key pair'
aws ec2 delete-key-pair --key-name ${KEY_NAME}
if [ -f "${KEY_PAIR_PATH}" ]; then
    rm ${KEY_PAIR_PATH}
    echo "✅ File deleted : ${KEY_PAIR_PATH}"
else
    echo "✅ No File to delete on local."
fi
echo "✅ Deleted key pair : ${KEY_NAME}"

## Delete EC2 instances
echo '⏳ Deleting EC2 instances'
export INSTANCE_IDS=$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" --query "Reservations[*].Instances[*].InstanceId" --output text)
export INSTANCE_SGS=$(aws ec2 describe-instances --query "Reservations[*].Instances[*].SecurityGroups[*].GroupId" --output text | tr '\t' '\n' | sort | uniq | tr '\n' '\t') 

if [ -z "$INSTANCE_IDS" ]; then
    echo "✅ No EC2 to Delete"
    echo "⏳ Check and Delete security groups manually"
else
    export DELETED_IDS=$(aws ec2 terminate-instances --instance-ids ${INSTANCE_IDS} | jq '.TerminatingInstances[].InstanceId')
    echo "✅ Deleted EC2s with IDs : ${DELETED_IDS}"
    ## Deleting security group
    echo "⏳ Delete security groups ${INSTANCE_SGS} manually"
fi

