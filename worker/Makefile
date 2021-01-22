SHELL = /bin/bash

.PHONY = build clean

TOPDIR := $(shell git rev-parse --show-toplevel)
APPDIR := $(TOPDIR)/worker

compile:
	@echo Compiling typescript to js
	@cd $(APPDIR) && npm run build


watch:
	@echo Watching for changes and compile
	@cd $(APPDIR) && npm run watch


install:
	@echo Installing dependencies
	@cd $(APPDIR) && npm install


clean:
	@echo Destroying the stack
	@cd $(APPDIR) && cdk destroy

test:
	@echo Performing the jest unit tests
	@cd $(APPDIR) && npm run test


deploy:
	@echo Deploying this stack to your default AWS account and reagion
	@cd $(APPDIR) && cdk deploy --trace --require-approval never


diff:
	@echo Comparing deployed stack with current state
	@cd $(APPDIR) && cdk diff --trace


synth:
	@echo Emiting the synthesized CloudFormation template to stdout as Yaml and in cdk.out in json format
	@cd $(APPDIR) && cdk synth
