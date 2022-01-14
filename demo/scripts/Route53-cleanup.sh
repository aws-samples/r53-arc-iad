# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. SPDX-License-Identifier: MIT-0
#!/bin/zsh

REGION=us-west-2
STACK_NAME=Route53-dns-records
aws --region $REGION cloudformation delete-stack               \
    --stack-name $STACK_NAME

REGION=us-west-2
STACK_NAME=Route53ARC-RoutingControl
aws --region $REGION cloudformation delete-stack               \
    --stack-name $STACK_NAME


REGION=us-west-2
STACK_NAME=Route53ARC-ReadinessCheck
aws --region $REGION cloudformation delete-stack               \
            --stack-name $STACK_NAME
