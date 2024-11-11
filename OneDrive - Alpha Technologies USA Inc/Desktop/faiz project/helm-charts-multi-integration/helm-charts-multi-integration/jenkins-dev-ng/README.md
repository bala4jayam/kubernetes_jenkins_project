# Jenkins automation

## Prerequisites

Due to the [Jenkins issue](https://issues.jenkins.io/browse/JENKINS-43758?attachmentOrder=asc) jobs created with JobDSL plugin lose parameters on reapply. Furthermore, JCasC reapplies jobs configuration on every helm upgrade.

Following a [workaround solution](https://issues.jenkins.io/browse/JENKINS-43758?focusedCommentId=408718&page=com.atlassian.jira.plugin.system.issuetabpanels%3Acomment-tabpanel#comment-408718) JobDSL needs to read and store existing parameters before recreating jobs.

However, there is no way to use this workaround with JCasC directly. To mitigate this issue jobs should be created using a seed job.

On the other hand, the seed job requires a list of job files in groovy format. To generate this list ansible is used. 


## Installation

### Get Repo Info
```
helm repo add jenkins https://charts.jenkins.io
helm repo update
```

### Install and upgrade

Chart installation should be done in two steps: install and upgrade.
The second step is necessary to set matrix-based strategy. It can not be done during install,
because AD connection is not yet configured.

Install chart.
```
$ helm install [RELEASE_NAME] jenkins/jenkins \
    --namespace [NAMESPACE_NAME] \
    --create-namespace \
    -f chart-values/agent.yaml \
    -f chart-values/credentials.yaml \
    -f chart-values/jobs.yaml \
    -f chart-values/other-values.yaml \
    -f chart-values/plugins-config.yaml \
    -f chart-values/plugins.yaml \
    -f chart-values/secrets.yml \
    -f chart-values/security.yaml \
    -f chart-values/tools.yaml
```
