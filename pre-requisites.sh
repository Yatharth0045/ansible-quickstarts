#!/bin/bash

set -e

## Use kk profile
echo 'Loading AWS Profile: KodeKloud'
export AWS_PROFILE='kodekloud'
export AWS_REGION='us-east-1'

## Setting variables
export KEY_NAME='kk-yatharth'
export KEY_PAIR_PATH="${HOME}/Downloads/${KEY_NAME}.pem"
export ZONE='us-east-1b'
export AL_2023_AMI_AMD='ami-0182f373e66f89c85'
export UBUNTU_AMI_AMD='ami-0e86e20dae9224db8'
export AL_2023_AMI_ARM='ami-0b947c5d5516fa06e'
export UBUNTU_AMI_ARM='ami-096ea6a12ea24a797'
export AMD_INSTANCE_TYPE='t3.medium'
export ARM_INSTANCE_TYPE='t4g.medium'
export AL_2023_USER='ec2-user'
export UBUNTU_USER='ubuntu'

create_key_pair() {
    ## Create key pair
    echo '⏳ Creating key pair ...'
    if aws ec2 describe-key-pairs --key-name ${KEY_NAME} > /dev/null 2>&1; then
        echo "✅ Key pair ${KEY_NAME} already exists. No need to create again."
    else
        echo "⚠️ Key pair ${KEY_NAME} does not exist. Creating a new one"
        if [ -f "${KEY_PAIR_PATH}" ]; then
            echo "⏳ Removing existing key file : ${KEY_PAIR_PATH}"
            rm ${KEY_PAIR_PATH}
        fi
        touch ${KEY_PAIR_PATH}
        aws ec2 create-key-pair --key-name ${KEY_NAME} --query 'KeyMaterial' --output text > ${KEY_PAIR_PATH}
        echo "✅ Downloaded key pair : ${KEY_PAIR_PATH}"
        echo "⏳ Changing permissions for key: ${KEY_PAIR_PATH}"
        sudo chmod 400 ${KEY_PAIR_PATH}
    fi
}

create_sg() {
    export NODE_NAME=$1
    echo "⏳ Creating Sg for $NODE_NAME node .... "
    if aws ec2 describe-security-groups --group-names ansible-${NODE_NAME}-sg > /dev/null 2>&1; then
        echo "✅ Security group ansible-${NODE_NAME}-sg already exists, skipping creation"
        export SG_ID=$(aws ec2 describe-security-groups --group-names ansible-controller-sg | jq -r '.SecurityGroups[0] | .GroupId')
    else
        echo "Security group ansible-${NODE_NAME}-sg does not exist, creating a new one"
        export SG_ID=$(aws ec2 create-security-group --group-name ansible-${NODE_NAME}-sg --description "My security group for Ansible EC2 instance" --vpc-id ${VPC_ID} | jq -r '.GroupId')
        echo "✅ Created Security group for controller node : ID is ${SG_ID}"
        echo "⏳ Opening all ports in ${NODE_NAME} sg .... "
        export RESULT=$(aws ec2 authorize-security-group-ingress --group-id ${SG_ID} --protocol -1 --port all --cidr 0.0.0.0/0 | jq -r '.Return')
        echo "✅ Opened all ports for ${NODE_NAME}"
    fi
}

launch_ec2() {
    export NODE_NAME=$1
    export AMI_ID=$2
    export INSTANCE_TYPE=$3
    export SG_ID=$4
    export USER=${5:-'ec2-user'}
    export KEY_NAME=${6:-'kk-yatharth'}
    echo "⏳ Creating EC2 ${NODE_NAME} instance"
    export NODE_ID=$(aws ec2 run-instances --image-id ${AMI_ID} --instance-type ${INSTANCE_TYPE} --key-name ${KEY_NAME} --security-group-ids ${SG_ID} --subnet-id ${SUBNET_ID} --count 1 --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Ansible-${NODE_NAME}-node}]" | jq -r '.Instances[0].InstanceId')
    echo "✅ Created controller node: ID is ${NODE_ID}"
    IP=$(aws ec2 describe-instances --instance-ids ${NODE_ID} --query "Reservations[*].Instances[*].PublicIpAddress" --output text)
    echo "✅ SSH for controller node: ssh -i ${KEY_PAIR_PATH} ${USER}@${IP}"
    echo "${NODE_NAME} : ssh -i ${KEY_PAIR_PATH} ${USER}@${IP}" >> .ec2-login
    echo "📄 Stored login info to file : .ec2-login"
}

