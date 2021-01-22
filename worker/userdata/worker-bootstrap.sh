#!/bin/bash

set -x

KURL_HASH=7a6185b
WAITTIME_BEFORE_START_IN_SEC=30

function generate_new_token() {
  GENERATECMD=$(aws ssm get-parameter  --name "/kube-master/generate/command" | jq .Parameter.Value | sed -e 's/^"//' -e 's/"$//')
  aws ssm send-command \
  --document-name "AWS-RunShellScript" \
  --document-version "1" \
  --targets '[{"Key":"tag:Name","Values":["kube-master"]}]' \
  --timeout-seconds 600 \
  --max-concurrency "50" \
  --max-errors "0" \
  --region us-east-1 \
  --parameters '{"workingDirectory":[""],"executionTimeout":["3600"],"commands":["#!/bin/bash","","set -x","set +e","JOIN=$('"$GENERATECMD"' | grep -A 1 '"'"'to this install'"'"' | grep curl | sed '"'"'s/\\x1b\\[[0-9;]*m//g'"'"' | sed '"'"'s/sudo bash/sudo bash +x/'"'"' | xargs) && \\","aws ssm put-parameter --name \"/kube-master/join/command\" --type \"String\" --value \"$JOIN\" --overwrite",""]}'
}

function join_to_master() {
  INSTANCE=$(curl http://169.254.169.254/latest/meta-data/instance-id)
  JOINCMD=$(aws ssm get-parameter  --name "/kube-master/join/command" | jq .Parameter.Value | sed -e 's/^"//' -e 's/"$//')
  aws ssm send-command \
  --document-name "AWS-RunShellScript" \
  --document-version "1" \
  --targets '[{"Key":"InstanceIds","Values":["'"$INSTANCE"'"]}]' \
  --timeout-seconds 600 \
  --max-concurrency "50" \
  --max-errors "0" \
  --region us-east-1 \
  --parameters '{"commands":["#!/bin/bash","","set -x","set +e","'"$JOINCMD"' > /var/log/kurl.log",""],"workingDirectory":[""],"executionTimeout":["3600"]}'
}


function install_dependency() {
  # Install ssm agent
  yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
  systemctl enable amazon-ssm-agent
  systemctl start amazon-ssm-agent
  # Install jq
  sudo yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
  sudo yum install jq -y

  # install awscli v2
  yum install -y unzip
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip
  ./aws/install
}


function disable_selinux() {
  # Disable SELinux
  setenforce 0
  sed -i s/^SELINUX=.*$/SELINUX=permissive/ /etc/selinux/config

}

function join_to_cluster() {
  EXPIRE_TIME=$(aws ssm get-parameter  --name "/kube-master/join/command" | jq .Parameter.LastModifiedDate | sed -e 's/^"//' -e 's/"$//')
  EXPIRE_TIME_IN_SEC=$(date -d ${EXPIRE_TIME} +"%s")
  CURRENT_TIME_IN_SEC=$(date +"%s")
  DIFF_IN_SEC=$(( CURRENT_TIME_IN_SEC - EXPIRE_TIME_IN_SEC ))
  # lets go with 23 hours instead of 24 to make sure we are not hiting the last minutes of the last hour
  DAY_IN_SEC=$((3600 * 23))
  if (( "$DIFF_IN_SEC" > "$DAY_IN_SEC" ));
  then
    echo 'Token is expired, requesting a new token before joining the master'
    generate_new_token
    sleep 30
    join_to_master
  else
    echo 'Token is fresh, joining to master node'
    join_to_master
  fi
}

function main() {
    echo 'Waiting for system to bootstrap before attempting to install' && sleep $WAITTIME_BEFORE_START_IN_SEC
    install_dependency
    disable_selinux
    join_to_cluster
}

main "$@"

