import cdk = require('@aws-cdk/core');
import ec2 = require('@aws-cdk/aws-ec2');
import { SubnetType, InstanceType, InstanceClass, InstanceSize } from '@aws-cdk/aws-ec2';
import { Role, ServicePrincipal, ManagedPolicy, CfnInstanceProfile } from '@aws-cdk/aws-iam'
import fs = require('fs');

export class WorkerStack extends cdk.Stack {
    constructor(scope: cdk.Construct, id: string, targetVpcId: string, props?: cdk.StackProps) {
        super(scope, id, props);
        const vpc = ec2.Vpc.fromLookup(this, 'VPC', {
            vpcId: targetVpcId,
        });

        const ami = ec2.MachineImage.genericLinux({
            // Official Centos 7 AMI
            "us-east-1": "ami-0affd4508a5d2481b",
        })

        const diskConf = [
            {
                deviceName: '/dev/sda1',
                volume: ec2.BlockDeviceVolume.ebs(16, {
                    deleteOnTermination: true,
                    encrypted: true,
                    volumeType: ec2.EbsDeviceVolumeType.GP2,
                }),
            }
        ]

        const role = new Role(this, 'K8-SSM-Role', {
            assumedBy: new ServicePrincipal('ec2.amazonaws.com')
        });
        role.addManagedPolicy(ManagedPolicy.fromAwsManagedPolicyName('AmazonSSMFullAccess'));


        const workerSecurityGroup = new ec2.SecurityGroup(this, 'worker_securityGroup', {
            vpc: vpc,
            securityGroupName: 'WorkerSecurityGroup',
            description: 'Kube Worker instance Security Group',
            allowAllOutbound: true
        })

        workerSecurityGroup.addIngressRule(
            // Open to all temporary until we setup the gateway or bastion host and allow ssh only from
            // that instance using this example
            // ec2.Peer.ipv4('10.0.0.1/24'),
            ec2.Peer.anyIpv4(),
            ec2.Port.tcp(22),
            'Allow ssh access from anywhere'
        );

        workerSecurityGroup.addIngressRule(
            ec2.Peer.ipv4('10.13.0.0/16'),
            ec2.Port.allUdp(),
            'Allow all UDP inbound from within the subnet'
        );

        workerSecurityGroup.addIngressRule(
            ec2.Peer.ipv4('10.13.0.0/16'),
            ec2.Port.allTcp(),
            'Allow all TCP inbound from within the subnet'
        );

        const workerUserDataFile = fs.readFileSync('userdata/worker-bootstrap.sh','utf8');
        const workerUserData = ec2.UserData.forLinux({ shebang: "#!/bin/bash -ex" });
        workerUserData.addCommands(
            'exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1',
            'echo export PS1=\\""\\[\\e[33m\\]Worker | \\e[32m\\]\\h\\[\\e[m\\] | \\[\\e[36m\\]\\u\\[\\e[m\\]  | \\[\\e[35m\\]\\t\\[\\e[m\\] | \\[\\e[32m\\]\\w\\[\\e[m\\]\\[\\e[35m\\] ➤ \\[\\e[m\\] \\"" >> /home/centos/.bash_profile',
            workerUserDataFile
        )

        let workerStorage: Array<ec2.Instance> = [];

        for(let i=0; i < 2; i++) {
            workerStorage.push(
                new ec2.Instance(this, `workerInstance-${i}`, {
                    vpc: vpc,
                    instanceName: `kube-worker-${i}`,
                    instanceType: InstanceType.of(InstanceClass.T2, InstanceSize.MEDIUM),
                    machineImage: ami,
                    keyName: 'gali_corp',
                    securityGroup: workerSecurityGroup,
                    userData: workerUserData,
                    blockDevices: diskConf,
                    role: role,
                })
            )
        }
    }
}
