#!/bin/bash

#List of Variables:
#1. SG region:
regionNVirginia="us-east-1"
regionOhio="us-east-2"
#2. EC2 AMI (Amazon Machine Image ID, see in AWS AMI catalogue):
amazonLinux2AMI="ami-0f9fc25dd2506cf6d"
#3. Instance type:
ec2typeNVirginia="t2.nano"
ec2typeNVirginia1="t2.nano"
ec2typeOhio="t2.nano"
#4. Number of created Instances:
ec2numberNVirginia="1"
ec2numberNVirginia1="1"
ec2numberOhio="1"
#5. Key name:
keypair="linuxkey"
keypairOhio="linuxkeyOH.pem"
#6. UserData file for Ngnix:
userdata="userdata.txt"

#BLOCK A (Create infrastructure in AWS N.Virginia Region).

#Step1: Set N.Virginia AWS Region (us-east-1):
aws configure set region "$regionNVirginia"

#Step2: Security group ID (create SG and save returned SG ID in a variable):
SGAssignment7=$(aws ec2 create-security-group --group-name SGAssignment7 --description "Security Group Assignment7" --region "$regionNVirginia" --query 'GroupId' --output text)

#Step3: Create Security group Inbound Rules (authorize port 80 (http) and port 22 (ssh) in Security group for all internet trafic (all IPs)):
aws ec2 authorize-security-group-ingress --group-name SGAssignment7 \
--region "$regionNVirginia" \
--ip-permissions IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=0.0.0.0/0}] \
IpProtocol=tcp,FromPort=80,ToPort=80,IpRanges=[{CidrIp=0.0.0.0/0}]

#Step4: create a t2.nano instance in the N. Virginia region (Amazon Linux 2 AMI, public IP)
aws ec2 run-instances \
    --image-id "$amazonLinux2AMI" \
    --instance-type "$ec2typeNVirginia" \
    --count "$ec2numberNVirginia" \
    --key-name "$keypair" \
    --security-group-ids "$SGAssignment7" \
    --associate-public-ip-address \
    --user-data file://$userdata \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Assignment7task1}]'

#Step5: Get Instance ID of the nstance created in Step4:
instanceID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=Assignment7task1" --query Reservations[*].Instances[*].[InstanceId] --output text)

#Step6: Wait untill EC2 launches (becomes running state):
aws ec2 wait instance-running \
    --instance-ids "$instanceID"

#Step7: create AMI image from the instance created in Step3:
aws ec2 create-image \
    --instance-id "$instanceID" \
    --name "MyAMI" \
    --description "An AMI for my server" \
    --tag-specifications 'ResourceType=image,Tags=[{Key=Name,Value=MyAMI}]' 'ResourceType=snapshot,Tags=[{Key=Name,Value=MySnapshot}]'

#Step8: Get AMI image ID from AMI created in Step7:
amiID=$(aws ec2 describe-images --filters "Name=tag:Name,Values=MyAMI" --query 'Images[*].[ImageId]' --output text)

#Step9: Wait untill AMI launches (becomes available):
aws ec2 wait image-available \
    --image-ids "$amiID"

#Step10: Get AMI Snapshot ID:
snapshotID=$(aws ec2 describe-snapshots --filters Name=tag:Name,Values=MySnapshot --query "Snapshots[*].[SnapshotId]" --output text)

#Step11: Wait untill AMI snapshot launches (becomes available):
aws ec2 wait snapshot-completed \
    --snapshot-ids "$snapshotID"

#Step12: Create a new instance from your AMI image in the N. Virginia region:
aws ec2 run-instances \
    --image-id "$amiID" \
    --instance-type "$ec2typeNVirginia1" \
    --count "$ec2numberNVirginia1" \
    --key-name "$keypair" \
    --security-group-ids "$SGAssignment7" \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Assignment7task2}]'

#Step13: Get Instance ID of the nstance created in Step12:
instanceID2=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=Assignment7task2" --query Reservations[*].Instances[*].[InstanceId] --output text)


#Step14: Copy AMI image from the N. Virginia region to the Ohio region:
aws ec2 copy-image \
    --region "$regionOhio" \
    --name ami-name \
    --source-region "$regionNVirginia" \
    --source-image-id "$amiID" \
    --description "This is my copied image"
    
#BLOCK B (Create infrustructure in AWS Ohio Region).

#Step 15: Set Ohio AWS Region (us-east-2):
aws configure set region "$regionOhio"

#Step16: Get AMI image ID from AMI created in Step14:
amiID2=$(aws ec2 describe-images --region "$regionOhio" --filters "Name=name,Values=ami-name" --query 'Images[*].[ImageId]' --output text)

#Step17: Wait untill AMI launches (becomes available):
aws ec2 wait image-available \
    --image-ids "$amiID2"

#Step18: Security group ID (create SG and save returned SG ID in a variable):
SGAssignment7Ohio=$(aws ec2 create-security-group --group-name SGAssignment7Ohio --description "Security Group Assignment7 in Ohio" --region "$regionOhio" --query 'GroupId' --output text)

#Step19: Security group Inbound Rules (authorize port 80 (http) and port 22 (ssh) in Security group for all internet trafic (all IPs)):
aws ec2 authorize-security-group-ingress --group-name SGAssignment7Ohio \
--region "$regionOhio" \
--ip-permissions IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=0.0.0.0/0}] \
IpProtocol=tcp,FromPort=80,ToPort=80,IpRanges=[{CidrIp=0.0.0.0/0}]

#Step20: Create a new instance from AMI image created in Step14 (in the Ohio region):
aws ec2 run-instances \
    --image-id "$amiID2" \
    --instance-type "$ec2typeOhio" \
    --count "$ec2numberOhio" \
    --key-name "$keypairOhio" \
    --security-group-ids "$SGAssignment7Ohio" \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Assignment7task2Ohio}]'

#Step21: Get Instance ID of the nstance created in Step3:
instanceID2=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=Assignment7task2Ohio" --query Reservations[*].Instances[*].[InstanceId] --output text)

#Step22: Wait untill EC2 launches (becomes running state):
aws ec2 wait instance-running \
    --instance-ids "$instanceID2"



