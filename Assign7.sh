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

        #BLOCK A: Create Infrastructure in AWS N.Virginia Region

#Step1: Switch Region to N.Virginia (us-east-1):
export AWS_DEFAULT_REGION="$regionNVirginia"

#Step2: Create Security group:
SGAssignment7=$(aws ec2 create-security-group --group-name SGAssignment7 \
--description "Security Group Assignment7" \
--region "$regionNVirginia" \
--query 'GroupId' --output text)

#Step3: Create Security group Inbound Rules (authorize port 80 (http) and port 22 (ssh) for all internet trafic (all IPs):
aws ec2 authorize-security-group-ingress --group-name SGAssignment7 \
--region "$regionNVirginia" \
--ip-permissions IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=0.0.0.0/0}] \
IpProtocol=tcp,FromPort=80,ToPort=80,IpRanges=[{CidrIp=0.0.0.0/0}]

#Step4: create a t2.nano instance in the N. Virginia region, get Instance ID:
instanceID=$(aws ec2 run-instances \
    --image-id "$amazonLinux2AMI" \
    --instance-type "$ec2typeNVirginia" \
    --count "$ec2numberNVirginia" \
    --key-name "$keypair" \
    --security-group-ids "$SGAssignment7" \
    --associate-public-ip-address \
    --user-data file://$userdata \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Assignment7task1}]' \
    --query "Instances[].InstanceId" --output text) 

#Step5: Wait untill EC2 launches (becomes running state):
aws ec2 wait instance-running \
    --instance-ids "$instanceID"

#Step6: create AMI image from the instance created in Step3:
amiID=$(aws ec2 create-image \
    --instance-id "$instanceID" \
    --name "MyAMI" \
    --description "An AMI for my server" \
    --tag-specifications 'ResourceType=image,Tags=[{Key=Name,Value=MyAMI}]' \
    --output text)

#Step7: Wait untill AMI launches (becomes available):
aws ec2 wait image-available \
    --image-ids "$amiID"

#Step8: Create a new instance from your AMI image in the N. Virginia region:
instanceID2=$(aws ec2 run-instances \
    --image-id "$amiID" \
    --instance-type "$ec2typeNVirginia1" \
    --count "$ec2numberNVirginia1" \
    --key-name "$keypair" \
    --security-group-ids "$SGAssignment7" \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Assignment7task2}]' \
    --query "Instances[].InstanceId" --output text)

#Step9: Wait untill EC2 launches (becomes running state):
aws ec2 wait instance-running \
    --instance-ids "$instanceID2"

#Step10: Get Public IP of instance
publicIP=$(aws ec2 describe-instances \
--filters "Name=tag:Name,Values=Assignment7task1" \
--query "Reservations[*].Instances[*].PublicIpAddress" --output=text)

#Step11: SSH to Instance created in Step10 and check the content of the index.html file (should be the same as in instance created in Step4):
ssh -o "StrictHostKeyChecking=no" -i ~/.ssh/"$keypair".pem ec2-user@"$publicIP" \
'ls /usr/share/nginx/html' | grep 'alexabuy.jpg' > ~/check1.txt

#Step12: SSH to Instance created in Step10 and check if the alexabuy.jpg exists in the Nginx root directory:
ssh -o "StrictHostKeyChecking=no" -i ~/.ssh/"$keypair".pem ec2-user@"$publicIP" \
'cat /usr/share/nginx/html/index.html' > ~/check2.txt

#Step13: Copy AMI image from the N. Virginia region to the Ohio region:
amiID2=$(aws ec2 copy-image \
    --region "$regionOhio" \
    --name ami-name \
    --source-region "$regionNVirginia" \
    --source-image-id "$amiID" \
    --description "This is my copied image" --output text)

        #BLOCK B: Create infrustructure in AWS Ohio Region     

#Step 14: Set Ohio AWS Region (us-east-2):
export AWS_DEFAULT_REGION="$regionOhio"  

#Step15: Security group ID (create SG and save returned SG ID in a variable):
SGAssignment7Ohio=$(aws ec2 create-security-group \
--group-name SGAssignment7Ohio \
--description "Security Group Assignment7 in Ohio" \
--region "$regionOhio" --query 'GroupId' --output text)

#Step16: Security group Inbound Rules (authorize port 80 (http) and port 22 (ssh) for all internet trafic (all IPs):
aws ec2 authorize-security-group-ingress --group-name SGAssignment7Ohio \
--region "$regionOhio" \
--ip-permissions IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=0.0.0.0/0}] \
IpProtocol=tcp,FromPort=80,ToPort=80,IpRanges=[{CidrIp=0.0.0.0/0}]

#Step17: Wait untill AMI launches (becomes available):
aws ec2 wait image-available \
    --filters "Name=name,Values=ami-name" --output text


#Step18: Create a new instance from AMI image created in Step14 (in the Ohio region):
instanceID3=$(aws ec2 run-instances \
    --image-id "$amiID2" \
    --instance-type "$ec2typeOhio" \
    --count "$ec2numberOhio" \
    --key-name "$keypairOhio" \
    --security-group-ids "$SGAssignment7Ohio" \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Assignment7task2Ohio}]' \
    --query "Instances[].InstanceId" --output text)

#Step19: Wait untill EC2 launches (becomes running state):
aws ec2 wait instance-running \
    --instance-ids "$instanceID3"


#Step20: Get Public IP of instance:
publicIP1=$(aws ec2 describe-instances \
--filters "Name=tag:Name,Values=Assignment7task2Ohio" \
--query "Reservations[*].Instances[*].PublicIpAddress" --output=text)

#Step21: SSH to Ohio Server created in Step18:
ssh -o "StrictHostKeyChecking=no" -i ~/.ssh/"$keypairOhio".pem ec2-user@"$publicIP1" 'free -m' > ~/check3.txt
sleep 3

#Step22: Set Ohio AWS Region (us-east-2):
export AWS_DEFAULT_REGION="$regionNVirginia"

#Step23: Change instance type to t2.micro:
    #stop
aws ec2 stop-instances --instance-ids "$instanceID"

    # wait
aws ec2 wait instance-stopped \
  --instance-ids "$instanceID"

    # resize
aws ec2 modify-instance-attribute \
	--instance-id "$instanceID" \
	--instance-type "{\"Value\": \"t2.micro\"}"

    # start
aws ec2 start-instances --instance-ids "$instanceID"

#Step24: Wait untill EC2 launches:
aws ec2 wait instance-running \
    --instance-ids "$instanceID"
sleep 2

#Step25: Get Public IP of instance:
publicIP2=$(aws ec2 describe-instances \
--filters "Name=tag:Name,Values=Assignment7task1" \
--query "Reservations[*].Instances[*].PublicIpAddress" --output=text)

#Step26: SSH to Ohio Server created in Step20:
ssh -o "StrictHostKeyChecking=no" -i ~/.ssh/"$keypair".pem ec2-user@"$publicIP2" 'free -m' > ~/check4.txt




