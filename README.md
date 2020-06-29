# Coffee Shop CI/CD with Tekton

This repo contains Tekton resources for continuous integration & continuous deployment of the Coffee Shop demo.

It contains the following components:
- Build, push & promote pipeline:
   This pipeline implements CI for a single microservice. It builds a Docker image, pushes it to a repository, and then promotes the change to the GitOps repository.
- Deploy pipline:
   This pipeline implements CD for the whole application. It deploys the application into an OpenShift cluster and runs integration tets.
- Triggers:
   These allow the pipeliens to be triggered by a GitHub webhoook.

## Installation

**Build, Deploy and Promote Pipelines**
1. Create a personal access token on GitHub with the `public_repo` scope.
1. Update the `password` field in the `deploy/pipeline/git-secrets.yaml` file to the personal access token created in the previous step.
1. Create a personal access token on DockerHub.
1. Update `build/pipeline/docker-secret.yaml` with your Docker ID and token.
1. In `build/pipeline/pipeline-resources.yaml`, update the `coffeeshop-ui-image` resource `url` attribute to an image repository you can push to.
1. Deploy the pipeline components:
   * `oc create ns coffeeshop-pipelines`
   * `oc apply -f serviceaccount.yaml`
   * `oc apply -f build/pipeline`
   * `oc apply -f deploy/pipeline`
   * `oc apply -f promote/pipeline`
1. Deploy the webhook secret. This is referenced by the service account, so nothing will work unless it exists.
   * `oc apply -f trigger/git-secrets.yaml`
1. Now you can manually run the pipelines: 
   * Build and promote the coffeeshop-ui service: `oc create -f build/run-pipeline.yaml`
   * Deploy the gitops-dev repo: `oc create -f deploy/run-pipeline.yaml`
   * Run the integration tests only: `oc create -f deploy/run-test-task.yaml`
   * Promote a service from dev to staging: `oc create -f promote/run-pipeline.yaml`
   

**Triggers**

1. In the `trigger/ingress.yaml` file, substitute `<INGRESS_ROUTER_HOSTNAME>` with the canonical hostname for the OpenShift ingress router. For example: `host: eventlistener.apps.mycluster.myorg.com`. This can be found by either:
   * using the OpenShift UI, find the `ROUTER_CANONICAL_HOSTNAME` environment variable defined in the `router-default` deployment in the `openshift-ingress` project,
   * via the command line as follows:  
   `oc describe deployment router-default -n openshift-ingress | grep HOSTNAME`
1. Update the `webhooksecret` field in the `trigger/git-secrets.yaml` file to a randomly generated secret.
1. Create webhooks on GitHub for each microservice and each GitOps repo (you many need additionion repo permissions) specifying:
   * "Payload URL" as `http://eventlistener.<HOST>:80` where host is the same as from the ingress file above.
   * "Secret" as the `webhooksecret` from `trigger/git-secrets.yaml`.
   * "Content-Type" as `application/json`.
   * In "Events" leave the "Just the push event" trigger option selected.
1. Deploy the trigger components:
   * `oc apply -f trigger`

**Dashboard**

1. Generate a password and enter the following in your command line `export PASSWORD=<password you created>`. The next script will use this variable to generate the certificate.
1. Create the certificate and key:  
`dashboard/generate-tls-certs.sh`
1. In the `dashboard/tekton-dashboard-secret.yaml` file you will need to replace the `tls.crt` and `tls.key` values with the certificate and key that was generated from the previous script. Use the following commands to encode the files to replace the above values with:
   * `echo dashboard/tekton-key.pem | base64`
   * `echo dashboard/tekton-cert.pem | base64`
1. In the `ingress.yaml` file, substitute `INGRESS_ROUTER_HOSTNAME` with the canonical hostname for the OpenShift ingress router. For example: `host: tekton.dashboard.apps.mycluster.myorg.com`. This can be found by either:
   * using the OpenShift UI, find the `ROUTER_CANONICAL_HOSTNAME` environment variable defined in the `router-default` deployment in the `openshift-ingress` project,
   * via the command line as follows:  
   `oc describe deployment router-default -n openshift-ingress | grep HOSTNAME`
1. Deploy the dashboard components.
   * `oc create ns tekton-pipelines`
   * `oc apply -f https://github.com/tektoncd/dashboard/releases/download/v0.5.2/openshift-tekton-dashboard-release.yaml --validate=false`
   * `oc apply -f dashboard/tekton-dashboard-secret.yaml`
   * `oc apply -f dashboard/ingress.yaml` 
1. You can find the url for the dashboard in the `Routes` in the `tekton-pipelines` project.
