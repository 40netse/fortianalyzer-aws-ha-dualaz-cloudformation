#!/usr/bin/env bash

source $(dirname $0)/stack_parameters.sh

pause=15

make_s3 ()
{
    if [ -z "$1" ]
    then
        echo "No bucket specified"
        return -1
    fi
    if [ -z "$2" ]
    then
        echo "No license specified"
        return -1
    fi
    url=$3

    bucket=$1
    file=$2
    found_bucket=0
    for b in `aws s3 ls|cut -f3 -d' '`
    do
        if [ "$bucket" == "$b" ]
        then
            found_bucket=1
            break
        fi
    done
    if [ $found_bucket == 0 ]
    then
        aws s3 mb s3://$bucket
        aws s3 cp $file s3://$bucket
    fi
    return 0
}

usage()
{
cat << EOF
usage: $0 options

This script will deploy a series of cloudformation templates that build and protect a workload

OPTIONS:
   -k pause for keyboard input
   -p pause value between AWS queries
EOF
}

while getopts kp:W OPTION
do
     case $OPTION in
         k)
             KI_SPECIFIED=true
             ;;
         p)
             PAUSE_SPECIFIED=true
             PAUSE_VALUE=$OPTARG
             ;;
         ?)
             usage
             exit
             ;;
     esac
done

if [ "$PAUSE_SPECIFIED" == true ]
then
    pause=$PAUSE_VALUE
fi

if [ "$KI_SPECIFIED" == true ]
then
    keypress_loop=true
else
    keypress_loop=false
fi
while [ $keypress_loop == true ]
do
    echo
    read -t 1 -n 10000 discard
    read -n1 -r -p "Press enter to deploy base vpc..." keypress
    if [[ "$keypress" == "" ]]
    then
        keypress_loop=false
    fi
done

make_s3 $license_bucket $faz1_license_file
make_s3 $license_bucket $faz2_license_file

if [ "${KI_SPECIFIED}" == true ]
then
    echo "Deploying "$stack1" Template and the script will pause when the create-stack is complete"
else
    echo "Deploying "$stack1" Template"
fi

#
# deploy the stack if it doesn't already exist
#
count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack1" |wc -l`
if [ "${count}" -eq "0" ]
then
    aws cloudformation create-stack --stack-name "$stack1" --output text --region "$region" \
        --template-body file://BaseVPC_Dual_AZ.yaml \
        --parameters ParameterKey=VPCCIDR,ParameterValue="$ha_cidr" \
         ParameterKey=AZForSubnet1,ParameterValue="$region"a \
         ParameterKey=AZForSubnet2,ParameterValue="$region"c \
         ParameterKey=PublicSubnet1,ParameterValue="$ha_public1_subnet" \
         ParameterKey=PrivateSubnet1,ParameterValue="$ha_private1_subnet" \
         ParameterKey=PublicSubnet2,ParameterValue="$ha_public2_subnet" \
         ParameterKey=PrivateSubnet2,ParameterValue="$ha_private2_subnet" > /dev/null
fi

#
# Wait for template above to CREATE_COMPLETE
#
for (( c=1; c<=50; c++ ))
do
    count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack1" |wc -l`
    if [ "${count}" -ne "0" ]
    then
        break
    fi
    sleep $pause
done

#
# Pull the outputs from the first template as environment variables that are used in the second and third templates
#
tfile=$(mktemp /tmp/foostack1.XXXXXXXXX)
aws cloudformation describe-stacks --output text --region "$region" --stack-name "$stack1" --query 'Stacks[*].Outputs[*].{KEY:OutputKey,Value:OutputValue}' > $tfile
VPC=`cat $tfile|grep ^VPCID|cut -f2 -d$'\t'`
VPCCIDR=`cat $tfile|grep ^VPCCIDR|cut -f2 -d$'\t'`
AZ1=`cat $tfile|grep ^AZ1|cut -f2 -d$'\t'`
AZ2=`cat $tfile|grep ^AZ2|cut -f2 -d$'\t'`
Public1_SUBNET=`cat $tfile|grep ^Public1ID|cut -f2 -d$'\t'`
Private1_SUBNET=`cat $tfile|grep ^Private1ID|cut -f2 -d$'\t'`
Public2_SUBNET=`cat $tfile|grep ^Public2ID|cut -f2 -d$'\t'`
Private2_SUBNET=`cat $tfile|grep ^Private2ID|cut -f2 -d$'\t'`
PublicRouteTableID=`cat $tfile|grep ^PublicRouteTableID|cut -f2 -d$'\t'`
PrivateRouteTable1ID=`cat $tfile|grep ^PrivateRouteTable1ID|cut -f2 -d$'\t'`
PrivateRouteTable2ID=`cat $tfile|grep ^PrivateRouteTable2ID|cut -f2 -d$'\t'`
if [ -f $tfile ]
then
    rm -f $tfile
fi

echo
echo "Created VPC = $VPC"
echo "VPC Cidr Block = $VPCCIDR"
echo "Availability Zone 1 = $AZ1"
echo "Availability Zone 2 = $AZ2"
echo "Public Subnet 1 = $Public1_SUBNET"
echo "Private Subnet 1 = $Private1_SUBNET"
echo "Public Subnet 2 = $Public2_SUBNET"
echo "Private Subnet 2 = $Private2_SUBNET"
echo "Public Route Table ID = $PublicRouteTableID"
echo "Private Route Table 1 ID = $PrivateRouteTable1ID"
echo "Private Route Table  2 ID = $PrivateRouteTable2ID"
echo

