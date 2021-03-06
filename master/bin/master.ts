#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from '@aws-cdk/core';
import { MasterStack } from '../lib/master-stack';

const app = new cdk.App();
const env = {
    account: process.env.CDK_DEPLOY_ACCOUNT || process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEPLOY_REGION || process.env.CDK_DEFAULT_REGION
}
// eng vpc id
const vpcId = 'vpc-0c9ebecbfef2d6436';
new MasterStack(app, 'MasterStack', vpcId, {env : env});
