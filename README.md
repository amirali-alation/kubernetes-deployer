
# Kubernetes Cluster deployment and bootstrap using CDK

This repo uses CDK to create and bootstrap a Kubernetes cluster and associated worker nodes on AWS.

This deployment will use a given VPC, and will setup the subnet and security group in it to setup the cluster.

KURL.sh has been used to bootstrap the Kubernetes with the following spec:

```yaml
spec:
  kubernetes:
    version: 1.19.3
  docker:
    version: 19.03.10
  weave:
    version: 2.7.0
  rook:
    version: 1.0.4
  registry:
    version: 2.7.1
  ekco:
    version: 0.7.0
 
```



Before begin please make sure you have:
- Installed and configured aws CLI
- Installed Node.js 10.3.0 or later
- Installed TypeScript using npm -g install typescript
- Installed aws-cdk using npm install -g aws-cdk

To learn more about CDK please look at
[AWS CDK getting started](https://docs.aws.amazon.com/cdk/latest/guide/getting_started.html)


There are two main modules, Master and Worker. Each module has its own Makefile. You can setup the master by running 
```bash
make deploy
```

and After about 10 Monites run the worker module using

```bash
make deploy
```