#
# Deploy Security VPC AGW (AGW_ExistingVPC.yaml)
#
if [ "$KI_SPECIFIED" == true ]
then
    keypress_loop=true
else
    keypress_loop=false
fi
while [ $keypress_loop == true ]
do
    read -t 1 -n 10000 discard
    read -n1 -r -p "Press enter to deploy Fortianalyzer Dual AZ HA (FortiAnalyzer_HA_DualAZ_ExistingVPC.json)..." keypress
    if [[ "$keypress" == "" ]]
    then
        keypress_loop=false
    fi
done


if [ "${KI_SPECIFIED}" == true ]
then
    echo "Deploying "$stack2" Template and the script will pause when the create-stack is complete"
else
    echo "Deploying "$stack2" Template"
fi

#
# Now deploy FortiAnalyzer HA in public subnets on top of the existing VPC
#

count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack2" |wc -l`
if [ "${count}" -eq "0" ]
then
    aws cloudformation create-stack --stack-name "$stack2" --output text --region "$region" --capabilities CAPABILITY_IAM \
        --template-body file://FortiAnalyzer_HA_DualAZ_ExistingVPC.template.json \
        --parameters    ParameterKey=VPCID,ParameterValue="$VPC" \
                        ParameterKey=VPCCIDR,ParameterValue="$VPCCIDR" \
                        ParameterKey=SubnetAZ1,ParameterValue="$Public1_SUBNET" \
                        ParameterKey=SubnetAZ2,ParameterValue="$Public2_SUBNET" \
                        ParameterKey=InstanceType,ParameterValue="$instance_type" \
                        ParameterKey=CIDRForInstanceAccess,ParameterValue="$access_private" \
                        ParameterKey=KeyPair,ParameterValue="$key" \
                        ParameterKey=EncryptVolumes,ParameterValue="$encrypt_volumes" \
                        ParameterKey=PubliclyAvailable,ParameterValue="$publicly_available" \
                        ParameterKey=S3EndpointDeployment,ParameterValue="$s3_endpoint_deployment" \
                        ParameterKey=SubnetRouteTableID,ParameterValue="$PublicRouteTableID" \
                        ParameterKey=InitS3Bucket,ParameterValue="$license_bucket" \
                        ParameterKey=FortiAnalyzerVersion,ParameterValue="$fazos_version" \
                        ParameterKey=LicenseType,ParameterValue="$license_type" \
                        ParameterKey=FortiAnalyzer1LicenseFile,ParameterValue="$faz1_license_file" \
                        ParameterKey=FortiAnalyzer2LicenseFile,ParameterValue="$faz2_license_file" \
                        ParameterKey=FortiAnalyzer1IPMgmt,ParameterValue="$faz1_ip_mgmt" \
                        ParameterKey=FortiAnalyzer1IPCluster,ParameterValue="$faz1_ip_cluster" \
                        ParameterKey=FortiAnalyzer2IPMgmt,ParameterValue="$faz2_ip_mgmt" \
                        ParameterKey=FortiAnalyzer2IPCluster,ParameterValue="$faz2_ip_cluster" \
                        ParameterKey=HaPassword,ParameterValue="$ha_password" \
                        ParameterKey=FortiAnalyzer1SN,ParameterValue="$faz1_sn" \
                        ParameterKey=FortiAnalyzer2SN,ParameterValue="$faz2_sn" > /dev/null
fi

#
# Wait for template above to CREATE_COMPLETE
#
for (( c=1; c<=50; c++ ))
do
    count=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output text --region "$region" |grep "$stack2" |wc -l`
    if [ ${count} -eq 1 ]
    then
        break
    fi
    sleep $pause
done

#
# Pull the outputs from the first template as environment variables that are used in the second and third templates
#
tfile=$(mktemp /tmp/foostack2.XXXXXXXXX)
aws cloudformation describe-stacks --output text --region "$region" --stack-name "$stack2" --query 'Stacks[*].Outputs[*].{KEY:OutputKey,Value:OutputValue}' > $tfile
USERNAME=`cat $tfile|grep ^Username|cut -f2 -d$'\t'`
PASSWORD=`cat $tfile|grep ^Password|cut -f2 -d$'\t'`
CLUSTER_LOGIN_URL=`cat $tfile|grep ^ClusterLoginURL|cut -f2 -d$'\t'`
FAZ1_LOGIN_URL=`cat $tfile|grep ^FortiAnalyzer1LoginURL|cut -f2 -d$'\t'`
FAZ2_LOGIN_URL=`cat $tfile|grep ^FortiAnalyzer2LoginURL|cut -f2 -d$'\t'`
if [ -f $tfile ]
then
    rm -f $tfile
fi
if [ -f $tfile ]
then
    rm -f $tfile
fi

echo
echo "ForitiAnalyzer Username = $USERNAME"
echo "ForitiAnalyzer Password = $PASSWORD"
echo "Cluster Login URL = $CLUSTER_LOGIN_URL"
echo "FortiAnalzyer AZ1 Login URL = $FAZ1_LOGIN_URL"
echo "FortiAnalzyer AZ2 Login URL = $FAZ2_LOGIN_URL"
echo

exit
#
# End of the script
#
