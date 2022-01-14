# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. SPDX-License-Identifier: MIT-0
#!/bin/zsh

CDK_OUTPUT_FILE=../out.json 

if [ ! -f $CDK_OUTPUT_FILE ]; then
    echo "Can not find CDK output files with the ARN of the resources it created"
    echo "Be sure to deploy the CDK stack using 'cdk deploy --all --outputs-file out.json'"
    exit -1
fi

# check dependency on jq
which jq > /dev/null
if [ $? != 0 ];
then
    echo 'jq must be installed.\nOn Mac, type "brew install jq".\nOtherwise check https://stedolan.github.io/jq/download/'
    exit -1
fi 

REGION=us-west-2
STACK_NAME=Route53-dns-records
LOAD_BALANCER_1_DNS=$(cat $CDK_OUTPUT_FILE| jq .\"TictactoeAppCdkStack-us-east-1\".LoadBalancerDNSName -r)
LOAD_BALANCER_2_DNS=$(cat $CDK_OUTPUT_FILE| jq .\"TictactoeAppCdkStack-us-west-2\".LoadBalancerDNSName -r)
LOAD_BALANCER_HOSTEDZONE_EAST=$(cat $CDK_OUTPUT_FILE| jq .\"TictactoeAppCdkStack-us-east-1\".HostedZoneLoadBalancer -r)
LOAD_BALANCER_HOSTEDZONE_WEST=$(cat $CDK_OUTPUT_FILE| jq .\"TictactoeAppCdkStack-us-west-2\".HostedZoneLoadBalancer -r)
VPC_EAST=$(cat $CDK_OUTPUT_FILE| jq .\"TictactoeAppCdkStack-us-east-1\".VPCID -r)
VPC_WEST=$(cat $CDK_OUTPUT_FILE| jq .\"TictactoeAppCdkStack-us-west-2\".VPCID -r)
VPC_CLIENT=$(cat $CDK_OUTPUT_FILE| jq .\"TictactoeClientCdkStack\".VPCID -r)

ROUTE53_HEALTHCHECKID_CELL1=$(aws --region $REGION cloudformation describe-stacks --stack-name Route53ARC-RoutingControl --query "Stacks[].Outputs[?OutputKey=='HealthCheckIdEast'].OutputValue" --output text)
ROUTE53_HEALTHCHECKID_CELL2=$(aws --region $REGION cloudformation describe-stacks --stack-name Route53ARC-RoutingControl --query "Stacks[].Outputs[?OutputKey=='HealthCheckIdWest'].OutputValue" --output text)

DNS_DOMAIN_NAME=example.com

aws --region $REGION cloudformation create-stack               \
    --template-body file://../cloudformation/Route53-DNS-records.yaml          \
    --stack-name $STACK_NAME                                   \
    --parameters ParameterKey=LoadBalancerDNSNameEast,ParameterValue=$LOAD_BALANCER_1_DNS \
                 ParameterKey=LoadBalancerDNSNameWest,ParameterValue=$LOAD_BALANCER_2_DNS \
                 ParameterKey=LoadBalancerHostedZoneEast,ParameterValue=$LOAD_BALANCER_HOSTEDZONE_EAST \
                 ParameterKey=LoadBalancerHostedZoneWest,ParameterValue=$LOAD_BALANCER_HOSTEDZONE_WEST \
                 ParameterKey=DNSHealthcheckIdEast,ParameterValue=$ROUTE53_HEALTHCHECKID_CELL1 \
                 ParameterKey=DNSHealthcheckIdWest,ParameterValue=$ROUTE53_HEALTHCHECKID_CELL2 \
                 ParameterKey=VpcIdEast,ParameterValue=$VPC_EAST \
                 ParameterKey=VpcIdWest,ParameterValue=$VPC_WEST \
                 ParameterKey=VpcIdClient,ParameterValue=$VPC_CLIENT \
                 ParameterKey=DNSDomainName,ParameterValue=$DNS_DOMAIN_NAME
