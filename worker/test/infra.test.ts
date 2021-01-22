import { expect as expectCDK, matchTemplate, MatchStyle } from '@aws-cdk/assert';
import * as cdk from '@aws-cdk/core';
import * as Infra from '../lib/worker-stack';

test('Empty Stack', () => {

    const env = {
        account: process.env.CDK_DEPLOY_ACCOUNT || process.env.CDK_DEFAULT_ACCOUNT,
        region: process.env.CDK_DEPLOY_REGION || process.env.CDK_DEFAULT_REGION
    }
    const vpcId = 'vpc-0c8d128180f93be76';

    const app = new cdk.App();
    // WHEN
    const stack = new Infra.WorkerStack(app, 'WorkerStack', vpcId, {env: env});
    // THEN
    expectCDK(stack).to(matchTemplate({
      "Resources": {}
    }, MatchStyle.EXACT))
});