copy_key_to_controller() {
    export IP=$1
    export USER=${2:-'ec2-user'}
    export KEY_NAME=${3:-'kk-yatharth'}
    echo "⏳ Copying SSH key to controller node ..."
    sleep 10
    echo "scp -i ${KEY_PAIR_PATH} ${KEY_PAIR_PATH} ${USER}@${IP}:${KEY_NAME}"
    scp -i ${KEY_PAIR_PATH} ${KEY_PAIR_PATH} ${USER}@${IP}:${KEY_NAME}
    echo "✅ Copied SSH key to controller node"
}

## Export vpc and subnet id
export VPC_ID=$(aws ec2 describe-vpcs --query "Vpcs[*].{ID:VpcId,CIDR:CidrBlock}" --output json | jq -r '.[0] | .ID')
echo "✅ Fetched VPC : ID is ${VPC_ID}"
# export SUBNET_ID=$(aws ec2 describe-subnets --query "Subnets[0].SubnetId" --output json | jq -r '.')
export SUBNET_ID=$(aws ec2 describe-subnets --query "Subnets[*].{ID:SubnetId,VPC:VpcId,CIDR:CidrBlock,AZ:AvailabilityZone}" --output json | jq -r --arg ZONE "$ZONE" '.[] | select(.AZ == $ZONE) | .ID ')
echo "✅ Fetched Subnet : ID is ${SUBNET_ID}"

## Creating login file
echo '📄 Creating .ec2-login file'
echo '' > .ec2-login

## Generating key_pair
create_key_pair

## Creating controller node sg
create_sg "controller"
export CONTROLLER_NODE_SG=${SG_ID}

## Creating worker node sg
create_sg "worker"
export WORKER_NODE_SG=${SG_ID}

## Launching controller node
launch_ec2 "controller" "${AL_2023_AMI_AMD}" "${AMD_INSTANCE_TYPE}" "${CONTROLLER_NODE_SG}"
export CONTROLLER_IP=${IP}
copy_key_to_controller "${CONTROLLER_IP}"

## Launching worker nodes for node_exporter
launch_ec2 "al2023-amd" "${AL_2023_AMI_AMD}" "${AMD_INSTANCE_TYPE}" "${WORKER_NODE_SG}"
launch_ec2 "ubuntu-amd" "${UBUNTU_AMI_AMD}" "${AMD_INSTANCE_TYPE}" "${WORKER_NODE_SG}" "${UBUNTU_USER}"
launch_ec2 "al2023-arm" "${AL_2023_AMI_ARM}" "${ARM_INSTANCE_TYPE}" "${WORKER_NODE_SG}"
launch_ec2 "ubuntu-arm" "${UBUNTU_AMI_ARM}" "${ARM_INSTANCE_TYPE}" "${WORKER_NODE_SG}" "${UBUNTU_USER}"

## Launching elasticsearch nodes
launch_ec2 "elastic_search_master" "${AL_2023_AMI_AMD}" "${AMD_INSTANCE_TYPE}" "${WORKER_NODE_SG}"
launch_ec2 "elastic_search_data" "${AL_2023_AMI_AMD}" "${AMD_INSTANCE_TYPE}" "${WORKER_NODE_SG}"
launch_ec2 "elastic_search_client" "${AL_2023_AMI_AMD}" "${AMD_INSTANCE_TYPE}" "${WORKER_NODE_SG}"
