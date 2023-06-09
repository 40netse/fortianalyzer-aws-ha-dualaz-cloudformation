#!/usr/bin/env bash


#
# variables for entire stack set
#
region=<change this>

stack_prefix=<change this>
environment_tag=<change this>
project_name=$stack_prefix-test

#
# Cloudinit stack names that build the AGW Stacks
#
#
# Base VPC Templates. (VPC's, Subnets, Route Tables, IGW's, etc)
# Not used if deploying into an existing VPC.
#
stack1=$project_name-base-vpc

#
# Templates to deploy Security VPC Fortigate's and Customer Endpoints
#
stack2=$project_name-deploy-faz-ha


#
# Security VPC Firewall Set variables
#
# This value needs to be changed. Account Specific
#
key=<change this>
license_bucket=<change this>
access_public="0.0.0.0/0"

faz1_license_file=<change this>
faz2_license_file=<change this>
access_private="0.0.0.0/0"
privateaccess="10.0.0.0/16"
instance_type=m5.xlarge
encrypt_volumes=false
publicly_available=Yes
s3_endpoint_deployment=DeployNew
fazos_version="7.2.x"
license_type=BYOL
ha_password=<change this>
faz1_ip_mgmt="10.0.0.11"
faz1_ip_cluster="10.0.0.12"
faz2_ip_mgmt="10.0.2.11"
faz2_ip_cluster="10.0.2.12"
faz1_sn=<change this>
faz2_sn=<change this>
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
