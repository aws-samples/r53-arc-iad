import { CfnOutput, Stack, StackProps } from 'aws-cdk-lib';
import { Construct } from 'constructs';

import { aws_ec2 as ec2 } from 'aws-cdk-lib';
import { aws_iam as iam } from 'aws-cdk-lib';

export class TictactoeClientCdkStack extends Stack {
  constructor(scope: Construct, id: string, props?: StackProps) {
    super(scope, id, props);

    /********************************************
     * Create the network
     ********************************************/

    // the network for the client EC2 instance
    const vpc = new ec2.Vpc(this, 'TicTacToeVPC', {
      natGateways: 1, //default value but better to make it explicit
      maxAzs: 1,
      ipAddresses: ec2.IpAddresses.cidr('10.0.0.0/16'),
      subnetConfiguration: [{
        subnetType: ec2.SubnetType.PUBLIC,
        name: 'igw',
        cidrMask: 24,
      }, {
        subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
        name: 'bastion',
        cidrMask: 24
      } ]
    });

    // create a bastion host in the private subnet
    const bastionRole = new iam.Role(this, 'BastionRole', {
        assumedBy: new iam.ServicePrincipal('ec2.amazonaws.com')
    });
    const bastionHost = new ec2.Instance(this, 'BastionHost', {
        vpc,
        vpcSubnets: { subnetGroupName: 'bastion'},
        instanceType: ec2.InstanceType.of(ec2.InstanceClass.BURSTABLE4_GRAVITON, ec2.InstanceSize.MICRO),
        machineImage: new ec2.AmazonLinuxImage({
            cpuType: ec2.AmazonLinuxCpuType.ARM_64,
            generation: ec2.AmazonLinuxGeneration.AMAZON_LINUX_2 }
        ), 
        instanceName: 'client',
        role: bastionRole
    });
    const policy = {
        Action: [
          "ssmmessages:*",
          "ssm:UpdateInstanceInformation",
          "ec2messages:*"
        ],
        Resource: "*",
        Effect: "Allow"
    }
    bastionHost.addToRolePolicy(iam.PolicyStatement.fromJson(policy));

    // output the bastion instance ID for easy retrieval
    new CfnOutput(this, 'BastionID', { value: bastionHost.instanceId});
    new CfnOutput(this, 'VPCID', { value: vpc.vpcId});

  }
}
