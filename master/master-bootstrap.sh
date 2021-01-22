#!/bin/bash

set -x

KURL_HASH=7a6185b
WAITTIME_BEFORE_START_IN_SEC=30

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

function bootstrap_cluster() {
  # Run the kurl and after finish, parse the join command and generate new command and push them to SSM parameter store
  aws ssm send-command --document-name "AWS-RunShellScript" \
    --document-version "1" \
    --targets '[{"Key":"tag:Name","Values":["kube-master"]}]' \
    --timeout-seconds 600 \
    --max-concurrency "50" \
    --max-errors "0" \
    --region us-east-1 \
    --parameters '{"commands":["#!/bin/bash","","set -x","set +e","","curl https://kurl.sh/'"$KURL_HASH"' | sudo bash +e > /var/log/kurl.log && \\","JOIN=$(cat /var/log/kurl.log | grep -A 1 '"'"'to this install'"'"' | grep curl | sed '"'"'s/\\x1b\\[[0-9;]*m//g'"'"' | sed '"'"'s/sudo bash/sudo bash +x/'"'"' | xargs) && \\","aws ssm put-parameter --name \"/kube-master/join/command\" --type \"String\" --value \"$JOIN\" --overwrite && \\","GENERATECMD=$(cat /var/log/kurl.log | grep '"'"'To generate new'"'"' | sed '"'"'s/.*run //'"'"' | sed '"'"'s/on this.*//'"'"' | sed '"'"'s/\\x1b\\[[0-9;]*m//g'"'"' | xargs) && sleep 25 &&\\","aws ssm put-parameter --name \"/kube-master/generate/command\" --type \"String\" --value \"$GENERATECMD\" --overwrite"],"workingDirectory":[""],"executionTimeout":["3600"]}'
}

function main() {
    echo 'Waiting for system to bootstrap before attempting to install' && sleep $WAITTIME_BEFORE_START_IN_SEC
    install_dependency
    disable_selinux
    bootstrap_cluster
}

main "$@"

# join command            # cat /var/log/kurl.log | grep -A 1 'to this install'  | grep curl | sed 's/\x1b\[[0-9;]*m//g' | sed 's/sudo bash/sudo bash +x/' | xargs
# regenerate join command # cat /var/log/kurl.log | grep 'To generate new' | sed 's/.*run //' | sed 's/on this.*//' | sed 's/\x1b\[[0-9;]*m//g'
# put param               # aws ssm put-parameter  --name "/joinCmd"  --type "String"  --value "$JOIN"  --overwrite
# get param               # aws ssm get-parameter  --name "/joinCmd" | jq .Parameter.Value

