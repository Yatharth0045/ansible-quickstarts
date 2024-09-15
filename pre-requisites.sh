#!/bin/bash

set -e

## Use kk profile
echo 'Loading AWS Profile: KodeKloud'
export AWS_PROFILE='kodekloud'
export AWS_REGION='us-east-1'

## Setting variables
export KEY_NAME='kk-yatharth'
export KEY_PAIR_PATH="${HOME}/Downloads/${KEY_NAME}.pem"
export ZONE='us-east-1d'
export AL_2023_AMI_AMD='ami-0182f373e66f89c85'
export UBUNTU_AMI_AMD='ami-0e86e20dae9224db8'
export AL_2023_AMI_ARM='ami-0b947c5d5516fa06e'
export UBUNTU_AMI_ARM='ami-096ea6a12ea24a797'
export AMD_INSTANCE_TYPE='t3.medium'
export ARM_INSTANCE_TYPE='t4g.medium'
export AL_2023_USER='ec2-user'
export UBUNTU_USER='ubuntu'

## Create key pair
echo '⏳ Creating key pair ...'
if [ -f "${KEY_PAIR_PATH}" ]; then
    echo "⏳ Removing existing key file : ${KEY_PAIR_PATH}"
    rm ${KEY_PAIR_PATH}
fi
touch ${KEY_PAIR_PATH}
aws ec2 create-key-pair --key-name ${KEY_NAME} --query 'KeyMaterial' --output text > ${KEY_PAIR_PATH}
echo "✅ Downloaded key pair : ${KEY_PAIR_PATH}"
echo "⏳ Changing permissions for key: ${KEY_PAIR_PATH}"
sudo chmod 400 ${KEY_PAIR_PATH}

## Export vpc and subnet id
export VPC_ID=$(aws ec2 describe-vpcs --query "Vpcs[*].{ID:VpcId,CIDR:CidrBlock}" --output json | jq -r '.[0] | .ID')
echo "✅ Fetched VPC : ID is ${VPC_ID}"
export SUBNET_ID=$(aws ec2 describe-subnets --query "Subnets[0].SubnetId" --output json | jq -r '.')
# export SUBNET_ID=$(aws ec2 describe-subnets --query "Subnets[*].{ID:SubnetId,VPC:VpcId,CIDR:CidrBlock,AZ:AvailabilityZone}" --output json | jq -r --arg ZONE "$ZONE" '.[] | select(.AZ == $ZONE) | .ID ')
echo "✅ Fetched Subnet in zone $ZONE : ID is ${SUBNET_ID}"

## Create controller node sg
echo "⏳ Creating Sg for contorller node .... "
export CONTROLLER_SG=$(aws ec2 create-security-group --group-name ansible-controller-sg --description "My security group for Ansible EC2 instance" --vpc-id ${VPC_ID} | jq -r '.GroupId')
echo "✅ Created Security group for controller node : ID is ${CONTROLLER_SG}"

echo "⏳ Opening port 22 in controller sg .... "
export RESULT_CONTROLLER_PORT_22=$(aws ec2 authorize-security-group-ingress --group-id ${CONTROLLER_SG} --protocol tcp --port 22 --cidr 0.0.0.0/0 | jq -r '.Return')
echo "✅ Opened port 22 for controller and worker node"

## Create worker node sg
echo "⏳ Creating Sg for worker node .... "
export WORKER_SG=$(aws ec2 create-security-group --group-name ansible-worker-sg --description "My security group for EC2 worker instance" --vpc-id ${VPC_ID} | jq -r '.GroupId')
echo "✅ Created Security group for worker node : ID is ${WORKER_SG}"

echo "⏳ Opening port 22 in worker sg .... "
export RESULT_WORKER_PORT_22=$(aws ec2 authorize-security-group-ingress --group-id ${WORKER_SG} --protocol tcp --port 22 --cidr 0.0.0.0/0 | jq -r '.Return')
echo "✅ Opened port 22 for controller and worker node"

## EC2 Controller node
# echo "⏳ Creating EC2 controller instance"
# export CONTROLLER_ID=$(aws ec2 run-instances --image-id ${AL_2023_AMI_AMD} --instance-type ${AMD_INSTANCE_TYPE} --key-name ${KEY_NAME} --security-group-ids ${CONTROLLER_SG} --subnet-id ${SUBNET_ID} --count 1 --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Ansible-controller-node}]' | jq -r '.Instances[0].InstanceId')
# echo "✅ Created controller node: ID is ${CONTROLLER_ID}"
# CONTROLLER_IP=$(aws ec2 describe-instances --instance-ids ${CONTROLLER_ID} --query "Reservations[*].Instances[*].PublicIpAddress" --output text)
# echo "✅ SSH for controller node: ssh -A -i ${KEY_PAIR_PATH} ${AL_2023_USER}@${CONTROLLER_IP}"

