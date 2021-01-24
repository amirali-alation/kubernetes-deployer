import { expect as expectCDK, matchTemplate, MatchStyle } from '@aws-cdk/assert';
import * as cdk from '@aws-cdk/core';
import * as Worker from '../lib/worker-stack';

test('Empty Stack', () => {
    const app = new cdk.App();
    // WHEN
    const stack = new Worker.WorkerStack(app, 'MyTestStack');
    // THEN
    expectCDK(stack).to(matchTemplate({
      "Resources": {}
    }, MatchStyle.EXACT))
});
