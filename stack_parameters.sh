#!/usr/bin/env bash


#
# variables for entire stack set
#
region=us-west-2

stack_prefix=faz1ha
environment_tag=dev
project_name=$stack_prefix-test

#
# Cloudinit stack names that build the AGW Stacks
#
#
# Base VPC Templates. (VPC's, Subnets, Route Tables, IGW's, etc)
# Not used if deploying into an existing VPC.
#
stack1s=$project_name-base-vpc

#
# Templates to deploy Security VPC Fortigate's and Customer Endpoints
#
stack2a=$project_name-deploy-faz-ha


#
# Security VPC Firewall Set variables
#
# This value needs to be changed. Account Specific
#
key=mdw-key-oregon
license_bucket=mdw-fortibucket-us-west-2
access_public="0.0.0.0/0"

faz1_license_file=FAZ-10_0_1_11.lic
faz2_license_file=FAZ-10_0_1_12.lic
access_private="0.0.0.0/0"
privateaccess="10.0.0.0/16"
instance_type=m5.xlarge
encrypt_volumes=false
publicly_available=Yes
s3_endpoint_deployment=DeployNew
fazos_version="7.2.x"
license_type=BYOL
ha_password=mysecret
faz1_ip_mgmt="10.0.0.11"
faz1_ip_cluster="10.0.0.12"
faz2_ip_mgmt="10.0.2.11"
faz2_ip_cluster="10.0.2.12"
faz1_sn=FAZ-VMTM23004040
faz2_sn=FAZ-VMTM23004043
#
# Variables for VPC Endpoints
#
AcceptConnection=false
AwsAccountToWhitelist="arn:aws:iam::123073262904:root"
#
# Variables for Security VPC
#
ha_cidr="10.0.0.0/16"
#
# Variables for Security VPC AZ 1
ha_public1_subnet="10.0.0.0/24"
ha_private1_subnet="10.0.1.0/24"

#
# Variables for Security VPC AZ 2
#
ha_public2_subnet="10.0.2.0/24"
ha_private2_subnet="10.0.3.0/24"