## EC2 Worker node
echo "⏳ Creating EC2 Worker node: al2023-amd"
export WORKER_AL_2023_AMD_ID=$(aws ec2 run-instances --image-id ${AL_2023_AMI_AMD} --instance-type ${AMD_INSTANCE_TYPE} --key-name ${KEY_NAME} --security-group-ids ${WORKER_SG} --subnet-id ${SUBNET_ID} --count 1 --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Ansible-al2023-amd-worker-node}]' | jq -r '.Instances[0].InstanceId')
echo "✅ Created worker node for al2023-amd: ID is ${WORKER_AL_2023_AMD_ID}"
WORKER_AL_2023_AMD_IP=$(aws ec2 describe-instances --instance-ids ${WORKER_AL_2023_AMD_ID} --query "Reservations[*].Instances[*].PublicIpAddress" --output text)
echo "✅ SSH for worker node al2023-amd: ssh -i ${KEY_PAIR_PATH} ${AL_2023_USER}@${WORKER_AL_2023_AMD_IP}"

echo "⏳ Creating EC2 Worker node: ubuntu-amd"
export WORKER_UBUNTU_AMD_ID=$(aws ec2 run-instances --image-id ${UBUNTU_AMI_AMD} --instance-type ${AMD_INSTANCE_TYPE} --key-name ${KEY_NAME} --security-group-ids ${WORKER_SG} --subnet-id ${SUBNET_ID} --count 1 --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Ansible-ubuntu-amd-worker-node}]' | jq -r '.Instances[0].InstanceId')
echo "✅ Created worker node for ubuntu-amd: ID is ${WORKER_UBUNTU_AMD_ID}"
WORKER_UBUNTU_AMD_IP=$(aws ec2 describe-instances --instance-ids ${WORKER_UBUNTU_AMD_ID} --query "Reservations[*].Instances[*].PublicIpAddress" --output text)
echo "✅ SSH for worker node ubuntu-amd: ssh -i ${KEY_PAIR_PATH} ${UBUNTU_USER}@${WORKER_UBUNTU_AMD_IP}"

## Copy key to controller node
# echo "⏳ Copying SSH key to controller node ..."
# scp -i ${KEY_PAIR_PATH} ${KEY_PAIR_PATH} ${AL_2023_USER}@${CONTROLLER_IP}:${KEY_NAME}
# echo "✅ Copied SSH key to controller node"

echo """
Controller Node: ssh -i ${KEY_PAIR_PATH} ${AL_2023_USER}@${CONTROLLER_IP}
Worker Node al2023-amd: ssh -i ${KEY_PAIR_PATH} ${AL_2023_USER}@${WORKER_AL_2023_AMD_IP}
Worker Node ubuntu-amd: ssh -i ${KEY_PAIR_PATH} ${UBUNTU_USER}@${WORKER_UBUNTU_AMD_IP}
""" > .ec2-login
echo "📄 Stored login info to file : .ec2-login"
# echo "⏳ Creating EC2 Worker node: al2023-arm"
# export WORKER_AL_2023_ARM_ID=$(aws ec2 run-instances --image-id ${AL_2023_AMI_ARM} --instance-type ${ARM_INSTANCE_TYPE} --key-name ${KEY_NAME} --security-group-ids ${WORKER_SG} --subnet-id ${SUBNET_ID} --count 1 --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Ansible-al2023-arm-worker-node}]' | jq -r '.Instances[0].InstanceId')
# echo "✅ Created worker node for al2023-arm: ID is ${WORKER_AL_2023_ARM_ID}"
# WORKER_AL_2023_ARM_IP=$(aws ec2 describe-instances --instance-ids ${WORKER_AL_2023_ARM_ID} --query "Reservations[*].Instances[*].PublicIpAddress" --output text)
# echo "✅ IP for worker node al2023-arm: ${WORKER_AL_2023_ARM_IP}"

# echo "⏳ Creating EC2 Worker node: ubuntu-arm"
# export WORKER_UBUNTU_ARM_ID=$(aws ec2 run-instances --image-id ${UBUNTU_AMI_arm} --instance-type ${ARM_INSTANCE_TYPE} --key-name ${KEY_NAME} --security-group-ids ${WORKER_SG} --subnet-id ${SUBNET_ID} --count 1 --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Ansible-ubuntu-arm-worker-node}]' | jq -r '.Instances[0].InstanceId')
# echo "✅ Created worker node for ubuntu-arm: ID is ${WORKER_UBUNTU_ARM_ID}"
# WORKER_UBUNTU_ARM_IP=$(aws ec2 describe-instances --instance-ids ${WORKER_UBUNTU_ARM_ID} --query "Reservations[*].Instances[*].PublicIpAddress" --output text)
# echo "✅ IP for worker node ubuntu-arm: ${WORKER_UBUNTU_ARM_IP}"
