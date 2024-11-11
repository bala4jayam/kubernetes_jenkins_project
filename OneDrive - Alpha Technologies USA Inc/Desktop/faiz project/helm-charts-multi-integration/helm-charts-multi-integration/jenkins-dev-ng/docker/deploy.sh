#!/bin/bash

docker info > /dev/null 2>&1

if [ $? -ne 0 ]; then
  echo "Docker is not running. Exiting."
  exit 1
fi

echo "Docker is running."

helm repo add jenkins https://charts.jenkins.io
helm repo update

appver=$(helm show chart jenkins/jenkins | yq e '.appVersion')
echo "Jenkins last version: $appver"
apptag=$(helm show values jenkins/jenkins | yq e '.controller.tagLabel')
agenttag=$(helm show values jenkins/jenkins | yq e '.agent.tag')


# Define dockerfile for jenkins custom image
echo "FROM jenkins/jenkins:$appver-$apptag" >> docker/Dockerfile.core
echo "COPY --chown=jenkins:jenkins docker/plugins.txt /usr/share/jenkins/ref/plugins.txt" >> docker/Dockerfile.core
echo "RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt --verbose --jenkins-version $appver" >> docker/Dockerfile.core

# Define dockerfile for jenkins agent custom image
echo "FROM jenkins/inbound-agent:$agenttag" >> docker/Dockerfile.agent

image_tag="191134568411.dkr.ecr.us-east-2.amazonaws.com/jenkins-core:jenkins-dev-ng_v$appver"
agent_image_tag="191134568411.dkr.ecr.us-east-2.amazonaws.com/jenkins-agent:inbound-agent-$agenttag"
docker build --no-cache -t $image_tag -f docker/Dockerfile.core .
docker build --no-cache -t $agent_image_tag -f docker/Dockerfile.agent .

rm docker/Dockerfile.agent
rm docker/Dockerfile.core

if [ "$1" = "auto" ]; then
  echo "Running command for 'auto' mode"
else
  echo "\n \n Please login to ECR:"
  echo "aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 191134568411.dkr.ecr.us-east-2.amazonaws.com"
  echo "docker push $image_tag"
  echo "docker push $agent_image_tag "
  echo "helm upgrade jenkins-dev jenkins/jenkins --namespace jenkins-dev --install --create-namespace \ "
  echo "    -f chart-values/agent.yaml \ "
  echo "    -f chart-values/configs.yaml \ "
  echo "    -f chart-values/other.yaml \ "
  echo "    -f chart-values/creds.yml \ "
  echo "    -f chart-values/secrets.yml \ "
  echo "    --set controller.installPlugins='false' \ "
  echo "    --set agent.image='191134568411.dkr.ecr.us-east-2.amazonaws.com/jenkins-agent' \ "
  echo "    --set agent.tag='inbound-agent-$agenttag' \ "
  echo "    --set controller.image='191134568411.dkr.ecr.us-east-2.amazonaws.com/jenkins-core' \ "
  echo "    --set controller.tag='jenkins-dev-ng_v$appver'"
fi
