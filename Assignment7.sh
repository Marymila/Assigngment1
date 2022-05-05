#!/bin/bash

amazonLinux2T1AMI="ami-0f9fc25dd2506cf6d"
keypair1="arkadiy-key-NVirginia"
keypair2="arkadiy-key-Ohio"
userdata="Assignment7userdata.txt"

# Task 1. ==============================================================================================================================
# create security group and save returned SG id in a variable
assignment7T1SGid=$(aws ec2 create-security-group --group-name Assignment7T1SG --description "Assignment#7 security group" \
	--query 'GroupId' --output text)

# authorize port 80, 22 in security group
aws ec2 authorize-security-group-ingress --group-name Assignment7T1SG --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-name Assignment7T1SG --protocol tcp --port 22 --cidr 0.0.0.0/0

# create an EC2 task 1 instance
assignment7T1Instanceid=$(aws ec2 run-instances --image-id "$amazonLinux2T1AMI" --instance-type t2.nano \
	--key-name "$keypair1" --associate-public-ip-address --user-data file://$userdata \
	--security-group-ids "$assignment7T1SGid" \
	--tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Assignment7task1}]' \
	--query "Instances[].InstanceId" --output text)

# Task 2. ==================================================================================================================================
# wait
aws ec2 wait instance-status-ok \
	--instance-ids "$assignment7T1Instanceid" \
	--filters "Name=instance-status.reachability,Values=passed" --output text

# create an AMI
aws ec2 create-image \
	--instance-id "$assignment7T1Instanceid" \
	--name "Assignment7AMI" \
	--description "An AMI for Assignment7"

# wait
aws ec2 wait image-available \
	--filters "Name=name,Values=Assignment7AMI" --output text

# ami variable
assignment7NVImageid=$(aws ec2 describe-images --filters "Name=name,Values=Assignment7AMI" --query "Images[].ImageId" --output text)

#create create an EC2 task 2 instance
assignment7T2Instanceid=$(aws ec2 run-instances \
	--image-id "$assignment7NVImageid" \
	--instance-type t2.micro \
	--key-name "$keypair1" \
	--associate-public-ip-address \
	--security-group-ids "$assignment7T1SGid" \
	--tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Assignment7task2}]' \
	--query "Instances[].InstanceId" --output text)

# wait
aws ec2 wait instance-status-ok \
--instance-ids "$assignment7T2Instanceid" \
--filters "Name=instance-status.reachability,Values=passed" --output text

# pub ip variable
assignment7T2Publicip1=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=Assignment7task2" \
	--query "Reservations[].Instances[].PublicIpAddress" --output text)

# ssh
ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=10 -i /Users/arkadiybalakin/Desktop/312/arkadiy-key-NVirginia.pem ec2-user@$assignment7T2Publicip1 cat /usr/share/nginx/html/index.html

# copy image
aws ec2 copy-image \
	--region "us-east-2" \
	--name "Assignment7AMI" \
	--source-region us-east-1 \
  --source-image-id "$assignment7NVImageid" \
	--description "This is my copied image."

export AWS_DEFAULT_REGION=us-east-2

# wait
aws ec2 wait image-available \
	--filters "Name=name,Values=Assignment7AMI" --output text

# create security group and save returned SG id in a variable
assignment7T2SGid=$(aws ec2 create-security-group --group-name Assignment7SG --description "Assignment#7 security group" \
	--query 'GroupId' --output text)

# authorize port 80, 22 in security group
aws ec2 authorize-security-group-ingress --group-name Assignment7SG --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-name Assignment7SG --protocol tcp --port 22 --cidr 0.0.0.0/0

# describe image ohio
assignment7OImageid=$(aws ec2 describe-images --filters "Name=name,Values=Assignment7AMI" --query "Images[].ImageId" --output text)

# create an EC2 task 2 Ohio instance
assignment7T22Instanceid=$(aws ec2 run-instances --image-id "$assignment7OImageid" --instance-type t2.micro \
	--key-name "$keypair2" --associate-public-ip-address \
	--security-group-ids "$assignment7T2SGid" \
	--tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Assignment7task2}]' \
	--query "Instances[].InstanceId" --output text)

# wait
aws ec2 wait instance-status-ok \
	--instance-ids "$assignment7T22Instanceid" \
	--filters "Name=instance-status.reachability,Values=passed" --output text

# pub ip variable
assignment7T22Publicip2=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=Assignment7task2" \
	--query "Reservations[].Instances[].PublicIpAddress" --output text)

# ssh
ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=10 -i /Users/arkadiybalakin/Desktop/312/arkadiy-key-NVirginia.pem ec2-user@$assignment7T22Publicip2 ls -l /usr/share/nginx/html

sleep 20

# Task 3. ====================================================================================================================================
export AWS_DEFAULT_REGION=us-east-1

# pub ip variable
assignment7T1Publicip3=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=Assignment7task1" \
	--query "Reservations[].Instances[].PublicIpAddress" --output text)

# available memory
ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=10 -i /Users/arkadiybalakin/Desktop/312/arkadiy-key-NVirginia.pem ec2-user@$assignment7T1Publicip3 free -m

sleep 20

# stop
aws ec2 stop-instances --instance-ids "$assignment7T1Instanceid"

# wait
aws ec2 wait instance-stopped \
  --instance-ids "$assignment7T1Instanceid"

# resize
aws ec2 modify-instance-attribute \
	--instance-id "$assignment7T1Instanceid" \
	--instance-type "{\"Value\": \"t2.micro\"}"

# start
aws ec2 start-instances --instance-ids "$assignment7T1Instanceid"

# wait
aws ec2 wait instance-status-ok \
	--instance-ids "$assignment7T1Instanceid" \
	--filters "Name=instance-status.reachability,Values=passed" --output text

# pub ip variable
assignment7T1Publicip4=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=Assignment7task1" \
	--query "Reservations[].Instances[].PublicIpAddress" --output text)

# available memory
ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=10 -i /Users/arkadiybalakin/Desktop/312/arkadiy-key-NVirginia.pem ec2-user@$assignment7T1Publicip4 free -m
