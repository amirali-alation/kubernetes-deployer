#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from '@aws-cdk/core';
import { WorkerStack } from '../lib/worker-stack';

const app = new cdk.App();
const env = {
    account: process.env.CDK_DEPLOY_ACCOUNT || process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEPLOY_REGION || process.env.CDK_DEFAULT_REGION
}
// eng VPC id
const vpcId = 'vpc-0c9ebecbfef2d6436';
new WorkerStack(app, 'WorkerStack', vpcId, {env : env});
